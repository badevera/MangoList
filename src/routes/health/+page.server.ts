import type { PageServerLoad } from './$types';

type HealthCheck = {
  name: string;
  status: 'up' | 'down';
  code: number;
  detail?: string;
};

type HealthResponse = {
  status: 'healthy' | 'unhealthy';
  checks: HealthCheck[];
  checkedAt: string;
};

export const load: PageServerLoad = async ({ fetch }) => {
  const response = await fetch('/api/health');
  const result = (await response.json()) as HealthResponse;

  return {
    ...result,
    endpointCode: response.status
  };
};
