import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { canonicalJson, PACK_KINDS } from "../_shared/packs.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner") {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME) });
  return { store, run };
}

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });
const foods = { items: [{ id: "labneh", name: t3("Labneh"), kcal: 160, protein: 6, carbs: 4, fat: 14 }] };
const sha256 = async (s: string) =>
  [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))].map((b) => b.toString(16).padStart(2, "0")).join("");

Deno.test("packs: save, read and publish a foods pack with its checksum", async () => {
  const { run, store } = setup("owner");
  assertEquals((await run({ action: "packs.save_draft", kind: "foods", body: foods, note: "Labneh" })).status, 200);
  assertEquals([store.packs[0].kind, store.packs[0].version, store.packs[0].status], ["foods", 1, "draft"]);
  assertEquals(store.packs[0].checksum, await sha256(canonicalJson(foods)));
  const got = await run({ action: "packs.get", kind: "foods" });
  assertEquals(got.status, 200);
  assertEquals((got.body as any).draft.body, foods);
  assertEquals((got.body as any).base, { items: [] });
  const pub = await run({ action: "packs.publish", kind: "foods", version: 1 });
  assertEquals(pub.status, 200);
  assertEquals(store.packs[0].status, "published");
  assertEquals(store.audit.at(-1)?.section, "content");
});

Deno.test("packs: invalid bodies are refused with field errors", async () => {
  const { run, store } = setup("editor");
  const r = await run({ action: "packs.save_draft", kind: "foods", body: { items: [{ ...foods.items[0], kcal: 2000 }] } });
  assertEquals([r.status, (r.body as any).error], [400, "invalid"]);
  assertEquals((r.body as any).errors[0].key, "items.0.kcal");
  assertEquals(store.packs.length, 0);
});

Deno.test("packs: removing an exercise a built-in template uses can't be saved", async () => {
  const { run } = setup("owner");
  const r = await run({ action: "packs.save_draft", kind: "exercises", body: { items: [], removed: ["Barbell_Hip_Thrust"] } });
  assertEquals(r.status, 400);
  assertEquals((r.body as any).errors, [{ key: "removed.0", message: "Removes “Barbell_Hip_Thrust”, used in 2 templates" }]);
});

Deno.test("packs: removing an exercise the published templates pack uses is blocked", async () => {
  const { run, store } = setup("owner");
  const templates = { items: [{ id: "core", name: t3("Core starter"), level: "beginner", routines: [{ name: t3("Day A"), weekday: 0, items: [{ exercise: "Cable_Crunch", sets: 3, rep_low: 8, rep_high: 12, rest_s: 60 }] }] }] };
  await run({ action: "packs.save_draft", kind: "templates", body: templates });
  await run({ action: "packs.publish", kind: "templates", version: 1 });
  const r = await run({ action: "packs.save_draft", kind: "exercises", body: { items: [], removed: ["Cable_Crunch"] } });
  assertEquals((r.body as any).errors, [{ key: "removed.0", message: "Removes “Cable_Crunch”, used in 1 template" }]);
  // A draft saved before the template was published still can't go out.
  store.packs.push({ kind: "exercises", version: 1, status: "draft", body: { items: [], removed: ["Cable_Crunch"] }, checksum: "x", created_by: ME.email });
  const p = await run({ action: "packs.publish", kind: "exercises", version: 1 });
  assertEquals([p.status, (p.body as any).error], [400, "invalid"]);
});

Deno.test("packs: a template using an exercise the published pack removes is blocked", async () => {
  const { run } = setup("owner");
  await run({ action: "packs.save_draft", kind: "exercises", body: { items: [], removed: ["Sit_Up"] } });
  await run({ action: "packs.publish", kind: "exercises", version: 1 });
  const templates = { items: [{ id: "core", name: t3("Core"), level: "beginner", routines: [{ name: t3("A"), weekday: 0, items: [{ exercise: "Sit_Up", sets: 3, rep_low: 8, rep_high: 12, rest_s: 60 }] }] }] };
  const r = await run({ action: "packs.check", kind: "templates", body: templates });
  assertEquals((r.body as any).errors[0].key, "items.0.routines.0.items.0.exercise");
});

Deno.test("packs.get returns the draft's warnings and a summary of every kind", async () => {
  const { run } = setup("owner");
  await run({ action: "packs.save_draft", kind: "eating_out", body: { dishes: [] } });
  await run({ action: "packs.publish", kind: "eating_out", version: 1 });
  const odd = { items: [{ id: "labneh", name: t3("Labneh"), kcal: 160, protein: 10, carbs: 10, fat: 14.67 }, { id: "b", name: t3("B"), kcal: 0, protein: 0, carbs: 0, fat: 0 }] };
  await run({ action: "packs.save_draft", kind: "foods", body: odd });
  const r = await run({ action: "packs.get", kind: "foods" });
  const b = r.body as any;
  assertEquals(b.warnings, [{ key: "items.0.kcal", message: "Labneh: macros add up to 212 kcal, but kcal says 160 per 100 g. Check the numbers." }]);
  assertEquals(b.summary.map((s: any) => s.kind), [...PACK_KINDS]);
  assertEquals(b.summary[0], { kind: "foods", published_version: null, draft_status: "draft", items: 2 });
  assertEquals(b.summary[2], { kind: "eating_out", published_version: 1, draft_status: null, items: 0 });
});

