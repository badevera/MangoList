import { json } from '@sveltejs/kit';
import { sql } from 'drizzle-orm';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

type HealthCheck = {
  name: string;
  status: 'up' | 'down';
  code: number;
  detail?: string;
};

export const GET: RequestHandler = async () => {
  const checks: HealthCheck[] = [
    {
      name: 'Application',
      status: 'up',
      code: 200
    }
  ];

  try {
    await db.execute(sql`select 1`);
    checks.push({
      name: 'PostgreSQL',
      status: 'up',
      code: 200
    });
  } catch (error) {
    console.error('Health check could not connect to PostgreSQL', error);
    checks.push({
      name: 'PostgreSQL',
      status: 'down',
      code: 503,
      detail: 'Database connection failed'
    });
  }

  const healthy = checks.every((check) => check.status === 'up');

  return json(
    {
      status: healthy ? 'healthy' : 'unhealthy',
      checks,
      checkedAt: new Date().toISOString()
    },
    { status: healthy ? 200 : 503 }
  );
};
