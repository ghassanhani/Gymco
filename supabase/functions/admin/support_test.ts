import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices, type Services } from "./services.ts";
import { TEMPLATES } from "../_shared/support_templates.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner", over: Partial<Services> = {}) {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  store.users.set("u-1", { id: "u-1", email: "ana@example.com" });
  const routes = buildRoutes(fakeServices(over));
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

const add = { action: "tickets.add", email: "ana@example.com", subject: "Restore", body: "Lost my diary after a new phone." };

Deno.test("tickets: a viewer is forbidden from every tickets.* action", async () => {
  const { run } = setup("viewer");
  for (const action of ["tickets.list", "tickets.get", "tickets.add", "tickets.reply", "tickets.set_status", "tickets.tag", "tickets.templates"]) {
    const r = await run({ action, tab: "new", id: 1 });
    assertEquals([r.status, (r.body as any).error], [403, "forbidden"], action);
  }
});

Deno.test("tickets.add stores an admin ticket; a deletion one gets a 30-day deadline", async () => {
  const { run, store } = setup("support");
  assertEquals((await run(add)).body, { id: 1 });
  assertEquals([store.ticketRows[0].source, store.ticketRows[0].status, store.ticketRows[0].deadline_at], ["admin", "new", null]);
  assertEquals((await run({ ...add, kind: "deletion" })).body, { id: 2 });
  assertEquals(store.ticketRows[1].deadline_at, "2026-11-19T12:00:00.000Z");
  const bad = await run({ ...add, email: "nope" });
  assertEquals([bad.status, (bad.body as any).error], [400, "invalid"]);
  assertEquals((bad.body as any).errors[0].key, "email");
  assertEquals(store.audit.at(-1)?.section, "support");
});

Deno.test("tickets.list never includes the body and says who has an account", async () => {
  const { run } = setup("support");
  await run(add);
  await run({ ...add, email: "nobody@example.com", subject: "Other" });
  const r = await run({ action: "tickets.list", tab: "new" });
  assertEquals(r.status, 200);
  const items = (r.body as any).items;
  assertEquals(items.length, 2);
  for (const t of items) assert(!("body" in t), "body leaked");
  assertEquals(items.map((t: any) => [t.email, t.has_account]), [["nobody@example.com", false], ["ana@example.com", true]]);
  assertEquals((r.body as any).counts, { new: 2, waiting: 0, solved: 0, deletion_open: 0, overdue: 0 });
  assertEquals((await run({ action: "tickets.list", tab: "new", q: "other" })).body, { ...(r.body as any), items: [items[0]] });
  assertEquals((await run({ action: "tickets.list", tab: "spam" })).status, 400);
});

Deno.test("the deletion tab lists every status, overdue first, and days_left goes negative", async () => {
  const { run, store } = setup("support");
  await run({ ...add, kind: "deletion" });
  await run({ ...add, kind: "deletion", subject: "Old" });
  store.ticketRows[1].deadline_at = "2026-10-18T12:00:00Z";
  store.ticketRows[1].status = "waiting";
  const r = await run({ action: "tickets.list", tab: "deletion" });
  assertEquals((r.body as any).items.map((t: any) => t.id), [2, 1]);
  assertEquals((r.body as any).counts, { new: 1, waiting: 1, solved: 0, deletion_open: 2, overdue: 1 });
  assertEquals(((await run({ action: "tickets.get", id: 2 })).body as any).days_left, -2);
  const fresh = (await run({ action: "tickets.get", id: 1 })).body as any;
  assertEquals(fresh.days_left, 30);
  assertEquals(fresh.ticket.body, "Lost my diary after a new phone.");
  assertEquals(fresh.ticket.has_account, true);
  assertEquals(fresh.messages, []);
  assertEquals((await run({ action: "tickets.get", id: 99 })).status, 404);
});

Deno.test("tickets.reply without RESEND stores the message and hands back a mailto", async () => {
  const { run, store } = setup("support");
  await run(add);
  const r = await run({ action: "tickets.reply", id: 1, body: "Hi Ana,\nSign in on the new phone." });
  assertEquals(r.body, { sent: false, mailto: "mailto:ana@example.com?subject=Re%3A%20Restore&body=Hi%20Ana%2C%0ASign%20in%20on%20the%20new%20phone." });
  assertEquals(store.messages.length, 1);
  assertEquals([store.messages[0].from_admin, store.messages[0].author], [true, ME.email]);
  assertEquals(store.ticketRows[0].status, "waiting");
  const got = (await run({ action: "tickets.get", id: 1 })).body as any;
  assertEquals(got.messages.length, 1);
  assertEquals(got.messages[0].body, "Hi Ana,\nSign in on the new phone.");
});

Deno.test("tickets.reply with RESEND emails the user with Re: subject and can solve the ticket", async () => {
  const sent: { to: string; subject: string; text: string }[] = [];
  const { run, store } = setup("support", {
    email: () => (m) => {
      sent.push(m);
      return Promise.resolve();
    },
  });
  await run(add);
  assertEquals((await run({ action: "tickets.reply", id: 1, body: "Done.", status: "solved" })).body, { sent: true });
  assertEquals(sent, [{ to: "ana@example.com", subject: "Re: Restore", text: "Done." }]);
  assertEquals(store.ticketRows[0].status, "solved");
  assertEquals((await run({ action: "tickets.reply", id: 1, body: "", status: "solved" })).status, 400);
  assertEquals((await run({ action: "tickets.reply", id: 1, body: "x", status: "new" })).status, 400);
});

Deno.test("a failed send still stores the message and falls back to mailto", async () => {
  const { run, store } = setup("support", { email: () => () => Promise.reject(new Error("resend 500: down")) });
  await run(add);
  const r = (await run({ action: "tickets.reply", id: 1, body: "Hi" })).body as any;
  assertEquals([r.sent, r.error], [false, "resend 500: down"]);
  assert(String(r.mailto).startsWith("mailto:ana@example.com"));
  assertEquals(store.messages.length, 1);
});

Deno.test("status and tags are checked; templates come from the shared constant", async () => {
  const { run, store } = setup("support");
  await run(add);
  assertEquals((await run({ action: "tickets.set_status", id: 1, status: "solved" })).status, 200);
  assertEquals(store.ticketRows[0].status, "solved");
  assertEquals((await run({ action: "tickets.set_status", id: 1, status: "closed" })).status, 400);
  assertEquals((await run({ action: "tickets.tag", id: 1, tags: ["bug", " billing "] })).status, 200);
  assertEquals(store.ticketRows[0].tags, ["bug", "billing"]);
  assertEquals((await run({ action: "tickets.tag", id: 1, tags: ["a", "b", "c", "d", "e", "f"] })).status, 400);
  assertEquals((await run({ action: "tickets.tag", id: 1, tags: ["x".repeat(21)] })).status, 400);
  assertEquals((await run({ action: "tickets.tag", id: 1, tags: "bug" })).status, 400);
  assertEquals((await run({ action: "tickets.templates" })).body, { templates: TEMPLATES });
});
