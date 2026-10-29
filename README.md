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
