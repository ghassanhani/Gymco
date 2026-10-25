// Whether an AI request may run, which model it gets, and what it cost.
// food-photo and routine-ai ask here before spending anything.

export type Feature = "photo" | "write" | "eating_out" | "routine";
export type GateResult = { ok: true } | { ok: false; reason: "feature_off" | "budget" | "maintenance" };

/** Per million tokens, in US dollars. */
const PRICES_USD: Record<string, { in: number; out: number }> = {
  "claude-haiku-5-5": { in: 0.1, out: 0.5 },
};
/** A fixed rate is good enough for an estimate; exact spend is in the Anthropic console. */
const USD_TO_EUR = 0.92;
/** An unknown model is costed as the dearest known one, so the budget errs on the safe side. */
const FALLBACK = { in: 0.1, out: 0.5 };

export function featureOf(body: { image?: unknown; note?: unknown; feature?: unknown }): Feature {
  if (typeof body.image === "string" && body.image) return "photo";
  return body.feature === "eating_out" ? "eating_out" : "write";
}

/** [spentTodayEur] is null when the spend couldn't be read: then AI rests, so an outage can't overspend. */
export function gate(config: any, feature: Feature, spentTodayEur: number | null): GateResult {
  if (config.app_gate?.maintenance_mode) return { ok: false, reason: "maintenance" };
  if (config.ai?.[feature] === false) return { ok: false, reason: "feature_off" };
  if (feature === "photo" && config.features?.photo_log === false) return { ok: false, reason: "feature_off" };
  if (feature === "eating_out" && config.features?.eating_out === false) return { ok: false, reason: "feature_off" };
  if (spentTodayEur === null || spentTodayEur >= (config.ai?.daily_budget_eur ?? 10)) return { ok: false, reason: "budget" };
  return { ok: true };
}

/** [bucket] is 0–99, fixed per install; buckets under the rollout share get the next model. */
export function pickModel(config: any, bucket: number) {
  const ai = config.ai ?? {};
  const next = bucket < (ai.rollout_percent ?? 0);
  return next
    ? { cohort: "next" as const, model: ai.next_model ?? "claude-haiku-5-5", prompt: ai.next_prompt_version ?? 1 }
    : { cohort: "current" as const, model: ai.model ?? "claude-haiku-5-5", prompt: ai.prompt_version ?? 1 };
}

export function costEur(model: string, usage: { input_tokens?: number; output_tokens?: number }): number {
  const p = PRICES_USD[model] ?? FALLBACK;
  return (((usage.input_tokens ?? 0) * p.in + (usage.output_tokens ?? 0) * p.out) / 1e6) * USD_TO_EUR;
}
