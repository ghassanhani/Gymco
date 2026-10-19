import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const css = readFileSync(new URL("../../site/admin/theme.css", import.meta.url), "utf8");

function block(selector) {
  const i = css.indexOf(selector + " {");
  assert.ok(i >= 0, `${selector} block missing`);
  const body = css.slice(i, css.indexOf("}", i));
  return Object.fromEntries([...body.matchAll(/--([a-z0-9-]+):\s*(#[0-9a-fA-F]{6})/g)].map((m) => [m[1], m[2]]));
}

const lum = (hex) => {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
};
const ratio = (a, b) => {
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
};

// Text (4.5:1) and marks and borders that carry meaning (3:1), in each theme.
const TEXT = [
  ["text-1", "page"], ["text-1", "card"], ["text-2", "card"], ["text-3", "card"], ["text-3", "page"], ["text-3", "sheet"],
  ["link", "card"], ["link", "page"], ["on-brand", "brand"], ["good", "card"], ["warn", "card"], ["critical", "card"],
  ["on-critical", "critical"], ["text-2", "raised"], ["link", "brand-wash"],
];
const MARKS = [["chart-1", "card"], ["chart-2", "card"], ["border-strong", "card"], ["focus", "page"]];

for (const [name, sel] of [["dark", ":root"], ["light", ':root[data-theme="light"]']]) {
  const t = block(sel);
  test(`${name}: text pairs reach 4.5:1`, () => {
    for (const [fg, bg] of TEXT) {
      assert.ok(t[fg] && t[bg], `${name} missing --${fg} or --${bg}`);
      assert.ok(ratio(t[fg], t[bg]) >= 4.5, `${name} ${fg} on ${bg} = ${ratio(t[fg], t[bg]).toFixed(2)}`);
    }
  });
  test(`${name}: marks and control borders reach 3:1`, () => {
    for (const [fg, bg] of MARKS) {
      assert.ok(ratio(t[fg], t[bg]) >= 3, `${name} ${fg} on ${bg} = ${ratio(t[fg], t[bg]).toFixed(2)}`);
    }
  });
}

test("dark uses the spec's Volt values", () => {
  const t = block(":root");
  assert.deepEqual([t.page, t.sheet, t.card, t.raised, t.brand], ["#0A0B09", "#111315", "#15171A", "#1F2226", "#C6F432"]);
});
