import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { defaults, ownerKeysChanged, resolve, validate } from "./config_schema.ts";

Deno.test("defaults are what the app does today", () => {
  const d = defaults();
  assertEquals(d.limits.ai_scans_per_day, 10);
  assertEquals(d.limits.photo_note_max_chars, 140);
  assertEquals(d.safety.calorie_floor, 1700);
  assertEquals(d.safety.max_rate_pct_week, 1);
  assertEquals(d.safety.max_weekly_target_change_kcal, 120);
  assertEquals(d.safety.banked_slice_warn_kcal, 300);
  assertEquals([d.water.ml_per_kg, d.water.training_day_bonus_l, d.water.min_l, d.water.max_l], [35, 0.5, 1.5, 5]);
  assertEquals([d.streak.freeze_every_days, d.streak.freeze_max], [7, 3]);
  assert(Object.values(d.features).every((v) => v === true));
  assertEquals([d.plans.paywall_enabled, d.plans.testing_unlock_all], [false, true]);
  assertEquals(d.app_gate.maintenance_mode, false);
});

Deno.test("a valid change passes and missing keys are filled from the defaults", () => {
  const r = validate({ limits: { ai_scans_per_day: 12 } });
  assert(r.ok);
  assertEquals(r.body.limits.ai_scans_per_day, 12);
  assertEquals(r.body.water.ml_per_kg, 35);
});

Deno.test("safety values can't leave their coded bounds", () => {
  for (const [key, value] of [
    ["calorie_floor", 1100],
    ["max_rate_pct_week", 1.5],
    ["max_weekly_target_change_kcal", 200],
  ] as const) {
    const r = validate({ safety: { [key]: value } });
    assert(!r.ok, key);
    assert(r.errors.some((e) => e.key === `safety.${key}`), key);
  }
});

Deno.test("a wrong type is an error, not a coercion", () => {
  const r = validate({ features: { photo_log: "yes" } });
  assert(!r.ok);
  assertEquals(r.errors[0].key, "features.photo_log");
});

Deno.test("unknown keys are dropped so an old dashboard can't publish junk", () => {
  const r = validate({ features: { teleport: true }, extra: 1 });
  assert(r.ok);
  assert(!("teleport" in r.body.features));
  assert(!("extra" in r.body));
});

Deno.test("maintenance needs its message in all three languages", () => {
  const r = validate({ app_gate: { maintenance_mode: true, maintenance_message: { en: "Back soon", ar: "", es: "Volvemos" } } });
  assert(!r.ok);
  assertEquals(r.errors[0].key, "app_gate.maintenance_message.ar");
});

Deno.test("only the owner's keys are flagged as owner changes", () => {
  const a = defaults();
  const b = validate({ features: { dictate: false }, safety: { calorie_floor: 1800 }, ai: { daily_budget_eur: 20 } }).body;
  assertEquals(ownerKeysChanged(a, b).sort(), ["ai.daily_budget_eur", "safety.calorie_floor"]);
});

Deno.test("rules target platform, language, version range and a percentage of installs", () => {
  const body = validate({
    rules: [
      { key: "features.photo_log", value: false, target: { platform: "android" } },
      { key: "limits.ai_scans_per_day", value: 20, target: { locale: "ar", min_build: 102 } },
      { key: "features.dictate", value: false, target: { percent: 25 } },
    ],
  }).body;
  const ios = resolve(body, { platform: "ios", locale: "en", build: 101, bucket: 50 });
  assertEquals([ios.features.photo_log, ios.limits.ai_scans_per_day, ios.features.dictate], [true, 10, true]);
  const android = resolve(body, { platform: "android", locale: "ar", build: 102, bucket: 10 });
  assertEquals([android.features.photo_log, android.limits.ai_scans_per_day, android.features.dictate], [false, 20, false]);
  assert(!("rules" in android));
});

Deno.test("a rule can't set a value outside the key's bounds", () => {
  const r = validate({ rules: [{ key: "safety.calorie_floor", value: 900, target: {} }] });
  assert(!r.ok);
  assertEquals(r.errors[0].key, "rules.0.value");
});

Deno.test("a rule on an unknown key is an error", () => {
  const r = validate({ rules: [{ key: "features.teleport", value: true, target: {} }] });
  assert(!r.ok);
});
