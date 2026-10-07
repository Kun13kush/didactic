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
