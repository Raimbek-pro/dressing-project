# Dressing project

Minimal stack: **Nginx** (serves frontend + proxies API) → **Node API** → **PostgreSQL**.

```
browser ──► nginx :8080 ──┬── /        → frontend/index.html
                          └── /api/... → api:3000 → db:5432 (Postgres)
```

## Run

Requires Docker Desktop.

```bash
cd "dressing project"
docker compose up --build
```

Open http://localhost:8080

## Stop

```bash
docker compose down        # stop
docker compose down -v     # stop and delete database data
```

## Useful

```bash
# Open psql inside the database
docker compose exec db psql -U app -d dressing

# Logs
docker compose logs -f api
```

## API

| Method | URL | Body |
|---|---|---|
| GET | /api/items | – |
| POST | /api/items | `{"name": "Black jacket"}` |
| DELETE | /api/items/:id | – |

`db/init.sql` runs only the first time the database volume is created.
To re-run it: `docker compose down -v && docker compose up --build`.
