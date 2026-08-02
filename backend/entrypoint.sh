#!/bin/sh
set -e

echo "[exi] Comprobando variables de entorno..."

if [ -z "${DATABASE_URL:-}" ]; then
  echo "[exi] ERROR: DATABASE_URL no está definida en el contenedor." >&2
  echo "[exi] Coolify → tablas-app → Environment Variables → añade DATABASE_URL" >&2
  echo "[exi] Marca Build Variable + Runtime Variable, guarda y Redeploy." >&2
  echo "[exi] Variables visibles ahora:" >&2
  env | grep -E '^(DATABASE|POSTGRES|PG|BOOTSTRAP|APP_|DEBUG|CORS)' | sed 's/=.*/=***/' >&2 || true
  exit 1
fi

case "$DATABASE_URL" in
  *://*@localhost:*|*://*@127.0.0.1:*|*://localhost:*|*://127.0.0.1:*)
    echo "[exi] ERROR: DATABASE_URL apunta a localhost/127.0.0.1." >&2
    echo "[exi] Dentro de Docker eso NO es el Postgres de Coolify." >&2
    echo "[exi] Usa el host interno, p.ej. ...@lcpp4fhc8vzq2i8vwbq5p3pc:5432/exi_db" >&2
    exit 1
    ;;
esac

# Mostrar host sin password
python - <<'PY'
import os
from urllib.parse import urlparse
url = os.environ.get("DATABASE_URL", "")
u = urlparse(url.replace("postgresql+psycopg2://", "postgresql://", 1))
print(f"[exi] DATABASE_URL host={u.hostname!r} db={(u.path or '').lstrip('/')!r} user={u.username!r}")
boot = os.environ.get("BOOTSTRAP_DATABASE_URL", "")
if boot:
    b = urlparse(boot.replace("postgresql+psycopg2://", "postgresql://", 1))
    print(f"[exi] BOOTSTRAP host={b.hostname!r} db={(b.path or '').lstrip('/')!r}")
else:
    print("[exi] BOOTSTRAP_DATABASE_URL no definida (se probará listaviva/postgres/template1 en el mismo host)")
PY

echo "[exi] Creando base de datos si hace falta..."
python /app/backend/ensure_database.py

echo "[exi] Esperando PostgreSQL (base destino)..."
python /app/backend/wait_for_db.py

echo "[exi] Aplicando esquema si hace falta..."
python /app/backend/init_schema.py

echo "[exi] Arrancando API..."
exec "$@"
