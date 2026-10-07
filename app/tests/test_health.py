import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("APP_VERSION", "a" * 40)

    with TestClient(create_app()) as test_client:
        yield test_client


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_version(client):
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {"version": "a" * 40}


def test_environment_is_used(monkeypatch):
    monkeypatch.setenv("APP_ENV", "prod")
    assert create_app().state.environment == "prod"


def test_invalid_environment(monkeypatch):
    monkeypatch.setenv("APP_ENV", "invalid")

    with pytest.raises(ValueError, match="APP_ENV"):
        create_app()


def test_empty_version(monkeypatch):
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("APP_VERSION", " ")

    with pytest.raises(ValueError, match="APP_VERSION"):
        create_app()


def test_local_defaults(monkeypatch):
    monkeypatch.delenv("APP_ENV", raising=False)
    monkeypatch.delenv("APP_VERSION", raising=False)

    application = create_app()
    assert application.state.environment == "dev"

    with TestClient(application) as client:
        assert client.get("/version").json() == {"version": "local"}


def test_unknown_path(client):
    assert client.get("/missing").status_code == 404
