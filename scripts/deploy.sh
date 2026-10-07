#!/usr/bin/env bash
set -euo pipefail

: "${APP_NAME:?}"
: "${AWS_REGION:?}"
: "${GITHUB_SHA:?}"
: "${SERVICE_URL:?}"

ECR_URL="732108543574.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"

# Confirm the service exists before building or pushing.
aws ecs describe-services \
  --cluster "$APP_NAME" \
  --services "$APP_NAME" > "$RUNNER_TEMP/service.json"

python - <<'PY'
import json
import os
from pathlib import Path

data = json.loads((Path(os.environ["RUNNER_TEMP"]) / "service.json").read_text())
if data.get("failures") or len(data.get("services", [])) != 1:
    raise SystemExit("ECS service missing or inaccessible; deployment stopped.")
PY

# Distinguish an existing immutable tag from an unexpected ECR error.
aws ecr batch-get-image \
  --repository-name "$APP_NAME" \
  --image-ids "imageTag=$GITHUB_SHA" \
  > "$RUNNER_TEMP/image.json"

DIGEST=$(python - <<'PY'
import json
import os
from pathlib import Path

data = json.loads((Path(os.environ["RUNNER_TEMP"]) / "image.json").read_text())
if data.get("images"):
    print(data["images"][0]["imageId"]["imageDigest"])
elif data.get("failures") and all(
    item["failureCode"] == "ImageNotFound" for item in data["failures"]
):
    print("")
else:
    raise SystemExit("Unexpected ECR lookup result")
PY
)

if [ -z "$DIGEST" ]; then
  aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin \
        "732108543574.dkr.ecr.${AWS_REGION}.amazonaws.com"

  docker build --platform linux/amd64 \
    -t "$ECR_URL:$GITHUB_SHA" .

  docker push "$ECR_URL:$GITHUB_SHA"

  DIGEST=$(aws ecr describe-images \
    --repository-name "$APP_NAME" \
    --image-ids "imageTag=$GITHUB_SHA" \
    --query 'imageDetails[0].imageDigest' \
    --output text)
fi

case "$DIGEST" in
  sha256:*) ;;
  *) echo "Invalid image digest"; exit 1 ;;
esac

CURRENT_TASK=$(python - <<'PY'
import json
import os
from pathlib import Path

data = json.loads((Path(os.environ["RUNNER_TEMP"]) / "service.json").read_text())
print(data["services"][0]["taskDefinition"])
PY
)

echo "Previous task definition: $CURRENT_TASK"

aws ecs describe-task-definition \
  --task-definition "$CURRENT_TASK" \
  > "$RUNNER_TEMP/task.json"

export DEPLOY_IMAGE="$ECR_URL@$DIGEST"

python - <<'PY'
import json
import os
from pathlib import Path

directory = Path(os.environ["RUNNER_TEMP"])
task = json.loads((directory / "task.json").read_text())["taskDefinition"]

allowed = {
    "family", "taskRoleArn", "executionRoleArn", "networkMode",
    "containerDefinitions", "volumes", "placementConstraints",
    "requiresCompatibilities", "cpu", "memory",
    "runtimePlatform", "ephemeralStorage",
}
task = {key: value for key, value in task.items() if key in allowed}

containers = [item for item in task["containerDefinitions"] if item["name"] == "app"]
if len(containers) != 1:
    raise SystemExit("Expected exactly one app container")

container = containers[0]
container["image"] = os.environ["DEPLOY_IMAGE"]

environment = [
    item for item in container.get("environment", [])
    if item["name"] != "APP_VERSION"
]
environment.append({"name": "APP_VERSION", "value": os.environ["GITHUB_SHA"]})
container["environment"] = environment

(directory / "release-task.json").write_text(json.dumps(task))
PY

NEW_TASK=$(aws ecs register-task-definition \
  --cli-input-json "file://$RUNNER_TEMP/release-task.json" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

aws ecs update-service \
  --cluster "$APP_NAME" \
  --service "$APP_NAME" \
  --task-definition "$NEW_TASK" > /dev/null

aws ecs wait services-stable \
  --cluster "$APP_NAME" \
  --services "$APP_NAME"

aws ecs describe-services \
  --cluster "$APP_NAME" \
  --services "$APP_NAME" > "$RUNNER_TEMP/deployed-service.json"

TARGET_GROUP=$(python - <<'PY'
import json
import os
from pathlib import Path

directory = Path(os.environ["RUNNER_TEMP"])
service = json.loads(
    (directory / "deployed-service.json").read_text()
)["services"][0]

if service["desiredCount"] < 1 or service["runningCount"] != service["desiredCount"]:
    raise SystemExit("Expected healthy running capacity")

registered = json.loads(
    (directory / "release-task.json").read_text()
)
# The exact active revision is checked separately in the shell.
print(service["loadBalancers"][0]["targetGroupArn"])
PY
)

ACTIVE_TASK=$(aws ecs describe-services \
  --cluster "$APP_NAME" \
  --services "$APP_NAME" \
  --query 'services[0].taskDefinition' \
  --output text)

test "$ACTIVE_TASK" = "$NEW_TASK"

aws elbv2 describe-target-health \
  --target-group-arn "$TARGET_GROUP" \
  > "$RUNNER_TEMP/targets.json"

python - <<'PY'
import json
import os
from pathlib import Path

targets = json.loads(
    (Path(os.environ["RUNNER_TEMP"]) / "targets.json").read_text()
)["TargetHealthDescriptions"]

active = [
    target for target in targets
    if target["TargetHealth"]["State"] != "draining"
]
if not active or any(
    target["TargetHealth"]["State"] != "healthy" for target in active
):
    raise SystemExit("Target health acceptance failed")
PY

python - <<'PY'
import json
import os
from urllib.request import urlopen

expected = {
    "/health": {"status": "healthy"},
    "/version": {"version": os.environ["GITHUB_SHA"]},
}

for path, body in expected.items():
    with urlopen(os.environ["SERVICE_URL"] + path, timeout=15) as response:
        if response.status != 200 or json.load(response) != body:
            raise SystemExit(f"Smoke test failed: {path}")

print("Deployment verified: healthy targets and HTTPS endpoint contracts")
PY
