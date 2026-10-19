import { test } from "node:test";
import assert from "node:assert/strict";
import { checkField, countChanges, ruleSummary, targetLabel, setKey } from "../../site/admin/lib/config_form.js";

const int = { kind: "int", min: 0, max: 100 };

test("a value outside its bound says the bound, the way the server does", () => {
  assert.equal(checkField(int, 12), null);
  assert.equal(checkField(int, 101), "Must be between 0 and 100");
  assert.equal(checkField(int, 1.5), "Must be a whole number");
  assert.equal(checkField({ kind: "num", min: 0.1, max: 1 }, NaN), "Must be a number");
});

test("the photo cap points at the kill switch instead of 0", () => {
  assert.match(checkField(int, 0, "limits.ai_scans_per_day"), /photo_log/);
});

test("a feature's targeting reads as a short summary", () => {
  const rules = [
    { key: "features.monthly_challenge", value: true, target: { locale: "ar", percent: 50 } },
    { key: "features.monthly_challenge", value: true, target: { locale: "es", percent: 50 } },
    { key: "features.dictate", value: false, target: { platform: "android", min_build: 100, max_build: 104 } },
  ];
  assert.equal(ruleSummary(rules, "features.monthly_challenge"), "AR · 50%, ES · 50%");
  assert.equal(ruleSummary(rules, "features.dictate"), "Android · builds 100–104");
  assert.equal(ruleSummary(rules, "features.photo_log"), "All");
  assert.equal(targetLabel({}), "Everyone");
});

test("changes are counted against what is published", () => {
  const a = { limits: { ai_scans_per_day: 10 }, features: { cheat_meals: true }, rules: [] };
  const b = setKey(setKey(a, "limits.ai_scans_per_day", 12), "features.cheat_meals", false);
  assert.equal(countChanges(a, b), 2);
  assert.equal(a.limits.ai_scans_per_day, 10, "setKey copies");
});
