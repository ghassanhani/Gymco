// The landing page at gymcoapp.com/: which sections show, the copy the
// Control Center may change, prices, store links, the FAQ and the email
// sign-up. One versioned body, like the remote config. The page carries the
// same defaults and works without it; the keys here match site/landing-copy.js.

import { checkT3, type T3 } from "./announcements.ts";

export const LANDING_KEYS = [
  "hero.title", "hero.lede", "hero.cta", "hero.cta2",
  "food.eyebrow", "food.title", "food.sub",
  "train.title", "train.sub", "train.cta",
  "coaching.eyebrow", "coaching.title", "coaching.sub",
  "streak.eyebrow", "streak.title", "streak.sub",
  "privacy.eyebrow", "privacy.title", "privacy.sub",
  "plans.eyebrow", "plans.title", "plans.banner",
  "faq.eyebrow", "faq.title",
  "join.title", "join.sub", "join.consent",
  "footer.tagline",
] as const;
export type LandingKey = typeof LANDING_KEYS[number];

/** The design's English, shown as hints in the dashboard. In titles *word* is the italic accent. */
export const LANDING_DEFAULTS: Record<LandingKey, string> = {
  "hero.title": "Diet and training for *lifters*",
  "hero.lede": "Log food in seconds, train with a plan, and keep a streak worth protecting.",
  "hero.cta": "Join the beta",
  "hero.cta2": "See how it works",
  "food.eyebrow": "Food",
  "food.title": "Log food *your way*",
  "food.sub": "Six ways in, so a meal never goes unlogged. You confirm every entry before it counts.",
  "train.title": "Train with a *plan*",
  "train.sub": "Pick a split or build your own. Miss a day and the week moves with you, and last time's numbers sit on every set.",
  "train.cta": "Choose a routine",
  "coaching.eyebrow": "Coaching",
  "coaching.title": "Measured, *not guessed*",
  "coaching.sub": "Your targets come from what you ate and how your trend weight moved. Not from a formula pretending to know you.",
  "streak.eyebrow": "Streaks and awards",
  "streak.title": "A streak worth *protecting*",
  "streak.sub": "A day counts when your meals are logged and you train or rest as planned. Rest days count too.",
  "privacy.eyebrow": "Privacy",
  "privacy.title": "Your data stays *yours*",
  "privacy.sub": "No account needed. The diary lives on your phone. Progress photos never leave it.",
  "plans.eyebrow": "Plans",
  "plans.title": "Free while we *test*",
  "plans.banner": "Gymco is in testing. Nothing is for sale yet, and every Pro feature is unlocked.",
  "faq.eyebrow": "FAQ",
  "faq.title": "Questions, *answered*",
  "join.title": "Start your *streak*",
  "join.sub": "Join the beta today. It's free while we test, and you keep every Pro feature until launch.",
  "join.consent": "One email at launch, with an unsubscribe link. We store your email and language only.",
  "footer.tagline": "Diet and training for lifters. Built in Barcelona, private by default.",
};

export const SECTIONS = ["proof", "food", "train", "coaching", "streak", "privacy", "plans", "faq", "join"] as const;
export const PRICE_KEYS = ["pro_month", "pro_year", "lifetime", "year_save"] as const;
export const STORE_PREFIX = { ios_url: "https://apps.apple.com/", android_url: "https://play.google.com/" } as const;
export const FAQ_MAX = 20;

export interface LandingBody {
  sections: Record<typeof SECTIONS[number], boolean>;
  beta: boolean;
  copy: Partial<Record<LandingKey, T3>>;
  prices: Record<typeof PRICE_KEYS[number], string>;
  stores: Record<keyof typeof STORE_PREFIX, string>;
  faq: { q: T3; a: T3 }[];
  notify: boolean;
}

export interface LandingError {
  key: string;
  message: string;
}

export function defaultLanding(): LandingBody {
  return {
    sections: Object.fromEntries(SECTIONS.map((s) => [s, true])) as LandingBody["sections"],
    beta: true,
    copy: {},
    prices: { pro_month: "€4.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" },
    stores: { ios_url: "", android_url: "" },
    faq: [],
    notify: true,
  };
}

const isObj = (v: unknown): v is Record<string, unknown> => v !== null && typeof v === "object" && !Array.isArray(v);
const titleMax = (k: string) => (k.endsWith(".title") ? 80 : 300);

/** Merge [input] over the defaults, keep only known keys, and check each value. */
export function validateLanding(input: unknown): { ok: boolean; body: LandingBody; errors: LandingError[] } {
  const src = isObj(input) ? input : {};
  const body = defaultLanding();
  const errors: LandingError[] = [];
  const bool = (v: unknown, key: string, set: (b: boolean) => void) => {
    if (typeof v === "boolean") set(v);
    else errors.push({ key, message: "Must be on or off" });
  };

  if (isObj(src.sections)) {
    for (const s of SECTIONS) if (s in src.sections) bool(src.sections[s], `sections.${s}`, (b) => (body.sections[s] = b));
  }
  if ("beta" in src) bool(src.beta, "beta", (b) => (body.beta = b));
  if ("notify" in src) bool(src.notify, "notify", (b) => (body.notify = b));

  if (isObj(src.copy)) {
    for (const [k, v] of Object.entries(src.copy)) {
      if (!(LANDING_KEYS as readonly string[]).includes(k)) {
        errors.push({ key: `copy.${k}`, message: "Not a key the page can take" });
        continue;
      }
      const t = checkT3(v, `copy.${k}`, titleMax(k));
      errors.push(...t.errors);
      body.copy[k as LandingKey] = t.value;
    }
  }

  if (isObj(src.prices)) {
    for (const p of PRICE_KEYS) {
      if (!(p in src.prices)) continue;
      const v = src.prices[p];
      const s = typeof v === "string" ? v.trim() : "";
      if (!s || s.length > 12) errors.push({ key: `prices.${p}`, message: "1 to 12 characters, like €4.99" });
      else body.prices[p] = s;
    }
  }

  if (isObj(src.stores)) {
    for (const [k, prefix] of Object.entries(STORE_PREFIX) as [keyof typeof STORE_PREFIX, string][]) {
      if (!(k in src.stores)) continue;
      const v = src.stores[k];
      const s = typeof v === "string" ? v.trim() : null;
      if (s === "" || (s && s.startsWith(prefix) && !/\s/.test(s) && s.length <= 500)) body.stores[k] = s;
      else errors.push({ key: `stores.${k}`, message: `Empty, or a link starting with ${prefix}` });
    }
  }

  if ("faq" in src) {
    if (!Array.isArray(src.faq)) errors.push({ key: "faq", message: "Must be a list of questions" });
    else if (src.faq.length > FAQ_MAX) errors.push({ key: "faq", message: `At most ${FAQ_MAX} questions` });
    else {
      body.faq = src.faq.map((item, i) => {
        const it = isObj(item) ? item : {};
        const q = checkT3(it.q, `faq.${i}.q`, 200);
        const a = checkT3(it.a, `faq.${i}.a`, 1000);
        errors.push(...q.errors, ...a.errors);
        return { q: q.value, a: a.value };
      });
    }
  }

  return { ok: errors.length === 0, body, errors };
}
