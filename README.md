# Finzla Cloud & Platform Assessment

## Current scope

Milestone 1 implements a minimal FastAPI application.
Docker, Terraform, AWS infrastructure and CI/CD are future milestones.
No AWS deployment or HTTPS verification has been performed.

The authoritative assessment PDF remains pending.

## Requirements

Ubuntu/WSL, Python 3.11 or newer, Git, and curl.

## Local development

```bash
python3 -m venv .venv-linux
source .venv-linux/bin/activate
python -m pip install -r requirements-dev.txt
python -m pytest -q

export APP_ENV=dev
export APP_VERSION=local
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
Endpoints
- GET /health: HTTP 200, {"status":"healthy"}
- GET /version: HTTP 200, {"version":"<APP_VERSION>"}
APP_ENV accepts dev, test, or prod and defaults to dev.
APP_VERSION defaults to local; deployments will supply the Git SHA.
Invalid APP_ENV or empty APP_VERSION fails startup.
Logging and security
Startup logs go to stdout. Uvicorn emits server and request logs to
standard streams. Never include secrets in URLs or log messages.
The application requires no secrets or AWS credentials.
Local development binds to loopback.
Container binding to 0.0.0.0:8000 will be added in Milestone 2.
Health confirms the application can serve requests; it does not
validate AWS infrastructure or external dependencies.
Validation
Automated tests check endpoint contracts, configuration and invalid input.
Manual curl checks verify actual HTTP serving.
Save actual validation output under docs/evidence/.
The pinned test dependencies currently emit a Starlette deprecation
warning about httpx. Tests passed with that warning on the earlier
Windows run; Ubuntu validation must be recorded separately.

## Docker

Build from the repository root:

```bash
IMAGE_TAG=$(git rev-parse HEAD)
docker build -t "finzla-app:${IMAGE_TAG}" .
docker run -d --name finzla-app \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop ALL \
  --security-opt no-new-privileges=true \
  -p 127.0.0.1:8001:8000 \
  -e APP_ENV=dev \
  -e APP_VERSION="$IMAGE_TAG" \
  "finzla-app:${IMAGE_TAG}"
Check /health and /version at http://127.0.0.1:8001.
Container health is available through docker inspect.
The runtime user is UID 10001.
Local image vulnerability scanning remains pending because Docker Scout
is unavailable. See docs/milestone-2.md for validation and limitations.

## Terraform foundation and remote state

Terraform roots are separated into bootstrap, dev, and prod.

The bootstrap root manages the S3 state bucket. Its initial local state
is migrated to S3 after the bucket is created and verified.

State bucket: finzla-tfstate-732108543574-eu-west-2
Region: eu-west-2

State keys:
- bootstrap/terraform.tfstate
- dev/terraform.tfstate
- prod/terraform.tfstate

The bucket has SSE-S3 encryption, versioning, public access blocking,
disabled ACLs, and an HTTPS-only access policy.

Each backend enables native S3 locking with use_lockfile=true.
Terraform acquires a temporary lock object for operations requiring
state locking, preventing concurrent writes to the same state key.
Never bypass locking or force-unlock without confirming the original
operation is no longer running.

State access requires authorized IAM permissions. Current access
depends on existing account IAM policies; dedicated scoped roles
will be introduced during IAM hardening. Separate state keys do not
by themselves prevent a principal from accessing both environments.

Engineers must use the shared production backend. Independent local
production state can produce conflicting resource ownership and
unsafe changes.

State files, backups, saved plans and .terraform directories must
never be committed. Provider .terraform.lock.hcl files are committed.

Bucket versioning supports recovery of earlier state versions, but
restoration must be coordinated with actual infrastructure changes.
