import { assertEquals } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices, type Services } from "./services.ts";
import { versionShares } from "./releases.ts";
import type { GitHub, Run } from "../_shared/github.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner", over: Partial<Services> = {}) {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  const routes = buildRoutes(fakeServices(over));
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

const RUN: Run = { id: 11, name: "CI", sha7: "abcdef1", status: "passed", when: "2026-10-20T10:00:00Z", url: "https://github.com/x/1" };
const fakeGitHub = (reruns: number[] = []): GitHub => ({
  latestRuns: () => Promise.resolve([RUN]),
  rerun: (id) => {
    reruns.push(id);
    return Promise.resolve(id === 11);
  },
  putFile: () => Promise.resolve(),
});

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });

Deno.test("releases.get without GITHUB_TOKEN: github false, runs empty, the gate from defaults", async () => {
  const { run } = setup("viewer");
  const r = await run({ action: "releases.get" });
  assertEquals(r.status, 200);
  assertEquals(r.body, {
    runs: [], versions: [], gate: { min_build_ios: 0, min_build_android: 0, recommended_build: 0 }, notes: [], github: false, mirror: "iFynx/Gymco",
  });
});

Deno.test("releases.get with GitHub: runs, the published gate, the version mix and notes", async () => {
  const { run, store } = setup("viewer", { github: fakeGitHub });
  store.stats = () => Promise.resolve({ mix: { app_version: { "1.2.0 (104)": 3, "1.1.0 (100)": 1, unknown: 0 } } });
  store.configs.push({ version: 1, status: "published", body: { app_gate: { min_build_ios: 90, min_build_android: 95, recommended_build: 104 } }, created_by: "x" });
  store.releaseNoteRows.push({ build: 104, version: "1.2.0", body: t3("Faster"), published: true, created_by: "x" });
  const b = (await run({ action: "releases.get" })).body as any;
  assertEquals(b.github, true);
  assertEquals(b.runs, [RUN]);
  assertEquals(b.gate, { min_build_ios: 90, min_build_android: 95, recommended_build: 104 });
  assertEquals(b.versions, [{ build: 104, pct: 75 }, { build: 100, pct: 25 }, { build: "unknown", pct: 0 }]);
  assertEquals(b.notes, [{ build: 104, version: "1.2.0", body: t3("Faster"), published: true }]);
});

Deno.test("version shares group by build number", () => {
  assertEquals(versionShares({ "1.2.0 (104)": 1, "1.2.1 (104)": 1, "1.0.0 (90)": 2 }), [{ build: 104, pct: 50 }, { build: 90, pct: 50 }]);
  assertEquals(versionShares(undefined), []);
});

Deno.test("releases.rerun needs GitHub and the publish capability", async () => {
  const off = setup("owner");
  assertEquals([(await off.run({ action: "releases.rerun", run_id: 11 })).status, ((await off.run({ action: "releases.rerun", run_id: 11 })).body as any).error], [503, "not_configured"]);
  const reruns: number[] = [];
  const on = setup("owner", { github: () => fakeGitHub(reruns) });
  assertEquals((await on.run({ action: "releases.rerun", run_id: 11 })).status, 200);
  assertEquals(reruns, [11]);
  assertEquals((await on.run({ action: "releases.rerun", run_id: 12 })).status, 502);
  assertEquals(on.store.audit.at(-1)?.section, "releases");
  const editor = setup("editor", { github: () => fakeGitHub() });
  assertEquals((await editor.run({ action: "releases.rerun", run_id: 11 })).status, 403);
});

Deno.test("release notes: an editor saves, only an owner publishes", async () => {
  const editor = setup("editor");
  const save = { action: "releases.notes_save", build: 105, version: "1.3.0", body: t3("New food search\nFaster sync") };
  assertEquals((await editor.run(save)).body, { build: 105 });
  assertEquals([editor.store.releaseNoteRows[0].published, editor.store.releaseNoteRows[0].version], [false, "1.3.0"]);
  assertEquals((await editor.run({ action: "releases.notes_publish", build: 105 })).status, 403);
  const bad = await editor.run({ ...save, build: 0, body: { en: "x", ar: "", es: "y" } });
  assertEquals((bad.body as any).errors.map((e: any) => e.key), ["build", "body.ar"]);
  const owner = setup("owner");
  assertEquals((await owner.run({ action: "releases.notes_publish", build: 105 })).status, 404);
  await owner.run(save);
  assertEquals((await owner.run({ action: "releases.notes_publish", build: 105 })).status, 200);
  assertEquals(owner.store.releaseNoteRows[0].published, true);
  // Re-saving corrects the text and keeps it published.
  await owner.run({ ...save, body: t3("Fixed") });
  assertEquals([owner.store.releaseNoteRows[0].published, (owner.store.releaseNoteRows[0].body as any).en], [true, "Fixed"]);
});

Deno.test("release notes: a build that isn't a whole number is a field error, not a crash", async () => {
  const { run } = setup("owner");
  for (const build of ["abc", 1.5, null, true, "105"]) {
    const p = await run({ action: "releases.notes_publish", build });
    assertEquals([p.status, (p.body as any).error, (p.body as any).errors], [400, "invalid", [{ key: "build", message: "Enter the build number" }]], String(build));
  }
  const s = await run({ action: "releases.notes_save", build: true, version: "1.3.0", body: t3("x") });
  assertEquals([s.status, (s.body as any).errors.map((e: any) => e.key)], [400, ["build"]]);
});
