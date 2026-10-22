# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12

# ---------- Stage 1: base ----------
FROM python:${PYTHON_VERSION}-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app

# ---------- Stage 2: builder ----------
# Heavy build tools (compiler, headers) live ONLY in this stage.
FROM base AS builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential libpq-dev \
 && rm -rf /var/lib/apt/lists/*
RUN python -m venv /opt/venv
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# ---------- Stage 3: runtime ----------
# Only the shared library psycopg2 needs at runtime. No compiler.
FROM base AS runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq5 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 10001 app \
 && useradd  --system --uid 10001 --gid app --no-create-home \
             --shell /usr/sbin/nologin app
COPY --from=builder /opt/venv /opt/venv
ENV FLASK_APP=app.py
EXPOSE 5000

# ---------- Stage 4: dev ----------
FROM runtime AS dev
ENV FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000
COPY --chown=app:app . .
USER app
CMD ["flask", "run"]

# ---------- Stage 5: prod (default target) ----------
FROM runtime AS prod
COPY --chown=app:app app.py .
USER app
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", \
     "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "app:app"]