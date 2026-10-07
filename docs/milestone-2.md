# Milestone 2 — Dockerization

## Verified in Ubuntu/WSL

- Docker image built successfully.
- Container health status: healthy.
- Runtime user: UID/GID 10001.
- Application listens on 0.0.0.0:8000 inside the container.
- /health and /version return HTTP 200.
- /version reports the configured Git commit SHA.
- Application and access logs reach standard streams.

## Design

The image uses a digest-pinned slim Python base and pinned dependencies.
Only application source and runtime requirements enter the build context.
The container runs as a non-root user.

Local validation uses a read-only filesystem, dropped capabilities,
no-new-privileges, and a loopback-only host port mapping.

## Limitation

Docker Scout is unavailable locally. No image vulnerability scan was
performed. Image scanning must be added and reviewed during CI/CD.
