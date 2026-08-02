# EXI / tablas-app

Sistema **PostgreSQL + FastAPI + HTML/CSS/JS**.

## Estructura

```
├── backend/          # FastAPI
├── frontend/         # UI estática (servida por FastAPI)
├── database/         # SQL e init
├── Dockerfile              # Deploy (Coolify / Docker)
└── docker-compose.dev.yml  # Solo desarrollo local
```

## Deploy en Coolify (VPS con PostgreSQL)

1. En Coolify: **New Resource → Application** → repo `hectordsc-4/tablas-app`.
2. Build Pack: **Dockerfile** (usa el `Dockerfile` de la raíz).
3. Puerto: **8000** (o el que inyecte Coolify vía `PORT`).
4. Variables de entorno:

| Variable | Ejemplo |
|----------|---------|
| `DATABASE_URL` | `postgresql+psycopg2://USER:PASS@HOST:5432/exi_db` |
| `APP_NAME` | `EXI API` |
| `DEBUG` | `false` |
| `CORS_ORIGINS` | `*` (o tu dominio) |

Si Postgres está en el mismo servidor/Docker network, usa el hostname interno del servicio (no `localhost` desde dentro del contenedor de la API).

5. **Una vez** crea la BD (si no existe) y aplica tablas:

```bash
# En el servidor / contenedor con psql, o desde un cliente:
psql "postgresql://USER:PASS@HOST:5432/exi_db" -f database/tables.sql
```

O con el script:

```bash
export DATABASE_URL="postgresql://USER:PASS@HOST:5432/exi_db"
chmod +x database/init_db.sh
./database/init_db.sh
```

6. Deploy. Healthcheck: `GET /api/health`.

La app sirve frontend + API en el mismo origen (`/`, `/home`, `/admin`, `/api/...`).

### SMTP (opcional)

Si no configuras SMTP, el recordatorio de contraseña se guarda en `backend/outbox/` dentro del contenedor.

| Variable | Descripción |
|----------|-------------|
| `SMTP_HOST` | Servidor SMTP |
| `SMTP_PORT` | `587` |
| `SMTP_USER` / `SMTP_PASSWORD` | Credenciales |
| `SMTP_FROM` | Remitente |
| `SMTP_TLS` / `SMTP_SSL` | `true` / `false` |

---

## Desarrollo local (Windows)

### Credenciales PostgreSQL (local)

| Campo | Valor |
|-------|-------|
| Host | `localhost` |
| Puerto | `5432` |
| Usuario | `postgres` |
| Contraseña | `exi_local_2026` |
| Base de datos | `exi_db` |

### Arranque

```powershell
# 1) PostgreSQL
cd database
.\start_postgres.ps1

# 2) Tablas (primera vez)
.\init_db.ps1

# 3) API + frontend
cd ..\backend
copy .env.example .env   # si aún no tienes .env
.\start_api.ps1
```

Abre: **http://127.0.0.1:8000** — Docs: **http://127.0.0.1:8000/docs**

### Usuarios de prueba (si aplicaste seed en tables.sql)

| Usuario | Contraseña |
|---------|------------|
| `admin` | `admin123` |
| `demo`  | `demo123`  |

### Docker Compose local (opcional)

```bash
docker compose -f docker-compose.dev.yml up --build
```

Levanta API + Postgres de prueba y aplica `database/tables.sql` al crear el volumen. En Coolify usa solo el `Dockerfile` (Postgres ya está en el servidor).

---

## API

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/auth/login` | Login |
| GET | `/api/health` | Healthcheck |
| GET/POST | `/api/usuarios` | Usuarios |
| GET/PUT/DELETE | `/api/usuarios/{cod}` | Usuario |
| GET | `/api/logins` | Logins |
| GET/POST | `/api/permisos` | Permisos |
| GET/POST/DELETE | `/api/permisos-usuario` | Asignación |

## Notas

- Las contraseñas están en texto plano de momento (diseño original).
- No subas `.env`, `tools/pgsql`, ni `tools/pgdata` al repo.
- Formato `DATABASE_URL` para SQLAlchemy: `postgresql+psycopg2://...`
