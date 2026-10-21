import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices } from "./services.ts";
import { LANDING_DEFAULTS, LANDING_KEYS } from "../_shared/landing.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner") {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const routes = buildRoutes(fakeServices());
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });

Deno.test("landing.get: a viewer reads the defaults, keys and waitlist numbers", async () => {
  const { run, store } = setup("viewer");
  store.waitlist.push(
    { email: "a@b.co", locale: "en", created_at: new Date().toISOString() },
    { email: "c@d.co", locale: "ar", created_at: "2026-01-01T00:00:00Z" },
  );
  const r = await run({ action: "landing.get" });
  assertEquals(r.status, 200);
  const b = r.body as any;
  assertEquals([b.published, b.draft, b.history], [null, null, []]);
  assertEquals(b.base.copy, {});
  assertEquals(b.defaults.prices.pro_month, "€4.99");
  assertEquals(b.defaults.sections.join, true);
  assertEquals(b.defaults.copy["hero.title"], { en: LANDING_DEFAULTS["hero.title"] });
  assertEquals(Object.keys(b.defaults.copy), [...LANDING_KEYS]);
  assertEquals(b.keys, [...LANDING_KEYS]);
  assertEquals(b.waitlist, { count: 2, last_7d: 1 });
});

Deno.test("landing: save, publish and roll back, audited under website", async () => {
  const { run, store } = setup("owner");
  const saved = await run({ action: "landing.save_draft", body: { beta: false, copy: { "hero.title": t3("Eat *well*") } }, note: "Launch" });
  assertEquals(saved.status, 200);
  assertEquals((saved.body as any).diff.map((d: any) => d.key), ["beta", "copy.hero.title"]);
  assertEquals([store.landing[0].version, store.landing[0].status], [1, "draft"]);
  assert(!("kind" in store.landing[0]));
  const pub = await run({ action: "landing.publish", version: 1 });
  assertEquals([pub.status, (pub.body as any).version], [200, 1]);
  await run({ action: "landing.save_draft", body: { beta: true, prices: { pro_month: "€5.99" } } });
  assertEquals((await run({ action: "landing.publish", version: 2 })).status, 200);
  assertEquals(store.landing.map((r) => r.status), ["archived", "published"]);
  const back = await run({ action: "landing.rollback", to_version: 1 });
  assertEquals([back.status, (back.body as any).version], [200, 3]);
  const live = store.landing.find((r) => r.status === "published")!;
  assertEquals([live.version, (live.body as any).beta, (live.body as any).prices.pro_month], [3, false, "€4.99"]);
  assertEquals(store.audit.map((a) => [a.section, a.action]), [
    ["website", "save_draft"], ["website", "publish"], ["website", "save_draft"], ["website", "publish"], ["website", "rollback"],
  ]);
  const got = (await run({ action: "landing.get" })).body as any;
  assertEquals(got.published.version, 3);
  assertEquals(got.history.map((h: any) => h.version), [3, 2, 1]);
});

Deno.test("landing: an unknown copy key is refused with its key", async () => {
  const { run, store } = setup("editor");
  const r = await run({ action: "landing.save_draft", body: { copy: { "hero.subtitle": t3("x") } } });
  assertEquals([r.status, (r.body as any).error], [400, "invalid"]);
  assertEquals((r.body as any).errors.map((e: any) => e.key), ["copy.hero.subtitle"]);
  assertEquals(store.landing.length, 0);
});

Deno.test("landing: copy without Arabic is refused at copy.<key>.ar", async () => {
  const { run } = setup("editor");
  const r = await run({ action: "landing.save_draft", body: { copy: { "join.sub": { en: "Join", ar: "", es: "Únete" } } } });
  assertEquals((r.body as any).errors, [{ key: "copy.join.sub.ar", message: "Needed in English, Arabic and Spanish" }]);
});

Deno.test("landing: a store link off the store's site is refused", async () => {
  const { run } = setup("editor");
  const r = await run({ action: "landing.save_draft", body: { stores: { ios_url: "https://example.com/gymco" } } });
  assertEquals([r.status, (r.body as any).errors.map((e: any) => e.key)], [400, ["stores.ios_url"]]);
});

