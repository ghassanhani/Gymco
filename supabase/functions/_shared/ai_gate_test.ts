import { assert, assertAlmostEquals, assertEquals } from "jsr:@std/assert@1.0.13";
import { costEur, featureOf, gate, pickModel } from "./ai_gate.ts";
import { defaults } from "./config_schema.ts";

Deno.test("an image is a photo scan; text is Write unless the app says eating out", () => {
  assertEquals(featureOf({ image: "x" }), "photo");
  assertEquals(featureOf({ note: "rice" }), "write");
  assertEquals(featureOf({ note: "shawarma", feature: "eating_out" }), "eating_out");
  assertEquals(featureOf({ note: "x", feature: "nonsense" }), "write");
});

Deno.test("with today's defaults every AI feature is open", () => {
  assertEquals(gate(defaults(), "photo", 0), { ok: true });
});

Deno.test("a feature switched off is paused, the others still run", () => {
  const c = defaults();
  c.ai.eating_out = false;
  assertEquals(gate(c, "eating_out", 0), { ok: false, reason: "feature_off" });
  assertEquals(gate(c, "photo", 0), { ok: true });
});

Deno.test("the app's own photo switch also stops photo scans", () => {
  const c = defaults();
  c.features.photo_log = false;
  assertEquals(gate(c, "photo", 0), { ok: false, reason: "feature_off" });
});

Deno.test("once today's spend reaches the budget, AI rests until tomorrow", () => {
  const c = defaults();
  c.ai.daily_budget_eur = 5;
  assertEquals(gate(c, "write", 4.99), { ok: true });
  assertEquals(gate(c, "write", 5), { ok: false, reason: "budget" });
});

Deno.test("a budget of 0 means no AI at all", () => {
  const c = defaults();
  c.ai.daily_budget_eur = 0;
  assertEquals(gate(c, "photo", 0), { ok: false, reason: "budget" });
});

Deno.test("maintenance pauses AI", () => {
  const c = defaults();
  c.app_gate.maintenance_mode = true;
  assertEquals(gate(c, "photo", 0), { ok: false, reason: "maintenance" });
});

Deno.test("a rollout sends its share of installs to the next model and prompt", () => {
  const c = defaults();
  c.ai.rollout_percent = 20;
  c.ai.next_prompt_version = 1;
  assertEquals(pickModel(c, 10).cohort, "next");
  assertEquals(pickModel(c, 20).cohort, "current");
  assertEquals(pickModel(c, 99).model, "claude-haiku-5-5");
});

Deno.test("cost is tokens × the model's price, in euros", () => {
  // claude-haiku-5-5: $0.10 in, $0.50 out per million tokens; × 0.92 for EUR.
  assertAlmostEquals(costEur("claude-haiku-5-5", { input_tokens: 1_000_000, output_tokens: 0 }), 0.092, 1e-9);
  assertAlmostEquals(costEur("claude-haiku-5-5", { input_tokens: 2000, output_tokens: 400 }), (2000 * 0.1 + 400 * 0.5) / 1e6 * 0.92, 1e-12);
  assert(costEur("unknown-model", { input_tokens: 10, output_tokens: 10 }) > 0);
});
