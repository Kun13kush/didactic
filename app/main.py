"""Minimal Finzla assessment HTTP service."""

import logging
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI


def create_app() -> FastAPI:
    environment = os.getenv("APP_ENV", "dev")
    version = os.getenv("APP_VERSION", "local")

    if environment not in {"dev", "test", "prod"}:
        raise ValueError("APP_ENV must be dev, test, or prod")

    if not version.strip():
        raise ValueError("APP_VERSION must not be empty")

    @asynccontextmanager
    async def lifespan(application: FastAPI):
        logging.basicConfig(level=logging.INFO, stream=sys.stdout)
        logging.getLogger(__name__).info(
            "Service started environment=%s", environment
        )
        yield

    application = FastAPI(
        lifespan=lifespan,
        docs_url=None,
        redoc_url=None,
        openapi_url=None,
    )
    application.state.environment = environment

    @application.get("/health")
    def health() -> dict[str, str]:
        return {"status": "healthy"}

    @application.get("/version")
    def release_version() -> dict[str, str]:
        return {"version": version}

    return application


app = create_app()
