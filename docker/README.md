# Local PostgreSQL

From the repository root, start PostgreSQL with:

```bash
docker compose up -d
```

The database is available at `localhost:5432`. The matching local connection string is:

```env
DATABASE_URL=postgres://mango_app:local_password@localhost:5432/mango_list
```

Stop the container while keeping its data:

```bash
docker compose stop
```

Stop the container and remove it:

```bash
docker compose down
```

To also delete the local database volume and all stored data:

```bash
docker compose down -v
```
