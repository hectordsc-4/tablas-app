#!/usr/bin/env sh
# Inicializa tablas en PostgreSQL del servidor.
# Uso:
#   export DATABASE_URL="postgresql://user:pass@host:5432/exi_db"
#   ./database/init_db.sh
#
# También acepta variables sueltas: PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SQL_FILE="${SCRIPT_DIR}/tables.sql"

if [ ! -f "$SQL_FILE" ]; then
  echo "No se encontró tables.sql" >&2
  exit 1
fi

if [ -n "${DATABASE_URL:-}" ]; then
  # psycopg2 usa postgresql+psycopg2://... ; psql quiere postgresql://...
  PSQL_URL=$(printf '%s' "$DATABASE_URL" | sed 's#postgresql+psycopg2://#postgresql://#')
  echo "Aplicando schema con DATABASE_URL..."
  psql "$PSQL_URL" -v ON_ERROR_STOP=1 -f "$SQL_FILE"
else
  : "${PGHOST:=localhost}"
  : "${PGPORT:=5432}"
  : "${PGUSER:=postgres}"
  : "${PGDATABASE:=exi_db}"
  if [ -z "${PGPASSWORD:-}" ]; then
    echo "Define DATABASE_URL o PGPASSWORD" >&2
    exit 1
  fi
  echo "Aplicando schema en ${PGHOST}:${PGPORT}/${PGDATABASE}..."
  PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -v ON_ERROR_STOP=1 -f "$SQL_FILE"
fi

echo "Listo."
