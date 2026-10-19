import { test } from "node:test";
import assert from "node:assert/strict";
import { aiCost, barGeometry, cleanCode, fmtBytes, fmtInt, weekCompare } from "../../site/admin/view.js";

const series = (values) => values.map((n, i) => ({ day: `2026-10-${String(i + 1).padStart(2, "0")}`, n }));
const zeros = series(Array(30).fill(0));

test("a quiet month compares as zero with no change", () => {
  assert.deepEqual(weekCompare(zeros), { thisWeek: 0, lastWeek: 0, change: null });
});

test("this week is the last 7 days against the 7 before", () => {
  const values = [...Array(16).fill(9), ...Array(7).fill(1), ...Array(7).fill(2)];
  assert.deepEqual(weekCompare(series(values)), { thisWeek: 14, lastWeek: 7, change: 1 });
});

test("AI cost is half a tenth of a cent per scan", () => {
  assert.equal(aiCost(1000), 0.5);
  assert.equal(aiCost(0), 0);
});

test("counts are grouped", () => {
  assert.equal(fmtInt(1234567), "1,234,567");
});

test("sizes read in the unit that fits", () => {
  assert.equal(fmtBytes(0), "0 B");
  assert.equal(fmtBytes(812_000), "812 KB");
  assert.equal(fmtBytes(3_400_000), "3.4 MB");
  assert.equal(fmtBytes(500_000_000), "500 MB");
});

test("an empty series draws flat bars, one per day", () => {
  const bars = barGeometry(zeros, 300, 100);
  assert.equal(bars.length, 30);
  assert.ok(bars.every((b) => b.h === 0 && b.y === 100));
});

test("the tallest day fills the height and the rest scale to it", () => {
  const bars = barGeometry(series([...Array(28).fill(0), 5, 10]), 300, 100);
  assert.equal(bars[29].h, 100);
  assert.equal(bars[28].h, 50);
  assert.equal(bars[29].y, 0);
  assert.ok(bars[29].x > bars[28].x);
  assert.ok(bars[0].w > 0 && bars[0].x + bars[0].w <= bars[1].x);
});

test("a pasted code keeps only its digits", () => {
  assert.equal(cleanCode(" 12 34 56\n"), "123456");
});
