// The remote config: every key the dashboard can change, its default (what
// the app does today), its hard bounds, and whether only the Owner may change
// it. Shared by the admin function (validation), app-config (resolution) and
// food-photo (limits). The app carries the same defaults, so it works offline.

export type Kind = "bool" | "int" | "num" | "text3" | "enum";

export interface KeySpec {
  kind: Kind;
  default: unknown;
  min?: number;
  max?: number;
  options?: string[];
  owner?: boolean;
  label: string;
  help?: string;
}

const t3 = (en: string, ar: string, es: string) => ({ en, ar, es });

export const SCHEMA: Record<string, Record<string, KeySpec>> = {
  features: {
    photo_log: { kind: "bool", default: true, label: "Photo logging" },
    eating_out: { kind: "bool", default: true, label: "Eating out" },
    dictate: { kind: "bool", default: true, label: "Dictate a meal" },
    barcode_contribute: { kind: "bool", default: true, label: "Add missing barcodes to Open Food Facts" },
    cheat_meals: { kind: "bool", default: true, label: "Cheat meals" },
    catch_up: { kind: "bool", default: true, label: "Catch up unlogged days" },
    monthly_challenge: { kind: "bool", default: true, label: "Monthly challenge" },
  },
  limits: {
    ai_scans_per_day: { kind: "int", default: 10, min: 1, max: 100, label: "AI scans per account per day" },
    photo_note_max_chars: { kind: "int", default: 140, min: 20, max: 500, label: "Photo note length" },
    backup_interval_min: { kind: "int", default: 0, min: 0, max: 1440, label: "Minutes between backups", help: "0 = when the app goes to the background, at most every 6 h" },
  },
  safety: {
    calorie_floor: { kind: "int", default: 1700, min: 1200, max: 2500, owner: true, label: "Calorie floor (kcal)", help: "Targets are never set below this" },
    max_rate_pct_week: { kind: "num", default: 1, min: 0.1, max: 1, owner: true, label: "Max rate (% body weight / week)" },
    max_weekly_target_change_kcal: { kind: "int", default: 120, min: 20, max: 120, owner: true, label: "Max weekly target change (kcal)" },
    banked_slice_warn_kcal: { kind: "int", default: 300, min: 100, max: 500, owner: true, label: "Banked cheat slice warning (kcal/day)" },
  },
  water: {
    ml_per_kg: { kind: "int", default: 35, min: 25, max: 45, label: "Water per kg (ml)" },
    training_day_bonus_l: { kind: "num", default: 0.5, min: 0, max: 1.5, label: "Training day bonus (L)" },
    min_l: { kind: "num", default: 1.5, min: 1, max: 3, label: "Lowest goal (L)" },
    max_l: { kind: "num", default: 5, min: 3, max: 8, label: "Highest goal (L)" },
  },
  streak: {
    freeze_every_days: { kind: "int", default: 7, min: 3, max: 30, label: "Earn a freeze every (days)" },
    freeze_max: { kind: "int", default: 3, min: 0, max: 10, label: "Freezes held at most" },
    repair_next_day: { kind: "bool", default: true, label: "Repair a missed day until 23:59 the next day" },
  },
  app_gate: {
    min_build_ios: { kind: "int", default: 0, min: 0, max: 100000, owner: true, label: "Minimum iOS build", help: "Older builds can't open until they update" },
    min_build_android: { kind: "int", default: 0, min: 0, max: 100000, owner: true, label: "Minimum Android build" },
    recommended_build: { kind: "int", default: 0, min: 0, max: 100000, owner: true, label: "Recommended build", help: "Older builds see a gentle update prompt" },
    maintenance_mode: { kind: "bool", default: false, owner: true, label: "Maintenance mode", help: "Sync, backup, AI and sign-in pause; the diary keeps working" },
    maintenance_message: { kind: "text3", default: t3("Back shortly. Your diary is safe on your phone.", "سنعود قريبًا. مذكراتك آمنة على هاتفك.", "Volvemos pronto. Tu diario está a salvo en tu teléfono."), owner: true, label: "Maintenance message" },
  },
  plans: {
    paywall_enabled: { kind: "bool", default: false, owner: true, label: "Paywall on" },
    testing_unlock_all: { kind: "bool", default: true, owner: true, label: "Testing: every Pro feature unlocked" },
  },
  ai: {
    daily_budget_eur: { kind: "num", default: 10, min: 0, max: 1000, owner: true, label: "Daily AI budget (EUR)", help: "When reached, photo logging rests until 00:00 UTC" },
    photo: { kind: "bool", default: true, label: "Photo scans" },
    write: { kind: "bool", default: true, label: "Write fallback estimates" },
    eating_out: { kind: "bool", default: true, label: "Eating out “Something else”" },
    model: { kind: "enum", default: "claude-haiku-5-5", options: ["claude-haiku-5-5"], label: "Model" },
    prompt_version: { kind: "int", default: 1, min: 1, max: 1, label: "Prompt version" },
    next_model: { kind: "enum", default: "claude-haiku-5-5", options: ["claude-haiku-5-5"], label: "Rollout model" },
    next_prompt_version: { kind: "int", default: 1, min: 1, max: 1, label: "Rollout prompt version" },
    rollout_percent: { kind: "int", default: 0, min: 0, max: 100, label: "Rollout share of installs (%)" },
  },
};

