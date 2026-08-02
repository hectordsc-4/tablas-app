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
4. Variables de entorno (mismas que baseapps / Postgres lista-viva):

| Variable | Ejemplo | Coolify |
|----------|---------|---------|
| `DATABASE_URL` | `postgresql+psycopg2://listaviva:PASS@HOST:5432/exi_db` | **Runtime ON**, Build OFF |
| `BOOTSTRAP_DATABASE_URL` | `postgresql+psycopg2://listaviva:PASS@HOST:5432/listaviva` | Runtime ON, Build OFF |
| `BOOTSTRAP_DB` | `listaviva` | Runtime ON |
| `APP_NAME` | `EXI API` | Runtime ON |
| `DEBUG` | `false` | Runtime ON |
| `CORS_ORIGINS` | `*` | Runtime ON |

Importante: el **Value** no puede estar vacío. No uses `localhost`. No marques solo Build Variable (deja la URL vacía en la imagen).

Al arrancar el contenedor:
1. Crea `exi_db` si no existe (vía bootstrap `listaviva`).
2. Aplica `database/tables.sql` si faltan tablas.
3. Levanta FastAPI + frontend.

5. Deploy. Healthcheck: `GET /api/health`. Login de prueba: `admin` / `admin123`.

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
