import { test } from "node:test";
import assert from "node:assert/strict";
import { ICONS } from "../../site/admin/lib/icons.js";
import { NAV } from "../../site/admin/lib/routes.js";

test("every sidebar section has a library icon", () => {
  for (const g of NAV) for (const i of g.items) assert.ok(ICONS[i.id]?.length, i.id);
});

test("the top bar, locks and tiles use library icons", () => {
  for (const k of ["menu", "search", "sun", "moon", "lock", "k-accounts", "k-signups", "k-active", "k-scans", "k-cost", "k-cap", "k-deletions", "k-db", "k-crash", "k-errors", "k-storage"]) {
    assert.ok(ICONS[k]?.length, k);
  }
});

test("icons are plain shapes in currentColor, nothing a browser could run", () => {
  const shapes = new Set(["path", "circle", "ellipse", "rect", "line", "polyline", "polygon"]);
  for (const [name, parts] of Object.entries(ICONS)) {
    for (const [tag, attrs] of parts) {
      assert.ok(shapes.has(tag), `${name}: ${tag}`);
      for (const [k, v] of Object.entries(attrs)) {
        assert.ok(!/^on/i.test(k) && !/href/i.test(k), `${name}: ${k}`);
        if (k === "fill" || k === "stroke") assert.ok(v === "none" || v === "currentColor", `${name}: ${k}=${v}`);
      }
    }
  }
});