export type Config = Record<string, Record<string, unknown>> & { rules?: Rule[] };
export interface Rule {
  key: string;
  value: unknown;
  target: { platform?: "ios" | "android"; locale?: "en" | "ar" | "es"; min_build?: number; max_build?: number; percent?: number };
}
export interface ConfigError {
  key: string;
  message: string;
}

export function defaults(): any {
  const out: Record<string, Record<string, unknown>> = {};
  for (const [g, keys] of Object.entries(SCHEMA)) {
    out[g] = {};
    for (const [k, spec] of Object.entries(keys)) out[g][k] = structuredClone(spec.default);
  }
  out.rules = [] as unknown as Record<string, unknown>;
  return out;
}

const specOf = (path: string) => {
  const [g, k] = path.split(".");
  return SCHEMA[g]?.[k];
};

function check(spec: KeySpec, v: unknown, key: string, errors: ConfigError[]) {
  const bad = (message: string) => errors.push({ key, message });
  switch (spec.kind) {
    case "bool":
      if (typeof v !== "boolean") bad("Must be on or off");
      break;
    case "int":
    case "num":
      if (typeof v !== "number" || !Number.isFinite(v) || (spec.kind === "int" && !Number.isInteger(v))) bad(spec.kind === "int" ? "Must be a whole number" : "Must be a number");
      else if ((spec.min != null && v < spec.min) || (spec.max != null && v > spec.max)) bad(`Must be between ${spec.min} and ${spec.max}`);
      break;
    case "enum":
      if (!spec.options!.includes(v as string)) bad(`Must be one of ${spec.options!.join(", ")}`);
      break;
    case "text3":
      for (const l of ["en", "ar", "es"]) {
        const s = (v as Record<string, unknown>)?.[l];
        if (typeof s !== "string" || !s.trim()) errors.push({ key: `${key}.${l}`, message: "Needed in English, Arabic and Spanish" });
        else if (s.length > 240) errors.push({ key: `${key}.${l}`, message: "Keep it under 240 characters" });
      }
  }
}

/** Merge [input] over the defaults, keep only known keys, and check bounds. */
export function validate(input: unknown): { ok: boolean; body: any; errors: ConfigError[] } {
  const src = (input && typeof input === "object" ? input : {}) as Record<string, any>;
  const body = defaults();
  const errors: ConfigError[] = [];
  for (const [g, keys] of Object.entries(SCHEMA)) {
    for (const [k, spec] of Object.entries(keys)) {
      if (src[g] && k in src[g]) {
        body[g][k] = src[g][k];
        check(spec, src[g][k], `${g}.${k}`, errors);
      }
    }
  }
  const rules = Array.isArray(src.rules) ? src.rules : [];
  body.rules = rules.slice(0, 50).map((r: any, i: number) => {
    const spec = specOf(String(r?.key ?? ""));
    if (!spec || spec.kind === "text3") {
      errors.push({ key: `rules.${i}.key`, message: "Unknown or untargetable key" });
      return null;
    }
    check(spec, r.value, `rules.${i}.value`, errors);
    const t = r.target ?? {};
    const target: Rule["target"] = {};
    if (t.platform === "ios" || t.platform === "android") target.platform = t.platform;
    if (["en", "ar", "es"].includes(t.locale)) target.locale = t.locale;
    if (Number.isInteger(t.min_build)) target.min_build = t.min_build;
    if (Number.isInteger(t.max_build)) target.max_build = t.max_build;
    if (Number.isInteger(t.percent) && t.percent >= 0 && t.percent <= 100) target.percent = t.percent;
    return { key: r.key, value: r.value, target };
  }).filter(Boolean);
  // Maintenance text is only required while maintenance is on.
  const visible = errors.filter((e) => !e.key.startsWith("app_gate.maintenance_message") || body.app_gate.maintenance_mode === true);
  return { ok: visible.length === 0, body, errors: visible };
}

/** Keys in the owner-only groups whose value differs between two configs. */
export function ownerKeysChanged(before: any, after: any): string[] {
  const out: string[] = [];
  for (const [g, keys] of Object.entries(SCHEMA)) {
    for (const [k, spec] of Object.entries(keys)) {
      if (spec.owner && JSON.stringify(before?.[g]?.[k]) !== JSON.stringify(after?.[g]?.[k])) out.push(`${g}.${k}`);
    }
  }
  if (JSON.stringify((before?.rules ?? []).filter((r: Rule) => specOf(r.key)?.owner)) !== JSON.stringify((after?.rules ?? []).filter((r: Rule) => specOf(r.key)?.owner))) out.push("rules");
  return out;
}

export interface Device {
  platform?: string;
  locale?: string;
  build?: number;
  bucket?: number;
}

/** The config one device sees: the body with every matching rule applied, in order. */
export function resolve(body: any, d: Device): any {
  const out = structuredClone(body);
  delete out.rules;
  for (const r of (body.rules ?? []) as Rule[]) {
    const t = r.target;
    if (t.platform && t.platform !== d.platform) continue;
    if (t.locale && t.locale !== d.locale) continue;
    if (t.min_build != null && !((d.build ?? 0) >= t.min_build)) continue;
    if (t.max_build != null && !((d.build ?? 0) <= t.max_build)) continue;
    if (t.percent != null && !((d.bucket ?? 100) < t.percent)) continue;
    const [g, k] = r.key.split(".");
    out[g][k] = r.value;
  }
  return out;
}
