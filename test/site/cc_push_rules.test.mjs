import { test } from "node:test";
import assert from "node:assert/strict";
import { isoWeek, onDate, quietHours, quietNote, weekTakenBy } from "../../site/admin/lib/push_rules.js";

test("quiet hours move a send to 08:00, the next day after 22:00", () => {
  assert.deepEqual(quietHours("2026-10-23T09:30"), { send_at_local: "2026-10-23T09:30", moved: false });
  assert.deepEqual(quietHours("2026-10-23T21:59"), { send_at_local: "2026-10-23T21:59", moved: false });
  assert.deepEqual(quietHours("2026-10-23T23:30"), { send_at_local: "2026-10-24T08:00", moved: true });
  assert.deepEqual(quietHours("2026-10-23T06:15"), { send_at_local: "2026-10-23T08:00", moved: true });
  assert.deepEqual(quietHours("2026-10-31T22:00"), { send_at_local: "2026-11-01T08:00", moved: true });
  assert.deepEqual(quietHours(""), { send_at_local: "", moved: false });
});

test("the editor's hint names the typed time", () => {
  assert.equal(quietNote("2026-10-23T23:30"), "23:30 is inside quiet hours · phones in each time zone get it at 08:00 their time instead");
  assert.equal(quietNote("2026-10-23T10:00"), null);
});

test("ISO weeks and the one-a-week rule", () => {
  assert.equal(isoWeek("2026-10-23T09:00"), "2026-W43");
  assert.equal(isoWeek("2026-10-26"), "2026-W44");
  assert.equal(isoWeek("2027-01-01"), "2026-W53");
  const taken = { id: "p1", status: "scheduled", send_at_local: "2026-10-23T09:00" };
  assert.equal(weekTakenBy([taken], "2026-10-21T18:00"), taken);
  assert.equal(weekTakenBy([taken], "2026-10-21T18:00", "p1"), null);
  assert.equal(weekTakenBy([{ ...taken, status: "draft" }], "2026-10-21T18:00"), null);
  assert.equal(weekTakenBy([taken], "2026-10-30T09:00"), null);
});

test("re-scheduling keeps the time of day", () => {
  assert.equal(onDate("2026-10-30", "2026-10-23T09:30"), "2026-10-30T09:30");
  assert.equal(onDate("2026-10-30", ""), "2026-10-30T09:00");
});
