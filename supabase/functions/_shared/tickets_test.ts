import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { appTicket, DAILY_LIMIT, GLOBAL_DAILY_LIMIT, overGlobalLimit, daysLeft, deletionDeadline, mailtoFor, overDailyLimit, parseTicket } from "./tickets.ts";

const now = new Date("2026-10-20T12:00:00Z");

Deno.test("a deletion ticket's deadline is 30 days out", () => {
  assertEquals(deletionDeadline(now), "2026-11-19T12:00:00.000Z");
});

Deno.test("days_left counts whole days and goes negative when overdue", () => {
  assertEquals(daysLeft("2026-11-19T12:00:00Z", now), 30);
  assertEquals(daysLeft("2026-10-21T11:00:00Z", now), 0);
  assertEquals(daysLeft("2026-10-19T12:00:00Z", now), -1);
  assertEquals(daysLeft("2026-10-20T00:00:00Z", now), -1);
  assertEquals(daysLeft(null, now), null);
});

Deno.test("a ticket needs a real email, a subject and a body within the table's limits", () => {
  const good = parseTicket({ email: " Ana@Example.com ", subject: " Restore ", body: "Lost my diary", locale: "es", app_version: "1.2.0 (104)", platform: "ios", kind: "deletion" });
  assert(good.ok);
  assertEquals(good.row, { email: "ana@example.com", subject: "Restore", body: "Lost my diary", locale: "es", app_version: "1.2.0 (104)", platform: "ios", kind: "deletion" });
  const bad = parseTicket({ email: "nope", subject: "", body: "x".repeat(5001), locale: "fr", platform: "web", kind: "spam" });
  assert(!bad.ok);
  assertEquals(bad.errors.map((e) => e.key), ["email", "subject", "body"]);
  // Unknown optional values are dropped, not refused.
  const loose = parseTicket({ email: "a@b.co", subject: "s", body: "b", locale: "fr", platform: "web", kind: "spam" });
  assert(loose.ok);
  assertEquals([loose.row.locale, loose.row.platform, loose.row.kind], [null, null, "general"]);
});

Deno.test("five tickets per email per day", () => {
  assertEquals(DAILY_LIMIT, 5);
  assertEquals(overDailyLimit(4), false);
  assertEquals(overDailyLimit(5), true);
});

Deno.test("a mailto link carries the reply subject and body", () => {
  assertEquals(mailtoFor("ana@example.com", "Restore", "Hi Ana,\nDone."), "mailto:ana@example.com?subject=Re%3A%20Restore&body=Hi%20Ana%2C%0ADone.");
});

Deno.test("at most 300 tickets a day from everyone together", () => {
  assertEquals(GLOBAL_DAILY_LIMIT, 300);
  assertEquals(overGlobalLimit(299), false);
  assertEquals(overGlobalLimit(300), true);
});

Deno.test("a ticket from the app: deletions get the deadline and are marked unverified", () => {
  const p = parseTicket({ email: "a@b.co", subject: "Delete me", body: "Please", kind: "deletion" });
  assert(p.ok);
  const del = appTicket(p.row, now);
  assertEquals([del.source, del.deadline_at, del.tags], ["app", "2026-11-19T12:00:00.000Z", ["unverified"]]);
  const general = appTicket({ ...p.row, kind: "general" }, now);
  assertEquals([general.deadline_at, general.tags], [null, []]);
});
