import { assertEquals } from "jsr:@std/assert@1.0.13";
import { isoWeek, nextFreeDate, outsideQuietHours, parseLocal, weekTakenBy } from "./push_rules.ts";

Deno.test("quiet hours: 23:30 moves to 08:00 the next day", () => {
  assertEquals(outsideQuietHours("2026-10-20T23:30"), { send_at_local: "2026-10-21T08:00", moved: true });
  assertEquals(outsideQuietHours("2026-10-31T22:00"), { send_at_local: "2026-11-01T08:00", moved: true });
});

Deno.test("quiet hours: 06:00 moves to 08:00 the same day", () => {
  assertEquals(outsideQuietHours("2026-10-20T06:00"), { send_at_local: "2026-10-20T08:00", moved: true });
  assertEquals(outsideQuietHours("2026-10-20T07:59"), { send_at_local: "2026-10-20T08:00", moved: true });
});

Deno.test("quiet hours: 09:00 is left alone", () => {
  assertEquals(outsideQuietHours("2026-10-20T09:00"), { send_at_local: "2026-10-20T09:00", moved: false });
  assertEquals(outsideQuietHours("2026-10-20T08:00"), { send_at_local: "2026-10-20T08:00", moved: false });
  assertEquals(outsideQuietHours("2026-10-20T21:59"), { send_at_local: "2026-10-20T21:59", moved: false });
});

Deno.test("a local time must be YYYY-MM-DDTHH:MM and a real date", () => {
  assertEquals(parseLocal("2026-10-20T09:00")?.toISOString(), "2026-10-20T09:00:00.000Z");
  assertEquals(parseLocal("2026-02-30T09:00"), null);
  assertEquals(parseLocal("2026-10-20 09:00"), null);
  assertEquals(parseLocal("2026-10-20T09:00:00Z"), null);
});

Deno.test("ISO weeks: year boundaries follow ISO 8601", () => {
  assertEquals(isoWeek("2026-10-20T09:00"), "2026-W43");
  assertEquals(isoWeek("2027-01-01T09:00"), "2026-W53");
  assertEquals(isoWeek("2024-12-30T09:00"), "2025-W01");
});

Deno.test("a week is taken by another scheduled or sent campaign in it", () => {
  const list = [
    { id: 1, send_at_local: "2026-10-19T09:00", status: "sent" },
    { id: 2, send_at_local: "2026-10-27T09:00", status: "scheduled" },
    { id: 3, send_at_local: "2026-10-21T09:00", status: "cancelled" },
    { id: 4, send_at_local: "2026-10-22T09:00", status: "draft" },
  ];
  assertEquals(weekTakenBy(list, "2026-10-22T09:00", 4)?.id, 1);
  assertEquals(weekTakenBy(list, "2026-10-19T09:00", 1), null);
  assertEquals(weekTakenBy(list, "2026-11-03T09:00", 4), null);
});

Deno.test("the next free date is the Monday of the first week nobody has", () => {
  const list = [
    { id: 1, send_at_local: "2026-10-19T09:00", status: "sent" },
    { id: 2, send_at_local: "2026-10-27T09:00", status: "scheduled" },
  ];
  assertEquals(nextFreeDate(list, "2026-10-22T09:00"), "2026-11-02");
  assertEquals(nextFreeDate([], "2026-10-22T09:00"), "2026-10-26");
});