Deno.test("landing: an editor saves and submits but can't publish", async () => {
  const { run, store } = setup("editor");
  assertEquals((await run({ action: "landing.save_draft", body: { notify: false } })).status, 200);
  assertEquals((await run({ action: "landing.submit" })).status, 200);
  assertEquals(store.landing[0].status, "in_review");
  assertEquals((await run({ action: "landing.publish", version: 1 })).status, 403);
  assertEquals((await run({ action: "landing.rollback", to_version: 1 })).status, 403);
  assertEquals((await run({ action: "landing.discard" })).status, 200);
  assertEquals(store.landing[0].status, "archived");
});

Deno.test("waitlist.export: owner only, as CSV, and audited", async () => {
  for (const role of ["viewer", "support", "editor"] as const) {
    assertEquals((await setup(role).run({ action: "waitlist.export" })).status, 403, role);
  }
  const { run, store } = setup("owner");
  store.waitlist.push(
    { email: "a@b.co", locale: "en", created_at: "2026-10-20T10:00:00Z" },
    { email: "x,\"y\"@b.co", locale: "es", created_at: "2026-10-19T10:00:00Z" },
  );
  const r = await run({ action: "waitlist.export" });
  assertEquals(r.status, 200);
  assertEquals((r.body as any).csv, 'email,locale,created_at\na@b.co,en,2026-10-20T10:00:00Z\n"x,""y""@b.co",es,2026-10-19T10:00:00Z');
  const a = store.audit.at(-1)!;
  assertEquals([a.section, a.action, a.after], ["website", "waitlist_export", { rows: 2 }]);
});

const b64 = (bytes: number[]) => {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
};
const JPEG = [0xff, 0xd8, 0xff, 0xe0, 1, 2, 3];

Deno.test("landing.upload_screen: an editor's picture lands under its hash and is audited", async () => {
  const { run, store } = setup("editor");
  const r = await run({ action: "landing.upload_screen", slot: "today", type: "image/jpeg", data: b64(JPEG) });
  assertEquals(r.status, 200);
  const url = (r.body as any).url as string;
  assert(/\/storage\/v1\/object\/public\/site\/landing\/[0-9a-f]{64}\.jpg$/.test(url), url);
  const [path] = [...store.siteFiles.keys()];
  assertEquals([store.siteFiles.get(path)!.contentType, store.siteFiles.get(path)!.bytes.length], ["image/jpeg", JPEG.length]);
  const a = store.audit.at(-1)!;
  assertEquals([a.section, a.action, (a.after as any).slot], ["website", "landing_upload_screen", "today"]);
  // The same picture again gives the same address.
  const again = await run({ action: "landing.upload_screen", slot: "r1", type: "image/jpeg", data: b64(JPEG) });
  assertEquals((again.body as any).url, url);
  // And a draft can name it.
  assertEquals((await run({ action: "landing.save_draft", body: { screens: { today: url } } })).status, 200);
});

Deno.test("landing.upload_screen: refuses viewers, unknown phones, other files and big ones", async () => {
  assertEquals((await setup("viewer").run({ action: "landing.upload_screen", slot: "today", type: "image/jpeg", data: b64(JPEG) })).status, 403);
  const { run, store } = setup("editor");
  const cases: Record<string, unknown>[] = [
    { slot: "side", type: "image/jpeg", data: b64(JPEG) },
    { slot: "l1", type: "image/gif", data: b64(JPEG) },
    { slot: "l1", type: "image/png", data: b64(JPEG) },
    { slot: "l1", type: "image/jpeg", data: "%%%" },
    { slot: "l1", type: "image/jpeg", data: "" },
    { slot: "l1", type: "image/jpeg", data: b64([...JPEG, ...new Array(2_000_001).fill(0)].slice(0, 2_000_001)) },
  ];
  for (const c of cases) {
    const r = await run({ action: "landing.upload_screen", ...c });
    assertEquals([r.status, (r.body as any).error], [400, "invalid"], JSON.stringify(c).slice(0, 60));
  }
  assertEquals(store.siteFiles.size, 0);
});
