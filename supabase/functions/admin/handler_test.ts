import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { handle } from "./handler.ts";
import { FakeStore, token } from "./fake_store.ts";

const ME = { id: "u-owner", email: "owner@gymco.test" };

function setup(role: "viewer" | "support" | "editor" | "owner" | null = "owner", aal: "aal1" | "aal2" = "aal2") {
  const store = new FakeStore();
  if (role) store.admins.set(ME.id, { user_id: ME.id, email: ME.email, role });
  store.users.set("u-1", { id: "u-1", email: "user@example.com" });
  const run = (body: unknown, jwt: string | null = token(aal)) =>
    handle({ jwt, body }, { store, verify: (t) => Promise.resolve(t ? ME : null) });
  return { store, run };
}

Deno.test("no token is 401", async () => {
  const { run } = setup();
  assertEquals((await run({ action: "me" }, null)).status, 401);
});

Deno.test("a session without the second factor is asked for it", async () => {
  const { run } = setup("owner", "aal1");
  const r = await run({ action: "me" });
  assertEquals([r.status, (r.body as { error: string }).error], [403, "mfa_required"]);
});

Deno.test("someone who isn't an admin is refused", async () => {
  const { run } = setup(null);
  const r = await run({ action: "me" });
  assertEquals([r.status, (r.body as { error: string }).error], [403, "not_admin"]);
});

Deno.test("me says who and what role", async () => {
  const { run } = setup("editor");
  assertEquals((await run({ action: "me" })).body, { email: ME.email, role: "editor" });
});

Deno.test("an unknown action is a 400", async () => {
  const { run } = setup();
  assertEquals((await run({ action: "drop.tables" })).status, 400);
});

Deno.test("a viewer reads the overview but can't open an account", async () => {
  const { run } = setup("viewer");
  assertEquals((await run({ action: "stats", range: 30 })).status, 200);
  const r = await run({ action: "account.lookup", email: "user@example.com", reason: "support_ticket" });
  assertEquals([r.status, (r.body as { error: string }).error], [403, "forbidden"]);
});

Deno.test("looking up an account needs a reason from the list", async () => {
  const { run, store } = setup("support");
  const r = await run({ action: "account.lookup", email: "user@example.com", reason: "curious" });
  assertEquals([r.status, (r.body as { error: string }).error], [400, "reason_required"]);
  assertEquals(store.audit.length, 0);
});

Deno.test("a lookup is audited even when no account matches", async () => {
  const { run, store } = setup("support");
  const r = await run({ action: "account.lookup", email: "nobody@example.com", reason: "support_ticket" });
  assertEquals(r.status, 404);
  assertEquals(store.audit.at(-1)?.action, "lookup");
  assertEquals(store.audit.at(-1)?.reason, "support_ticket");
});

Deno.test("deleting an account needs the email typed back", async () => {
  const { run, store } = setup("owner");
  const bad = await run({ action: "account.action", user_id: "u-1", act: "delete_account", reason: "deletion_request", confirm_email: "wrong@example.com" });
  assertEquals([bad.status, (bad.body as { error: string }).error], [400, "confirm_mismatch"]);
  assert(store.users.has("u-1"));
  const ok = await run({ action: "account.action", user_id: "u-1", act: "delete_account", reason: "deletion_request", confirm_email: " USER@example.com " });
  assertEquals(ok.status, 200);
  assert(!store.users.has("u-1"));
  assertEquals(store.deletionsCounted, 1);
  assertEquals(store.audit.at(-1)?.action, "delete_account");
});

Deno.test("extra scans are 1 to 100", async () => {
  const { run, store } = setup("support");
  assertEquals((await run({ action: "account.action", user_id: "u-1", act: "grant_scans", extra: 500, reason: "support_ticket" })).status, 400);
  assertEquals((await run({ action: "account.action", user_id: "u-1", act: "grant_scans", extra: 5, reason: "support_ticket" })).status, 200);
  assertEquals(store.grants.get("u-1"), 5);
});

Deno.test("support can't grant a plan without a reason, owner can with one", async () => {
  const { run } = setup("owner");
  assertEquals((await run({ action: "account.action", user_id: "u-1", act: "grant_plan", plan: "pro" })).status, 400);
  assertEquals((await run({ action: "account.action", user_id: "u-1", act: "grant_plan", plan: "pro", reason: "test" })).status, 200);
});

Deno.test("the last owner can't be demoted or removed", async () => {
  const { run } = setup("owner");
  const r = await run({ action: "team.set_role", user_id: ME.id, role: "editor" });
  assertEquals([r.status, (r.body as { error: string }).error], [400, "last_owner"]);
  assertEquals((await run({ action: "team.remove", user_id: ME.id })).status, 400);
});

Deno.test("only an owner manages the team", async () => {
  const { run } = setup("editor");
  assertEquals((await run({ action: "team.invite", email: "new@gymco.test", role: "viewer" })).status, 403);
});

Deno.test("an invite adds the admin and is audited", async () => {
  const { run, store } = setup("owner");
  const r = await run({ action: "team.invite", email: "New@Gymco.test", role: "support" });
  assertEquals(r.status, 200);
  assert([...store.admins.values()].some((a) => a.email === "new@gymco.test" && a.role === "support"));
  assertEquals(store.audit.at(-1)?.section, "team");
});

Deno.test("a note is 1 to 2000 characters", async () => {
  const { run } = setup("support");
  assertEquals((await run({ action: "note.add", user_id: "u-1", note: "   " })).status, 400);
  assertEquals((await run({ action: "note.add", user_id: "u-1", note: "Emailed about restore." })).status, 200);
});

Deno.test("audit export is owner only and comes back as CSV", async () => {
  const viewer = setup("viewer");
  assertEquals((await viewer.run({ action: "audit.export" })).status, 403);
  const owner = setup("owner");
  await owner.run({ action: "note.add", user_id: "u-1", note: "x" });
  const r = await owner.run({ action: "audit.export" });
  assertEquals(r.status, 200);
  assert(String((r.body as { csv: string }).csv).startsWith("at,admin,section,action,object,reason,before,after"));
});

Deno.test("no admin's account or backup can be deleted from the accounts page", async () => {
  const { run, store } = setup("support");
  store.users.set(ME.id, { id: ME.id, email: ME.email });
  store.users.set("u-boss", { id: "u-boss", email: "boss@gymco.test" });
  store.admins.set("u-boss", { user_id: "u-boss", email: "boss@gymco.test", role: "owner" });
  for (const act of ["delete_account", "delete_backup"]) {
    for (const [uid, email] of [["u-boss", "boss@gymco.test"], [ME.id, ME.email]]) {
      const r = await run({ action: "account.action", user_id: uid, act, reason: "deletion_request", confirm_email: email });
      assertEquals([r.status, (r.body as { error: string }).error], [403, "is_admin"], `${act} ${uid}`);
    }
  }
  assert(store.users.has("u-boss") && store.admins.has("u-boss"));
  assertEquals(store.deletionsCounted, 0);
  assertEquals(store.audit.length, 0);
});

Deno.test("the audit list is for support and up, not viewers", async () => {
  const viewer = setup("viewer");
  const r = await viewer.run({ action: "audit.list" });
  assertEquals([r.status, (r.body as { error: string }).error], [403, "forbidden"]);
  assertEquals((await setup("support").run({ action: "audit.list" })).status, 200);
});
