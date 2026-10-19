import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices, type Services } from "./services.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner", over: Partial<Services> = {}) {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const routes = buildRoutes(fakeServices(over));
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });
const ann = { action: "announce.save", title: t3("New"), body: t3("Hello"), starts_at: "2026-10-21T00:00:00Z", ends_at: "2026-10-28T00:00:00Z" };

Deno.test("announce: save, list newest first, publish and archive, all audited", async () => {
  const { run, store } = setup("owner");
  const a = await run(ann);
  assertEquals(a.status, 200);
  assertEquals(a.body, { id: 1, warnings: [] });
  await run({ ...ann, title: t3("Second") });
  const list = await run({ action: "announce.list" });
  assertEquals((list.body as any).items.map((x: any) => [x.id, x.status, x.cta]), [[2, "draft", null], [1, "draft", null]]);
  assertEquals((await run({ action: "announce.publish", id: 1 })).status, 200);
  assertEquals([store.announcementRows[0].status, store.announcementRows[0].published_by], ["published", ME.email]);
  assertEquals((await run({ action: "announce.archive", id: 1 })).status, 200);
  assertEquals(store.announcementRows[0].status, "archived");
  assertEquals(store.audit.map((e) => e.action), ["announce_save", "announce_save", "announce_publish", "announce_archive"]);
  assert(store.audit.every((e) => e.section === "messaging"));
  assertEquals((await run({ action: "announce.publish", id: 9 })).status, 404);
});

Deno.test("announce: an end before the start is a field error", async () => {
  const { run, store } = setup("editor");
  const r = await run({ ...ann, ends_at: "2026-10-20T00:00:00Z" });
  assertEquals([r.status, (r.body as any).error], [400, "invalid"]);
  assertEquals((r.body as any).errors, [{ key: "ends_at", message: "End date is before the start date." }]);
  assertEquals(store.announcementRows.length, 0);
});

Deno.test("announce: overlapping a live announcement for the same audience is a warning", async () => {
  const { run } = setup("owner");
  await run({ ...ann, targeting: { platform: "ios" } });
  await run({ action: "announce.publish", id: 1 });
  const r = await run({ ...ann, title: t3("Another") });
  assertEquals((r.body as any).warnings, [{ key: "starts_at", message: "Overlaps 1 live announcement · only the newest shows" }]);
  // A different platform doesn't overlap; re-saving the live one itself doesn't either.
  assertEquals((await run({ ...ann, targeting: { platform: "android" } })).body, { id: 3, warnings: [] });
  assertEquals((await run({ ...ann, id: 1, targeting: { platform: "ios" } })).body, { id: 1, warnings: [] });
});

Deno.test("announce: the voice check flags 'burn off'", async () => {
  const { run } = setup("editor");
  const r = await run({ ...ann, body: { ...t3("Burn off the weekend") } });
  assertEquals((r.body as any).warnings, [{ key: "body.en", message: "“burn off” ties exercise to food. Try “Start the week strong”." }]);
});

Deno.test("announce: an editor saves and archives but can't publish; a viewer only lists", async () => {
  const editor = setup("editor");
  assertEquals((await editor.run(ann)).status, 200);
  assertEquals((await editor.run({ action: "announce.publish", id: 1 })).status, 403);
  const viewer = setup("viewer");
  assertEquals((await viewer.run({ action: "announce.list" })).status, 200);
  assertEquals((await viewer.run(ann)).status, 403);
});

const push = { action: "push.save", title: t3("Week"), body: t3("Start strong"), send_at_local: "2026-10-21T09:00" };

Deno.test("push: a time in quiet hours is moved to 08:00", async () => {
  const { run, store } = setup("editor");
  assertEquals((await run({ ...push, send_at_local: "2026-10-21T23:30" })).body, { id: 1, send_at_local: "2026-10-22T08:00", moved: true });
  assertEquals((await run({ ...push, send_at_local: "2026-10-21T06:00" })).body, { id: 2, send_at_local: "2026-10-21T08:00", moved: true });
  assertEquals((await run(push)).body, { id: 3, send_at_local: "2026-10-21T09:00", moved: false });
  assertEquals(store.campaignRows[0].send_at_local, "2026-10-22T08:00");
  assertEquals((await run({ ...push, send_at_local: "tomorrow" })).status, 400);
});

Deno.test("push.list says whether FCM is configured and how many tokens there are", async () => {
  const { run, store } = setup("viewer");
  store.tokens = 12;
  assertEquals((await run({ action: "push.list" })).body, { items: [], configured: false, tokens: 12 });
  const on = setup("viewer", { fcmConfigured: () => true });
  assertEquals((await on.run({ action: "push.list" })).body, { items: [], configured: true, tokens: 0 });
});

Deno.test("push.schedule without FCM is 503 and the campaign stays a draft", async () => {
  const { run, store } = setup("owner");
  await run(push);
  const r = await run({ action: "push.schedule", id: 1 });
  assertEquals([r.status, (r.body as any).error], [503, "not_configured"]);
  assertEquals(store.campaignRows[0].status, "draft");
});

Deno.test("push.schedule: one campaign per ISO week, with the next free Monday", async () => {
  const { run, store } = setup("owner", { fcmConfigured: () => true });
  await run(push);
  assertEquals((await run({ action: "push.schedule", id: 1 })).status, 200);
  assertEquals(store.campaignRows[0].status, "scheduled");
  await run({ ...push, send_at_local: "2026-10-25T09:00" });
  const r = await run({ action: "push.schedule", id: 2 });
  assertEquals([r.status, (r.body as any).error], [409, "week_taken"]);
  assertEquals((r.body as any).taken_by.id, 1);
  assertEquals((r.body as any).next_free, "2026-10-26");
  assertEquals(store.campaignRows[1].status, "draft");
  // The week after is free.
  await run({ ...push, send_at_local: "2026-10-27T09:00" });
  assertEquals((await run({ action: "push.schedule", id: 3 })).status, 200);
  assertEquals((await run({ action: "push.schedule", id: 3 })).status, 409);
});

Deno.test("push.cancel frees the week; a sent campaign can't be cancelled; editors can't schedule", async () => {
  const { run, store } = setup("owner", { fcmConfigured: () => true });
  await run(push);
  await run({ action: "push.schedule", id: 1 });
  assertEquals((await run({ action: "push.cancel", id: 1 })).status, 200);
  assertEquals(store.campaignRows[0].status, "cancelled");
  await run({ ...push, send_at_local: "2026-10-22T09:00" });
  assertEquals((await run({ action: "push.schedule", id: 2 })).status, 200);
  store.campaignRows[1].status = "sent";
  assertEquals((await run({ action: "push.cancel", id: 2 })).status, 409);
  assertEquals((await run({ ...push, id: 2 })).status, 409);
  const editor = setup("editor", { fcmConfigured: () => true });
  await editor.run(push);
  assertEquals((await editor.run({ action: "push.schedule", id: 1 })).status, 403);
});
