import { test } from "node:test";
import assert from "node:assert/strict";
import {
  barPath, delta, fmtBytes, fmtEur, fmtInt, linePath, mixRows, relTime, sparkPath,
} from "../../site/admin/lib/format.js";

test("counts are grouped", () => {
  assert.equal(fmtInt(1234567), "1,234,567");
  assert.equal(fmtInt(null), "—");
});

test("sizes read in the unit that fits", () => {
  assert.equal(fmtBytes(0), "0 B");
  assert.equal(fmtBytes(812_000), "812 KB");
  assert.equal(fmtBytes(3_400_000), "3.4 MB");
});

test("euros keep two decimals and say when a cost is under a cent", () => {
  assert.equal(fmtEur(1.374), "€1.37");
  assert.equal(fmtEur(0), "€0.00");
  assert.equal(fmtEur(0.0025), "< €0.01");
});

test("times read as people say them", () => {
  const now = new Date("2026-10-19T18:00:00Z");
  assert.equal(relTime("2026-10-19T17:59:30Z", now), "Just now");
  assert.equal(relTime("2026-10-19T16:00:00Z", now), "2 h ago");
  assert.equal(relTime("2026-10-18T09:00:00Z", now), "Yesterday");
  assert.equal(relTime("2026-10-02T09:00:00Z", now), "2 Oct");
  assert.equal(relTime(null, now), "Never");
});

test("a change is a signed percentage with a tone", () => {
  assert.deepEqual(delta(112, 100), { text: "+12%", tone: "good" });
  assert.deepEqual(delta(90, 100), { text: "−10%", tone: "bad" });
  assert.deepEqual(delta(5, 0), { text: "New", tone: "flat" });
  assert.deepEqual(delta(0, 0), { text: "0%", tone: "flat" });
  assert.deepEqual(delta(90, 100, { lowerIsBetter: true }), { text: "−10%", tone: "good" });
});

test("a line spans the width and its peak touches the top padding", () => {
  const d = linePath([0, 5, 10], 600, 200);
  assert.ok(d.startsWith("M0.0 200.0"));
  assert.ok(d.includes("L600.0 10.0"));
});

test("an all-zero line lies on the baseline", () => {
  assert.equal(linePath([0, 0], 100, 50), "M0.0 50.0 L100.0 50.0");
});

test("bars sit on the baseline, one per value", () => {
  const d = barPath([0, 4, 8], 300, 100);
  assert.equal(d.split("M").length - 1, 3);
  assert.ok(d.includes("v-90.0"));
});

test("a sparkline is 120 × 32", () => {
  assert.ok(sparkPath([1, 2, 3]).includes("L120.0"));
});

test("the language mix is labelled, sorted and sums to 100", () => {
  const rows = mixRows({ en: 6, ar: 3, unknown: 1 }, { en: "English", ar: "Arabic" });
  assert.deepEqual(rows.map((r) => r.label), ["English", "Arabic", "Not reported yet"]);
  assert.deepEqual(rows.map((r) => r.pct), [60, 30, 10]);
  assert.deepEqual(mixRows({}, {}), []);
});
