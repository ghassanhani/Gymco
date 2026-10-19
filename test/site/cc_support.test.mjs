import { test } from "node:test";
import assert from "node:assert/strict";
import { ageLabel, ageLate, daysLeft, deadlineLine, fillTemplate, matchTickets, tabLabel, ticketMeta } from "../../site/admin/lib/support.js";

const now = new Date("2026-10-19T12:00:00Z");

test("tabs carry their counts; Solved has none", () => {
  const counts = { new: 4, waiting: 3, solved: 90, deletion_open: 2, overdue: 1 };
  assert.equal(tabLabel("new", counts), "New · 4");
  assert.equal(tabLabel("waiting", counts), "Waiting · 3");
  assert.equal(tabLabel("solved", counts), "Solved");
  assert.equal(tabLabel("deletion", counts), "Deletion requests · 2");
  assert.equal(tabLabel("new", {}), "New");
});

test("age reads in the unit that fits and goes red after a day unanswered", () => {
  assert.equal(ageLabel("2026-10-19T11:59:40Z", now), "Just now");
  assert.equal(ageLabel("2026-10-19T11:25:00Z", now), "35 min");
  assert.equal(ageLabel("2026-10-19T06:00:00Z", now), "6 h");
  assert.equal(ageLabel("2026-10-16T09:00:00Z", now), "3 d");
  assert.equal(ageLate({ status: "new", created_at: "2026-10-18T11:00:00Z" }, now), true);
  assert.equal(ageLate({ status: "new", created_at: "2026-10-18T13:00:00Z" }, now), false);
  assert.equal(ageLate({ status: "waiting", created_at: "2026-10-10T13:00:00Z" }, now), false);
});

test("the deletion countdown: plain, yellow from 7 days, red once overdue", () => {
  assert.equal(daysLeft("2026-11-15T12:00:00Z", now), 27);
  assert.equal(daysLeft("2026-10-17T12:00:00Z", now), -2);
  // Whole days round down, as the server's days_left does.
  assert.equal(daysLeft("2026-11-15T00:00:00Z", now), 26);
  assert.equal(daysLeft("2026-10-19T18:00:00Z", now), 0);
  assert.equal(daysLeft("2026-10-19T06:00:00Z", now), -1);
  assert.equal(daysLeft(null, now), null);
  const far = deadlineLine(27, "2026-11-15T12:00:00Z");
  assert.deepEqual(far, { number: "27", label: "days left to complete deletion", tone: "", legal: "Legal deadline: 30 days from 16 Oct" });
  assert.equal(deadlineLine(3, "2026-10-22T12:00:00Z").tone, "warn");
  const late = deadlineLine(-2, "2026-10-17T12:00:00Z");
  assert.equal(late.number, "−2");
  assert.equal(late.label, "days overdue");
  assert.equal(late.tone, "bad");
  assert.equal(deadlineLine(1, null).label, "day left to complete deletion");
  assert.equal(deadlineLine(null), null);
});

test("ticket meta and templates", () => {
  assert.equal(ticketMeta({ email: "user@example.com", locale: "ar", app_version: "1.0.2", source: "email" }), "user@example.com · Arabic · v1.0.2 · via support@gymcoapp.com");
  assert.equal(ticketMeta({ email: "a@b.c", locale: "en", source: "app" }), "a@b.c · English · via the in-app form");
  assert.equal(fillTemplate("Hi {email}, done. {email}", "a@b.c"), "Hi a@b.c, done. a@b.c");
});

test("search covers subject, email and tags", () => {
  const items = [{ subject: "Restore failed", email: "a@b.c", tags: ["bug"] }, { subject: "Delete me", email: "x@y.z", tags: ["deletion"] }];
  assert.equal(matchTickets(items, "BUG").length, 1);
  assert.equal(matchTickets(items, "y.z")[0].subject, "Delete me");
  assert.equal(matchTickets(items, "  ").length, 2);
});
