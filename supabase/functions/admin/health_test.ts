import { assertEquals } from "jsr:@std/assert@1.0.13";
import { buildRoutes, handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";
import { fakeServices, type Services } from "./services.ts";
import type { GitHub } from "../_shared/github.ts";

const ME = { id: "u-me", email: "me@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner", over: Partial<Services> = {}) {
  const store = new FakeStore();
  store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  store.stats = () => Promise.resolve({ db_bytes: 12345, backups: { count: 2, bytes: 999 } });
  store.fnCalls = [{ fn: "admin", calls: 40, errors: 1 }, { fn: "food-photo", calls: 0, errors: 0 }];
  store.tokens = 7;
  const routes = buildRoutes(fakeServices(over));
  const run = (body: unknown) => handle({ jwt: token("aal2"), body }, { store, verify: () => Promise.resolve(ME), routes });
  return { store, run };
}

Deno.test("health: a viewer reads it; without GitHub or FCM the services say so", async () => {
  const { run } = setup("viewer");
  const r = await run({ action: "health" });
  assertEquals(r.status, 200);
  const b = r.body as any;
  assertEquals(b.functions, [{ fn: "admin", calls: 40, errors: 1, rate: 0.025 }, { fn: "food-photo", calls: 0, errors: 0, rate: 0 }]);
  assertEquals([b.db_bytes, b.backups, b.tokens, b.crashlytics, b.ci], [12345, { count: 2, bytes: 999 }, 7, false, null]);
  assertEquals(b.tickets, { new: 0, waiting: 0, solved: 0, deletion_open: 0, overdue: 0, feature_open: 0 });
  assertEquals(b.services.map((s: any) => [s.name, s.state]), [
    ["Auth email delivery", "unknown"], ["ImprovMX forwarding", "ok"], ["GitHub Pages", "unknown"], ["Push (FCM)", "warn"],
  ]);
  assertEquals(b.services[0].note, "Not tracked yet");
  assertEquals(b.services[1].note, "support@gymcoapp.com → inbox");
  assertEquals(b.generated_at, "2026-10-20T12:00:00.000Z");
});

Deno.test("health: GitHub Pages follows the Website run and ci is the CI run", async () => {
  const gh: GitHub = {
    latestRuns: () => Promise.resolve([
      { id: 1, name: "Website", sha7: "a", status: "failed", when: "2026-10-20T09:00:00Z", url: "u1" },
      { id: 2, name: "CI", sha7: "b", status: "passed", when: "2026-10-20T10:00:00Z", url: "u2" },
    ]),
    rerun: () => Promise.resolve(true),
    putFile: () => Promise.resolve(),
  };
  const { run } = setup("viewer", { github: () => gh, fcmConfigured: () => true });
  const b = (await run({ action: "health" })).body as any;
  assertEquals(b.services[2].state, "bad");
  assertEquals(b.services[3].state, "ok");
  assertEquals(b.ci, { name: "CI", status: "passed", when: "2026-10-20T10:00:00Z", url: "u2" });
});
