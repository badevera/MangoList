# Docker

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage production image for the SvelteKit app |
| `docker-compose.yml` | Local PostgreSQL only |

## Local Postgres

From the **repository root**:

```bash
npm run db:up
npm run db:down
```

Or:

```bash
docker compose -f docker/docker-compose.yml -p mango-list up -d
```

Connection string:

```env
DATABASE_URL=postgresql://mango_app:local_password@localhost:5432/mango_list
```

## Production image

Build from the repo root (build context is `.` so `src/`, `drizzle/`, etc. are included):

```bash
docker build -f docker/Dockerfile -t mango-list:latest .
```

`scripts/deploy.ps1` does this and pushes to ECR.
