"""Aplica database/tables.sql si hace falta y verifica que se pueda leer."""
from __future__ import annotations

import sys
from pathlib import Path

import psycopg2
from psycopg2.extensions import connection as PgConnection

from app.config import settings

SQL_PATH = Path(__file__).resolve().parents[1] / "database" / "tables.sql"
REQUIRED_COLUMNS = {
    "usr_codusr",
    "usr_name",
    "usr_pass",
    "usr_tipusr",
    "usr_email",
    "usr_fecbaj",
}


def _dsn() -> str:
    url = settings.database_url
    if url.startswith("postgresql+psycopg2://"):
        return url.replace("postgresql+psycopg2://", "postgresql://", 1)
    return url


def _table_exists(conn: PgConnection) -> bool:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = 'exi_usuarios'
            """
        )
        return cur.fetchone() is not None


def _columns_ok(conn: PgConnection) -> bool:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'exi_usuarios'
            """
        )
        cols = {row[0] for row in cur.fetchall()}
    return REQUIRED_COLUMNS.issubset(cols)


def _can_read_usuarios(conn: PgConnection) -> tuple[bool, str]:
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT usr_codusr FROM exi_usuarios LIMIT 1")
            cur.fetchall()
        return True, ""
    except Exception as exc:  # noqa: BLE001
        return False, str(exc)


def _apply_sql(conn: PgConnection) -> None:
    sql = SQL_PATH.read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql)


def _ensure_seed(conn: PgConnection) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO exi_usuarios
                (usr_codusr, usr_name, usr_usrcre, usr_pass, usr_email, usr_descri, usr_tipusr)
            VALUES
                ('admin', 'Administrador', 'SYSTEM', 'admin123', 'admin@exi.local', 'Usuario administrador', 'SUPERADMIN'),
                ('demo',  'Usuario Demo',  'SYSTEM', 'demo123',  'demo@exi.local',  'Usuario de demostración', 'DIRECTOR')
            ON CONFLICT (usr_codusr) DO NOTHING
            """
        )


def main() -> int:
    if not SQL_PATH.is_file():
        print(f"[exi] No se encontró {SQL_PATH}", file=sys.stderr)
        return 1

    conn = psycopg2.connect(_dsn())
    conn.autocommit = True
    try:
        exists = _table_exists(conn)
        cols_ok = _columns_ok(conn) if exists else False

        if not exists or not cols_ok:
            if exists and not cols_ok:
                print("[exi] Schema incompleto en exi_usuarios; reaplicando tables.sql...")
            else:
                print("[exi] Aplicando schema (tables.sql)...")
            try:
                _apply_sql(conn)
            except Exception as exc:  # noqa: BLE001
                print(f"[exi] Error aplicando schema: {exc}", file=sys.stderr)
                return 1
        else:
            print("[exi] Esquema ya presente.")

        readable, err = _can_read_usuarios(conn)
        if not readable:
            print(f"[exi] No se puede leer exi_usuarios: {err}", file=sys.stderr)
            print(
                "[exi] Puede ser un problema de permisos/ownership en exi_db. "
                "Prueba en Postgres: GRANT ALL ON ALL TABLES IN SCHEMA public TO listaviva;",
                file=sys.stderr,
            )
            return 1

        _ensure_seed(conn)
        print("[exi] Schema OK y usuarios seed verificados.")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
