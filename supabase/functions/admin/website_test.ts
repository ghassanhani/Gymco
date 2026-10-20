import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices, type Services } from "./services.ts";
import type { GitHub } from "../_shared/github.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner", over: Partial<Services> = {}) {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const routes = buildRoutes(fakeServices(over));
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });
const body = { title: t3("Support"), markdown: t3("# Help\n\nEmail us."), updated: "2026-10-20" };

Deno.test("website.get: base, live urls and a summary of every page", async () => {
  const { run } = setup("viewer");
  const r = await run({ action: "website.get", page: "support" });
  assertEquals(r.status, 200);
  const b = r.body as any;
  assertEquals(b.base.title, { en: "Support", ar: "", es: "" });
  assertEquals(b.base.markdown, { en: "", ar: "", es: "" });
  assert(/^\d{4}-\d{2}-\d{2}$/.test(b.base.updated));
  assertEquals([b.published, b.draft, b.history], [null, null, []]);
  assertEquals(b.live, { en_url: "https://gymcoapp.com/support/", ar_url: "https://gymcoapp.com/support/ar/", es_url: "https://gymcoapp.com/support/es/" });
  assertEquals(b.summary.map((s: any) => s.page), ["support", "privacy", "terms", "delete-account"]);
  assertEquals(b.summary[0], { page: "support", published_version: null, draft_status: null, updated: null });
  const del = (await run({ action: "website.get", page: "delete-account" })).body as any;
  assertEquals(del.live.es_url, "https://gymcoapp.com/delete-account/es/");
});

Deno.test("website: a bad page is 400 bad_kind on every action", async () => {
  const { run } = setup("owner");
  for (const action of ["website.get", "website.save_draft", "website.submit", "website.discard", "website.publish", "website.rollback"]) {
    for (const page of ["../admin", "home"]) {
      const r = await run({ action, page, body, version: 1, to_version: 1 });
      assertEquals([r.status, (r.body as any).error], [400, "bad_kind"], `${action} ${page}`);
    }
  }
  assertEquals((await run({ action: "website.get", kind: "support" })).status, 400);
});

Deno.test("website: save a draft under its page, publish without a token: committed false", async () => {
  const { run, store } = setup("owner");
  const saved = await run({ action: "website.save_draft", page: "support", body, note: "First" });
  assertEquals(saved.status, 200);
  assertEquals([store.pages[0].page, store.pages[0].version, store.pages[0].status], ["support", 1, "draft"]);
  assert(!("kind" in store.pages[0]));
  const pub = await run({ action: "website.publish", page: "support", version: 1 });
  assertEquals(pub.status, 200);
  assertEquals((pub.body as any).committed, false);
  assertEquals((pub.body as any).version, 1);
  assertEquals(store.pages[0].status, "published");
  assertEquals(store.audit.at(-1)?.section, "website");
  assertEquals(((await run({ action: "website.get", page: "support" })).body as any).summary[0], { page: "support", published_version: 1, draft_status: null, updated: "2026-10-20" });
});

Deno.test("website: publishing with GitHub writes the three pages with the commit message", async () => {
  const puts: { path: string; content: string; message: string }[] = [];
  const gh: GitHub = { latestRuns: () => Promise.resolve([]), rerun: () => Promise.resolve(true), putFile: (path, content, message) => {
    puts.push({ path, content, message });
    return Promise.resolve();
  } };
  const { run } = setup("owner", { github: () => gh });
  await run({ action: "website.save_draft", page: "support", body });
  const pub = await run({ action: "website.publish", page: "support", version: 1 });
  assertEquals((pub.body as any).committed, true);
  assertEquals(puts.map((p) => p.path), ["site/support/index.html", "site/support/ar/index.html", "site/support/es/index.html"]);
  assert(puts.every((p) => p.message === "Website: support v1"));
  assertStringIncludes(puts[1].content, '<html lang="ar" dir="rtl">');
  assertStringIncludes(puts[0].content, "<h1>Help</h1>");
  // Rollback publishes a copy and commits it too.
  await run({ action: "website.save_draft", page: "support", body: { ...body, markdown: t3("# Changed") } });
  await run({ action: "website.publish", page: "support", version: 2 });
  const back = await run({ action: "website.rollback", page: "support", to_version: 1 });
  assertEquals([(back.body as any).version, (back.body as any).committed], [3, true]);
  assertEquals(puts.at(-1)?.message, "Website: support v3");
  // Nothing ever writes the landing page at the root.
  assert(puts.every((p) => p.path.startsWith("site/support/")));
  assertStringIncludes(puts.at(-3)!.content, "<h1>Help</h1>");
});

Deno.test("website: a GitHub failure keeps the version published and says why", async () => {
  const gh: GitHub = { latestRuns: () => Promise.resolve([]), rerun: () => Promise.resolve(true), putFile: () => Promise.reject(new Error("github 401: Bad credentials")) };
  const { run, store } = setup("owner", { github: () => gh });
  await run({ action: "website.save_draft", page: "terms", body });
  const pub = await run({ action: "website.publish", page: "terms", version: 1 });
  assertEquals([(pub.body as any).committed, (pub.body as any).error], [false, "github 401: Bad credentials"]);
  assertEquals(store.pages[0].status, "published");
});

Deno.test("website: every language is needed; an editor saves and submits but can't publish", async () => {
  const { run, store } = setup("editor");
  const bad = await run({ action: "website.save_draft", page: "privacy", body: { ...body, markdown: { en: "x", ar: "", es: "y" }, updated: "soon" } });
  assertEquals((bad.body as any).errors, [{ key: "markdown.ar", message: "Needed in English, Arabic and Spanish" }, { key: "updated", message: "Date as YYYY-MM-DD" }]);
  assertEquals((await run({ action: "website.save_draft", page: "privacy", body })).status, 200);
  assertEquals((await run({ action: "website.submit", page: "privacy" })).status, 200);
  assertEquals(store.pages[0].status, "in_review");
  assertEquals((await run({ action: "website.publish", page: "privacy", version: 1 })).status, 403);
});
