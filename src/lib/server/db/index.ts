import { env } from '$env/dynamic/private';
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';

if (!env.DATABASE_URL) {
  throw new Error('DATABASE_URL must be set before using the database client');
}

const client = postgres(env.DATABASE_URL);

export const db = drizzle(client);
