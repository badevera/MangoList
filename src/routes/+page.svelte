<script lang="ts">
  import { enhance } from '$app/forms';

  type GroceryList = {
    id: string;
    name: string;
    items: { id: string; name: string; completed: boolean }[];
  };

  export let data: { username: string | null; lists: GroceryList[] };
  export let form: { message?: string } | null = null;
  let username = '';
  let activeListId = '';
  let newItem = '';
  let newListName = '';
  let showNewList = false;

  $: lists = data.lists;
  $: if (!activeListId || !lists.some((list) => list.id === activeListId)) activeListId = lists[0]?.id ?? '';
  $: activeList = lists.find((list) => list.id === activeListId) ?? lists[0];
  $: completedCount = activeList?.items.filter((item) => item.completed).length ?? 0;
</script>

<svelte:head>
  <title>Mango List — groceries made simple</title>
  <meta
    name="description"
    content="A simple, friendly grocery list maker for everything you need."
  />
</svelte:head>

{#if !data.username}
  <main class="flex min-h-screen items-center justify-center bg-cream px-6 py-12">
    <section class="grid w-full max-w-5xl overflow-hidden rounded-[2rem] bg-white shadow-card md:grid-cols-2">
      <div class="flex min-h-[32rem] flex-col bg-leaf p-8 text-white md:p-12">
        <div class="flex items-center gap-2 text-lg font-bold">
          <span class="text-2xl">🥭</span>
          <span>Mango List</span>
        </div>
        <div class="flex flex-1 items-center">
          <h1 class="font-display text-5xl leading-tight md:text-6xl">
            Everyday lists for groceries and more
          </h1>
        </div>
      </div>
      <div class="flex min-h-[32rem] flex-col justify-center p-8 md:p-12">
        <div class="mb-10">
          <p class="mb-3 text-sm font-bold uppercase tracking-[0.18em] text-leaf">Welcome back</p>
          <h2 class="font-display text-4xl">Let's make a list.</h2>
          <p class="mt-3 text-slate-500">Sign in with a username to get started.</p>
        </div>
        <form method="POST" action="?/signIn" use:enhance>
          <label class="mb-2 block text-sm font-semibold" for="username">Your username</label>
          <input
            id="username"
            bind:value={username}
            name="username"
            class="input input-bordered h-14 w-full rounded-xl border-slate-200 bg-slate-50"
            placeholder="e.g. alex"
            autocomplete="username"
            required
          />
          <button class="btn mt-5 h-14 w-full rounded-xl border-0 bg-mango text-ink hover:bg-[#ef9d27]" type="submit">
            Continue <span aria-hidden="true">→</span>
          </button>
          {#if form?.message}
            <p class="mt-3 text-center text-sm text-red-600" role="alert">{form.message}</p>
          {/if}
        </form>
        <p class="mt-6 text-center text-xs text-slate-400">No password needed. Just groceries.</p>
      </div>
    </section>
  </main>
{:else}
  <main class="min-h-screen bg-cream">
    <header class="border-b border-[#eee4d3] bg-cream">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <a class="flex items-center gap-2 text-lg font-bold" href="/">
          <span class="text-2xl">🥭</span> Mango List
        </a>
        <div class="flex items-center gap-3 text-sm">
          <span class="hidden text-slate-500 sm:inline">Hi, {data.username}</span>
          <form method="POST" action="?/signOut">
            <button class="btn btn-ghost btn-sm rounded-lg" type="submit">Sign out</button>
          </form>
        </div>
      </div>
    </header>
    <div class="mx-auto grid max-w-6xl gap-8 px-6 py-10 lg:grid-cols-[15rem_1fr]">
      <aside>
        <div class="mb-4 flex items-center justify-between">
          <h2 class="text-sm font-bold uppercase tracking-[0.15em] text-slate-500">Your lists</h2>
          <button class="btn btn-circle btn-sm border-0 bg-[#e6f0e2] text-leaf hover:bg-[#d6e8d1]" on:click={() => (showNewList = true)} aria-label="Create a new list">+</button>
        </div>
        <nav class="space-y-1">
          {#each lists as list}
            <button
              class:!bg-white={activeListId === list.id}
              class="flex w-full items-center justify-between rounded-xl px-4 py-3 text-left text-sm font-semibold text-slate-600 transition hover:bg-white"
              on:click={() => (activeListId = list.id)}
            >
              <span class="truncate">{list.name}</span>
              <span class="ml-2 text-xs text-slate-400">{list.items.length}</span>
            </button>
          {/each}
        </nav>
        {#if showNewList}
          <form class="mt-5" method="POST" action="?/createList" use:enhance on:submit={() => (showNewList = false)}>
            <input bind:value={newListName} name="name" class="input input-sm w-full rounded-lg bg-white" placeholder="List name" required />
            <div class="mt-2 flex gap-2">
              <button class="btn btn-sm flex-1 rounded-lg bg-leaf text-white hover:bg-[#416c49]" type="submit">Add</button>
              <button class="btn btn-ghost btn-sm rounded-lg" type="button" on:click={() => (showNewList = false)}>Cancel</button>
            </div>
          </form>
        {/if}
      </aside>
      <section>
        {#if activeList}
          <div class="mb-8 flex flex-wrap items-end justify-between gap-4">
            <div>
              <p class="mb-2 text-sm font-semibold text-leaf">{completedCount} of {activeList.items.length} checked off</p>
              <h1 class="font-display text-5xl">{activeList.name}</h1>
            </div>
            <span class="rounded-full bg-[#f7e6bf] px-4 py-2 text-sm font-semibold text-[#916624]">This week</span>
          </div>
          <form class="mb-5 flex gap-3" method="POST" action="?/addItem" use:enhance>
            <input type="hidden" name="listId" value={activeList.id} />
            <input bind:value={newItem} name="name" class="input h-14 flex-1 rounded-xl border-slate-200 bg-white shadow-sm" placeholder="Add an item..." aria-label="New grocery item" required />
            <button class="btn h-14 rounded-xl border-0 bg-leaf px-6 text-white hover:bg-[#416c49]" type="submit">Add item</button>
          </form>
          <div class="overflow-hidden rounded-2xl bg-white shadow-card">
            {#if activeList.items.length === 0}
              <div class="p-12 text-center text-slate-500">
                <p class="mb-2 text-3xl">🛒</p>
                <p class="font-semibold">Your list is ready for its first item.</p>
              </div>
            {:else}
              {#each activeList.items as item}
                <label class="flex cursor-pointer items-center gap-4 border-b border-slate-100 px-5 py-4 last:border-0 hover:bg-slate-50">
                  <form method="POST" action="?/toggleItem" use:enhance>
                    <input type="hidden" name="itemId" value={item.id} />
                    <input type="hidden" name="completed" value={String(!item.completed)} />
                    <input type="checkbox" class="checkbox checkbox-success" checked={item.completed} on:change={(event) => event.currentTarget.form?.requestSubmit()} />
                  </form>
                  <span class:line-through={item.completed} class:text-slate-400={item.completed}>{item.name}</span>
                </label>
              {/each}
            {/if}
          </div>
        {/if}
      </section>
    </div>
  </main>
{/if}
