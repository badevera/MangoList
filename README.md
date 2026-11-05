# Mango List

A simple grocery list maker built with SvelteKit, TypeScript, Tailwind CSS, daisyUI, PostgreSQL, and Drizzle ORM.

## Getting started

```bash
npm install
npm run db:up
npm run db:generate
npm run db:migrate
npm run dev
```

The app currently provides a username-only sign-in flow and an interactive local grocery-list experience. Lists and items are ready to be connected to the database schema in `src/lib/server/db/schema.ts`.

## Local PostgreSQL with Docker Compose

Install Docker Desktop, then start the local PostgreSQL service:

```bash
npm run db:up
```

The Compose service uses the database name `mango_list`, username `mango_app`, password `local_password`, and port `5432`. Copy `.env.example` to `.env` if needed. Drizzle uses this same `DATABASE_URL` when generating and applying migrations:

```env
DATABASE_URL=postgres://mango_app:local_password@localhost:5432/mango_list
```

To stop PostgreSQL without deleting its data:

```bash
npm run db:down
```

To reset the local database completely, run `docker compose down -v`.

## Scripts

- `npm run dev` — start the development server
- `npm run check` — run Svelte and TypeScript checks
- `npm run build` — create a production build
- `npm run db:up` — start local PostgreSQL
- `npm run db:down` — stop local PostgreSQL
- `npm run db:generate` — generate a Drizzle migration from schema changes
- `npm run db:migrate` — apply pending Drizzle migrations

## Health checks

- `GET /api/health` — returns JSON with application and PostgreSQL checks. It returns `200` when all checks pass and `503` when a dependency is unavailable.
- `/health` — browser-friendly view of the same checks and response codes.

## Deploying the Docker image to EC2

The app includes a production `Dockerfile` and an EC2 Compose file. Use an external PostgreSQL database for production (for example, Amazon RDS), and set its connection string in an uncommitted `.env` file:

```env
DATABASE_URL=postgres://USER:PASSWORD@DB_HOST:5432/mango_list
ORIGIN=http://localhost:3000
```

Build and test the image locally:

```bash
docker build -t mango-list:latest .
docker run --rm --env-file .env -p 3000:3000 mango-list:latest
```

To upload the image directly to EC2 without a registry:

```bash
docker save mango-list:latest | gzip > mango-list.tar.gz
scp mango-list.tar.gz ec2-user@EC2_PUBLIC_IP:/home/ec2-user/
ssh ec2-user@EC2_PUBLIC_IP
gunzip -c mango-list.tar.gz | docker load
```

On the instance, upload `docker-compose.ec2.yml` and `.env` (never commit `.env`), then start the app:

```bash
docker compose -f docker-compose.ec2.yml up -d
docker compose -f docker-compose.ec2.yml logs -f app
```

The Compose command applies Drizzle migrations before starting the server. Verify the deployment with:

```bash
curl -i http://127.0.0.1:3000/api/health
```

Set `ORIGIN` to the exact URL users use to open the app. For example, use `ORIGIN=http://EC2_PUBLIC_IP:3000` for direct testing, or `ORIGIN=https://your-domain.example` behind HTTPS. Open port `3000` only to the reverse proxy or trusted network in the EC2 security group. For a public deployment, put Nginx or an AWS load balancer in front of the container, use HTTPS, and expose only ports `80`/`443`.

For later releases, rebuild the image, repeat `docker save`/`scp`/`docker load`, then run `docker compose -f docker-compose.ec2.yml up -d`. Do not commit `.env` or private SSH keys.
