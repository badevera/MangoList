<script lang="ts">
  type GroceryList = {
    id: number;
    name: string;
    items: string[];
  };

  const starterLists: GroceryList[] = [
    { id: 1, name: 'Weekly groceries', items: ['Avocados', 'Sourdough bread', 'Oat milk'] },
    { id: 2, name: 'Weekend BBQ', items: ['Corn on the cob', 'Veggie burgers'] }
  ];

  let username = '';
  let signedInAs = '';
  let lists = starterLists;
  let activeListId = 1;
  let newItem = '';
  let newListName = '';
  let showNewList = false;

  $: activeList = lists.find((list) => list.id === activeListId) ?? lists[0];
  $: completedCount = activeList?.items.filter((item) => item.startsWith('✓ ')).length ?? 0;

  function signIn() {
    const trimmedUsername = username.trim();
    if (trimmedUsername) signedInAs = trimmedUsername;
  }

  function addItem() {
    const item = newItem.trim();
    if (!item || !activeList) return;
    lists = lists.map((list) =>
      list.id === activeList.id ? { ...list, items: [...list.items, item] } : list
    );
    newItem = '';
  }

  function toggleItem(itemIndex: number) {
    lists = lists.map((list) => {
      if (list.id !== activeList.id) return list;
      const items = [...list.items];
      items[itemIndex] = items[itemIndex].startsWith('✓ ')
        ? items[itemIndex].slice(2)
        : `✓ ${items[itemIndex]}`;
      return { ...list, items };
    });
  }

  function createList() {
    const name = newListName.trim();
    if (!name) return;
    const id = Math.max(...lists.map((list) => list.id), 0) + 1;
    lists = [...lists, { id, name, items: [] }];
    activeListId = id;
    newListName = '';
    showNewList = false;
  }
</script>

<svelte:head>
  <title>Mango List — groceries made simple</title>
  <meta
    name="description"
    content="A simple, friendly grocery list maker for everything you need."
  />
</svelte:head>

{#if !signedInAs}
  <main class="flex min-h-screen items-center justify-center bg-cream px-6 py-12">
    <section class="grid w-full max-w-5xl overflow-hidden rounded-[2rem] bg-white shadow-card md:grid-cols-2">
      <div class="flex min-h-[32rem] flex-col justify-between bg-leaf p-8 text-white md:p-12">
        <div class="flex items-center gap-2 text-lg font-bold">
          <span class="text-2xl">🥭</span>
          <span>Mango List</span>
        </div>
        <div>
          <p class="mb-4 text-sm font-bold uppercase tracking-[0.2em] text-[#d9ecd5]">Less fuss. More fresh.</p>
          <h1 class="font-display text-5xl leading-tight md:text-6xl">Everything you need, all in one place.</h1>
          <p class="mt-6 max-w-sm text-lg leading-8 text-[#e2f0df]">
            Keep your grocery trips organized and your brain focused on what matters.
          </p>
        </div>
        <p class="text-sm text-[#d9ecd5]">Simple lists for everyday life.</p>
      </div>
      <div class="flex min-h-[32rem] flex-col justify-center p-8 md:p-12">
        <div class="mb-10">
          <p class="mb-3 text-sm font-bold uppercase tracking-[0.18em] text-leaf">Welcome back</p>
          <h2 class="font-display text-4xl">Let's make a list.</h2>
          <p class="mt-3 text-slate-500">Sign in with a username to get started.</p>
        </div>
        <form on:submit|preventDefault={signIn}>
          <label class="mb-2 block text-sm font-semibold" for="username">Your username</label>
          <input
            id="username"
            bind:value={username}
            class="input input-bordered h-14 w-full rounded-xl border-slate-200 bg-slate-50"
            placeholder="e.g. alex"
            autocomplete="username"
            required
          />
          <button class="btn mt-5 h-14 w-full rounded-xl border-0 bg-mango text-ink hover:bg-[#ef9d27]" type="submit">
            Continue <span aria-hidden="true">→</span>
          </button>
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
          <span class="hidden text-slate-500 sm:inline">Hi, {signedInAs}</span>
          <button class="btn btn-ghost btn-sm rounded-lg" on:click={() => (signedInAs = '')}>Sign out</button>
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
          <form class="mt-5" on:submit|preventDefault={createList}>
            <input bind:value={newListName} class="input input-sm w-full rounded-lg bg-white" placeholder="List name" />
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
          <form class="mb-5 flex gap-3" on:submit|preventDefault={addItem}>
            <input bind:value={newItem} class="input h-14 flex-1 rounded-xl border-slate-200 bg-white shadow-sm" placeholder="Add an item..." aria-label="New grocery item" />
            <button class="btn h-14 rounded-xl border-0 bg-leaf px-6 text-white hover:bg-[#416c49]" type="submit">Add item</button>
          </form>
          <div class="overflow-hidden rounded-2xl bg-white shadow-card">
            {#if activeList.items.length === 0}
              <div class="p-12 text-center text-slate-500">
                <p class="mb-2 text-3xl">🛒</p>
                <p class="font-semibold">Your list is ready for its first item.</p>
              </div>
            {:else}
              {#each activeList.items as item, index}
                <label class="flex cursor-pointer items-center gap-4 border-b border-slate-100 px-5 py-4 last:border-0 hover:bg-slate-50">
                  <input type="checkbox" class="checkbox checkbox-success" checked={item.startsWith('✓ ')} on:change={() => toggleItem(index)} />
                  <span class:line-through={item.startsWith('✓ ')} class:text-slate-400={item.startsWith('✓ ')}>{item.replace(/^✓ /, '')}</span>
                </label>
              {/each}
            {/if}
          </div>
        {/if}
      </section>
    </div>
  </main>
{/if}
