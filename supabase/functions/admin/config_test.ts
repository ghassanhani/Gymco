import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner") {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME) });
  return { store, run };
}

Deno.test("anyone can read the config with its schema and defaults", async () => {
  const { run } = setup("viewer");
  const r = await run({ action: "config.get" });
  assertEquals(r.status, 200);
  const b = r.body as { defaults: { limits: { ai_scans_per_day: number } }; published: unknown; schema: unknown };
  assertEquals(b.defaults.limits.ai_scans_per_day, 10);
  assertEquals(b.published, null);
  assert(b.schema);
});

Deno.test("an editor drafts a change, which becomes the next version", async () => {
  const { run, store } = setup("editor");
  const r = await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 12 } }, note: "More scans" });
  assertEquals(r.status, 200);
  assertEquals(store.configs.length, 1);
  assertEquals([store.configs[0].version, store.configs[0].status], [1, "draft"]);
  assertEquals(store.audit.at(-1)?.action, "save_draft");
});

Deno.test("saving again updates the same draft instead of piling up versions", async () => {
  const { run, store } = setup("editor");
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 12 } } });
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 13 } } });
  assertEquals(store.configs.length, 1);
  assertEquals((store.configs[0].body as any).limits.ai_scans_per_day, 13);
});

Deno.test("out-of-bounds values come back as field errors", async () => {
  const { run } = setup("owner");
  const r = await run({ action: "config.save_draft", body: { safety: { calorie_floor: 900 } } });
  assertEquals(r.status, 400);
  assertEquals((r.body as any).errors[0].key, "safety.calorie_floor");
});

Deno.test("an editor can't touch the owner's keys, even in a draft", async () => {
  const { run } = setup("editor");
  const r = await run({ action: "config.save_draft", body: { ai: { daily_budget_eur: 50 } } });
  assertEquals([r.status, (r.body as any).error], [403, "owner_keys"]);
  assertEquals((r.body as any).keys, ["ai.daily_budget_eur"]);
});

Deno.test("an editor submits for review but can't publish", async () => {
  const { run, store } = setup("editor");
  await run({ action: "config.save_draft", body: { features: { dictate: false } } });
  assertEquals((await run({ action: "config.submit" })).status, 200);
  assertEquals(store.configs[0].status, "in_review");
  assertEquals((await run({ action: "config.publish", version: 1 })).status, 403);
});

Deno.test("the owner publishes with a diff, and the old version is archived", async () => {
  const { run, store } = setup("owner");
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 12 } } });
  await run({ action: "config.publish", version: 1 });
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 15 } } });
  const r = await run({ action: "config.publish", version: 2 });
  assertEquals(r.status, 200);
  assertEquals((r.body as any).diff, [{ key: "limits.ai_scans_per_day", before: 12, after: 15 }]);
  assertEquals(store.configs.map((c) => c.status), ["archived", "published"]);
  const audit = store.audit.at(-1)!;
  assertEquals([audit.action, (audit.before as any).limits.ai_scans_per_day, (audit.after as any).limits.ai_scans_per_day], ["publish", 12, 15]);
});

Deno.test("rolling back publishes a copy of the earlier version as a new one", async () => {
  const { run, store } = setup("owner");
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 12 } } });
  await run({ action: "config.publish", version: 1 });
  await run({ action: "config.save_draft", body: { limits: { ai_scans_per_day: 15 } } });
  await run({ action: "config.publish", version: 2 });
  const r = await run({ action: "config.rollback", to_version: 1 });
  assertEquals(r.status, 200);
  const live = store.configs.find((c) => c.status === "published")!;
  assertEquals([live.version, (live.body as any).limits.ai_scans_per_day], [3, 12]);
  assertEquals(store.audit.at(-1)?.action, "rollback");
});

Deno.test("publishing a version that isn't a draft fails", async () => {
  const { run } = setup("owner");
  assertEquals((await run({ action: "config.publish", version: 9 })).status, 404);
});

Deno.test("history lists versions newest first, without their bodies", async () => {
  const { run } = setup("owner");
  await run({ action: "config.save_draft", body: {} });
  await run({ action: "config.publish", version: 1 });
  await run({ action: "config.save_draft", body: { features: { dictate: false } } });
  const r = await run({ action: "config.get" });
  const h = (r.body as any).history;
  assertEquals(h.map((x: any) => [x.version, x.status]), [[2, "draft"], [1, "published"]]);
  assert(!("body" in h[0]));
});
