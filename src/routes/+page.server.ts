import { fail, redirect } from '@sveltejs/kit';
import { and, asc, eq, inArray } from 'drizzle-orm';
import { db } from '$lib/server/db';
import { groceryItems, groceryLists, users } from '$lib/server/db/schema';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ cookies }) => {
  const userId = cookies.get('userId');
  if (!userId) return { username: null, lists: [] };

  const [user] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
  if (!user) {
    cookies.delete('userId', { path: '/' });
    return { username: null, lists: [] };
  }

  const lists = await db
    .select()
    .from(groceryLists)
    .where(eq(groceryLists.userId, user.id))
    .orderBy(asc(groceryLists.createdAt));
  const listIds = lists.map((list) => list.id);
  const items = listIds.length
    ? await db
        .select()
        .from(groceryItems)
        .where(inArray(groceryItems.listId, listIds))
        .orderBy(asc(groceryItems.position), asc(groceryItems.createdAt))
    : [];

  return {
    username: user.username,
    lists: lists.map((list) => ({
      id: list.id,
      name: list.name,
      items: items
        .filter((item) => item.listId === list.id)
        .map(({ id, name, completed }) => ({ id, name, completed }))
    }))
  };
};

export const actions: Actions = {
  signIn: async ({ request, cookies }) => {
    const formData = await request.formData();
    const username = String(formData.get('username') ?? '').trim();
    if (!username) return fail(400, { message: 'Username is required.' });

    let [user] = await db.select().from(users).where(eq(users.username, username)).limit(1);
    if (!user) {
      [user] = await db.insert(users).values({ username }).returning();
      await db.insert(groceryLists).values({ userId: user.id, name: 'Weekly groceries' });
    }

    cookies.set('userId', user.id, {
      path: '/',
      httpOnly: true,
      sameSite: 'lax',
      secure: false,
      maxAge: 60 * 60 * 24 * 30
    });

    redirect(303, '/');
  },

  signOut: async ({ cookies }) => {
    cookies.set('userId', '', {
      path: '/',
      httpOnly: true,
      sameSite: 'lax',
      secure: false,
      maxAge: 0,
      expires: new Date(0)
    });
    redirect(303, '/');
  },

  addItem: async ({ request, cookies }) => {
    const userId = cookies.get('userId');
    const formData = await request.formData();
    const listId = String(formData.get('listId') ?? '');
    const name = String(formData.get('name') ?? '').trim();
    if (!userId || !listId || !name) return fail(400, { message: 'List and item name are required.' });

    const [list] = await db
      .select()
      .from(groceryLists)
      .where(and(eq(groceryLists.id, listId), eq(groceryLists.userId, userId)))
      .limit(1);
    if (!list) return fail(404, { message: 'List not found.' });

    await db.insert(groceryItems).values({ listId, name });
  },

  toggleItem: async ({ request, cookies }) => {
    const userId = cookies.get('userId');
    const formData = await request.formData();
    const itemId = String(formData.get('itemId') ?? '');
    const completed = formData.get('completed') === 'true';
    if (!userId || !itemId) return fail(400, { message: 'Item is required.' });

    const ownedItem = await db
      .select({ id: groceryItems.id })
      .from(groceryItems)
      .innerJoin(groceryLists, eq(groceryItems.listId, groceryLists.id))
      .where(and(eq(groceryItems.id, itemId), eq(groceryLists.userId, userId)))
      .limit(1);
    if (!ownedItem.length) return fail(404, { message: 'Item not found.' });

    await db.update(groceryItems).set({ completed }).where(eq(groceryItems.id, itemId));
  },

  createList: async ({ request, cookies }) => {
    const userId = cookies.get('userId');
    const formData = await request.formData();
    const name = String(formData.get('name') ?? '').trim();
    if (!userId || !name) return fail(400, { message: 'List name is required.' });

    await db.insert(groceryLists).values({ userId, name });
  }
};
