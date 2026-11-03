<script lang="ts">
  export let data: {
    status: 'healthy' | 'unhealthy';
    checks: { name: string; status: 'up' | 'down'; code: number; detail?: string }[];
    checkedAt: string;
    endpointCode: number;
  };
</script>

<svelte:head>
  <title>System health — Mango List</title>
  <meta name="description" content="Mango List application and database health status." />
</svelte:head>

<main class="min-h-screen bg-cream px-6 py-12">
  <section class="mx-auto max-w-3xl rounded-[2rem] bg-white p-8 shadow-card md:p-12">
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div>
        <a class="text-sm font-semibold text-leaf hover:underline" href="/">← Mango List</a>
        <h1 class="mt-5 font-display text-5xl">System health</h1>
        <p class="mt-3 text-slate-500">Live status of the application and its dependencies.</p>
      </div>
      <span
        class:rounded-full={true}
        class:bg-[#e6f0e2]={data.status === 'healthy'}
        class:text-leaf={data.status === 'healthy'}
        class:bg-[#fee2e2]={data.status === 'unhealthy'}
        class:text-red-700={data.status === 'unhealthy'}
        class="px-4 py-2 text-sm font-bold uppercase tracking-[0.12em]"
      >
        {data.status}
      </span>
    </div>

    <div class="mt-10 overflow-hidden rounded-2xl border border-slate-100">
      {#each data.checks as check}
        <div class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 px-5 py-4 last:border-0">
          <div class="flex items-center gap-3">
            <span class:text-leaf={check.status === 'up'} class:text-red-600={check.status === 'down'} aria-hidden="true">
              {check.status === 'up' ? '●' : '●'}
            </span>
            <div>
              <p class="font-semibold">{check.name}</p>
              {#if check.detail}<p class="text-sm text-red-600">{check.detail}</p>{/if}
            </div>
          </div>
          <span class="rounded-lg bg-slate-100 px-3 py-1 font-mono text-sm text-slate-600">{check.code}</span>
        </div>
      {/each}
    </div>

    <div class="mt-6 flex flex-wrap justify-between gap-2 text-sm text-slate-500">
      <span>Health endpoint response: <strong>{data.endpointCode}</strong></span>
      <span>Checked {new Date(data.checkedAt).toLocaleString()}</span>
    </div>
  </section>
</main>