Deno.test("packs.check validates without saving", async () => {
  const { run, store } = setup("editor");
  const r = await run({ action: "packs.check", kind: "copy", body: { overrides: { nope: t3("x") } } });
  assertEquals(r.status, 200);
  assertEquals(r.body, { ok: false, errors: [{ key: "overrides.nope", message: "Unknown text key" }], warnings: [] });
  assertEquals((await run({ action: "packs.check", kind: "foods", body: foods })).body, { ok: true, errors: [], warnings: [] });
  assertEquals(store.packs.length, 0);
});

Deno.test("packs: an unknown kind is a 400", async () => {
  const { run } = setup("owner");
  for (const action of ["packs.get", "packs.save_draft", "packs.check", "packs.publish", "packs.submit", "packs.discard", "packs.rollback"]) {
    const r = await run({ action, kind: "recipes", body: {}, version: 1 });
    assertEquals([r.status, (r.body as any).error], [400, "bad_kind"], action);
  }
});

Deno.test("packs: an editor can save and submit but not publish", async () => {
  const { run, store } = setup("editor");
  assertEquals((await run({ action: "packs.save_draft", kind: "foods", body: foods })).status, 200);
  assertEquals((await run({ action: "packs.submit", kind: "foods" })).status, 200);
  assertEquals(store.packs[0].status, "in_review");
  const r = await run({ action: "packs.publish", kind: "foods", version: 1 });
  assertEquals([r.status, (r.body as any).error], [403, "forbidden"]);
});

Deno.test("packs: a viewer reads but can't check or save", async () => {
  const { run } = setup("viewer");
  assertEquals((await run({ action: "packs.get", kind: "foods" })).status, 200);
  assertEquals((await run({ action: "packs.check", kind: "foods", body: foods })).status, 403);
  assertEquals((await run({ action: "packs.save_draft", kind: "foods", body: foods })).status, 403);
});

Deno.test("plans.grants lists the plans granted by hand", async () => {
  const { run, store } = setup("support");
  store.users.set("u-1", { id: "u-1", email: "user@example.com" });
  store.users.set("u-2", { id: "u-2", email: "store@example.com" });
  await store.setEntitlement("u-1", "pro", "2027-01-01T00:00:00Z", "owner@gymco.test");
  store.entitlements.set("u-2", { plan: "pro", source: "store", expires_at: null, granted_by: null, at: "2026-10-01T00:00:00Z" });
  const r = await run({ action: "plans.grants" });
  assertEquals(r.status, 200);
  const grants = (r.body as any).grants;
  assertEquals(grants.length, 1);
  const { granted_at, ...rest } = grants[0];
  assert(typeof granted_at === "string");
  assertEquals(rest, { user_id: "u-1", email: "user@example.com", plan: "pro", expires_at: "2027-01-01T00:00:00Z", granted_by: "owner@gymco.test" });
});

Deno.test("plans.grants is not for viewers", async () => {
  const { run } = setup("viewer");
  const r = await run({ action: "plans.grants" });
  assertEquals([r.status, (r.body as any).error], [403, "forbidden"]);
});

Deno.test("packs: a rollback that no longer validates changes nothing", async () => {
  const { run, store } = setup("owner");
  const tpl = (exercise: string) => ({ items: [{ id: "core", name: t3("Core"), level: "beginner", routines: [{ name: t3("A"), weekday: 0, items: [{ exercise, sets: 3, rep_low: 8, rep_high: 12, rest_s: 60 }] }] }] });
  await run({ action: "packs.save_draft", kind: "templates", body: tpl("Sit_Up") });
  await run({ action: "packs.publish", kind: "templates", version: 1 });
  await run({ action: "packs.save_draft", kind: "templates", body: tpl("Cable_Crunch") });
  await run({ action: "packs.publish", kind: "templates", version: 2 });
  await run({ action: "packs.save_draft", kind: "exercises", body: { items: [], removed: ["Sit_Up"] } });
  await run({ action: "packs.publish", kind: "exercises", version: 1 });
  await run({ action: "packs.save_draft", kind: "templates", body: tpl("Cable_Crunch"), note: "Work in progress" });
  const before = structuredClone(store.packs);
  const r = await run({ action: "packs.rollback", kind: "templates", to_version: 1 });
  assertEquals([r.status, (r.body as any).error], [400, "invalid"]);
  assertEquals((r.body as any).errors[0].key, "items.0.routines.0.items.0.exercise");
  assertEquals(store.packs, before);
  assertEquals(store.packs.find((p) => p.kind === "templates" && p.version === 3)?.status, "draft");
});
