FROM python@sha256:f6a589d43c42b9e7f7dc67a12d37132491f362859a5d750607710cc56da3bc72

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    APP_ENV=dev \
    APP_VERSION=local

WORKDIR /app

RUN addgroup -g 10001 appuser \
    && adduser -D -H -u 10001 -G appuser -s /sbin/nologin appuser

COPY app/requirements.txt /app/requirements.txt

RUN python -m pip install --no-cache-dir -r /app/requirements.txt \
    && python -m pip check \
    && python -m pip uninstall --yes pip

COPY app/__init__.py app/main.py /app/app/

USER 10001:10001

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3).close()"]

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
