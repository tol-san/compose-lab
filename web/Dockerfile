# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12

# ---------- Stage 1: base ----------
# Shared settings for every later stage.
FROM python:${PYTHON_VERSION}-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app

# ---------- Stage 2: builder ----------
# Installs dependencies into a virtualenv. Nothing from this stage
# ships except the /opt/venv directory we copy out of it.
FROM base AS builder
RUN python -m venv /opt/venv
# Copy ONLY requirements first so this layer stays cached until deps change.
COPY requirements.txt .
# BuildKit cache mount: pip's download cache survives between builds
# without ending up inside the image.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# ---------- Stage 3: runtime ----------
# Common runtime base: non-root user + the venv from the builder.
FROM base AS runtime
RUN groupadd --system --gid 10001 app \
 && useradd  --system --uid 10001 --gid app --no-create-home \
             --shell /usr/sbin/nologin app
COPY --from=builder /opt/venv /opt/venv
ENV FLASK_APP=app.py
EXPOSE 5000

# ---------- Stage 4: dev ----------
# Flask dev server with debugger and reloader. Code is bind-mounted by Compose.
FROM runtime AS dev
ENV FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000
COPY --chown=app:app . .
USER app
CMD ["flask", "run"]

# ---------- Stage 5: prod (LAST stage = default target) ----------
FROM runtime AS prod
COPY --chown=app:app app.py .
USER app
# Exec form (JSON array) so gunicorn is PID 1 and receives SIGTERM correctly.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", \
     "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "app:app"]