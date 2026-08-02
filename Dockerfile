FROM python:3.12-slim

# Coolify inyecta estas como build-args si están marcadas en Environment Variables.
ARG DATABASE_URL
ARG BOOTSTRAP_DATABASE_URL
ARG BOOTSTRAP_DB=listaviva
ARG APP_NAME=EXI API
ARG DEBUG=false
ARG CORS_ORIGINS=*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    DATABASE_URL=${DATABASE_URL} \
    BOOTSTRAP_DATABASE_URL=${BOOTSTRAP_DATABASE_URL} \
    BOOTSTRAP_DB=${BOOTSTRAP_DB} \
    APP_NAME=${APP_NAME} \
    DEBUG=${DEBUG} \
    CORS_ORIGINS=${CORS_ORIGINS}

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend /app/backend
COPY frontend /app/frontend
COPY database /app/database

WORKDIR /app/backend

RUN chmod +x /app/backend/entrypoint.sh

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${PORT}/api/health" || exit 1

ENTRYPOINT ["/app/backend/entrypoint.sh"]
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
