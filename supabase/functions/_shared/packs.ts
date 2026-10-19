// Content packs: what each kind's body may hold, the canonical JSON its
// checksum is computed over, and the rules that keep packs honest (three
// languages, sane numbers, no awards for weight loss, no removing exercises a
// template needs). Shared by admin (validation, checksum) and app-config
// (serving the same canonical string the checksum was computed over).

export const PACK_KINDS = ["foods", "vocabulary", "eating_out", "exercises", "templates", "awards", "challenges", "copy"] as const;
export type PackKind = typeof PACK_KINDS[number];

export interface PackIssue {
  key: string;
  message: string;
}

/** Facts from other packs that some rules need. */
export interface PackContext {
  /** Exercise id → names of the templates (published pack) that use it. Built-ins are added here. */
  templateExercises?: Map<string, string[]>;
  /** Exercise ids the published exercises pack removes. */
  removedExercises?: Set<string>;
}

// Canonical JSON ---------------------------------------------------------------

/** Keys sorted recursively, no whitespace: the exact string phones hash. */
export function canonicalJson(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map((x) => (x === undefined ? "null" : canonicalJson(x))).join(",")}]`;
  if (v !== null && typeof v === "object") {
    const o = v as Record<string, unknown>;
    const parts = Object.keys(o).sort().filter((k) => o[k] !== undefined).map((k) => `${JSON.stringify(k)}:${canonicalJson(o[k])}`);
    return `{${parts.join(",")}}`;
  }
  return JSON.stringify(v);
}

export async function checksum(body: unknown): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(canonicalJson(body)));
  return [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Fixed lists --------------------------------------------------------------------

export const COPY_KEYS = [
  "emptyDayTitle", "emptyDayBody", "obWelcomeBody", "welcomeBody", "welcomeLogBody",
  "welcomeTrainBody", "welcomeProgressBody", "obTargetsBody", "remindMealBody", "remindWorkoutBody",
] as const;

const MUSCLES = [
  "chest", "shoulders", "triceps", "biceps", "forearms", "lats", "middle back", "lower back", "traps",
  "abdominals", "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors", "neck",
];
const UNITS = ["piece", "scoop", "slice", "tbsp", "tsp", "cup", "handful", "bowl"];
const LANGS = ["en", "ar", "es"] as const;

/**
 * Words an award may not use: they reward losing weight or eating less.
 * English and Spanish match whole words, ignoring case and accents; Arabic
 * matches inside words, since it attaches prefixes like ال and و.
 */
export const AWARD_BLOCKED_WORDS: Record<"en" | "ar" | "es", string[]> = {
  en: [
    "lose weight", "losing weight", "lost weight", "weight loss", "fat loss", "lose fat", "burn fat", "fat burning",
    "kg", "kgs", "kilo", "kilos", "lb", "lbs", "pounds", "slim", "slimming", "skinny", "thinner",
    "eat less", "eating less", "ate less", "fewer calories", "deficit", "calories burned", "burn calories", "starve",
  ],
  ar: [
    "انقاص الوزن", "خساره الوزن", "فقدان الوزن", "نزول الوزن", "خسرت", "تخسيس", "رجيم", "نحافه", "نحيف",
    "كيلو", "كغ", "كجم", "اكل اقل", "تناول اقل", "عجز السعرات", "عجز حراري", "السعرات المحروقه", "حرق السعرات", "حرق الدهون",
  ],
  es: [
    "perder peso", "perdida de peso", "bajar de peso", "bajar peso", "adelgazar", "adelgaza", "adelgazaste",
    "kg", "kilo", "kilos", "delgado", "delgada", "comer menos", "come menos", "comiste menos",
    "deficit", "calorias quemadas", "quemar calorias", "quemar grasa", "perder grasa",
  ],
};

// Exercise ids from lib/data/templates.dart and the built-in templates that use them.
const UL = "Upper / Lower", PPL = "Push Pull Legs", FB = "Full body";
export const BUILT_IN_TEMPLATE_EXERCISES: ReadonlyMap<string, string[]> = new Map([
  ["Barbell_Bench_Press_-_Medium_Grip", [UL, PPL, FB]],
  ["Incline_Dumbbell_Press", [UL, PPL, FB]],
  ["Standing_Military_Press", [UL, PPL, FB]],
  ["Side_Lateral_Raise", [UL, PPL, FB]],
  ["Triceps_Pushdown", [UL, PPL, FB]],
  ["Weighted_Pull_Ups", [UL, PPL, FB]],
  ["Bent_Over_Barbell_Row", [UL, PPL, FB]],
  ["Seated_Cable_Rows", [UL, PPL, FB]],
  ["Wide-Grip_Lat_Pulldown", [UL, PPL]],
  ["Face_Pull", [PPL]],
  ["Incline_Dumbbell_Curl", [UL, PPL, FB]],
  ["Hammer_Curls", [PPL]],
  ["Barbell_Squat", [UL, PPL, FB]],
  ["Romanian_Deadlift", [UL, PPL, FB]],
  ["Leg_Press", [UL, PPL, FB]],
  ["Seated_Leg_Curl", [UL, PPL]],
  ["Leg_Extensions", [UL]],
  ["Standing_Calf_Raises", [UL, PPL]],
  ["Barbell_Hip_Thrust", [UL, PPL]],
  ["Dumbbell_Bench_Press", [PPL]],
  ["Dumbbell_Shoulder_Press", [UL]],
]);

const LISTS: Record<PackKind, string> = {
  foods: "items", vocabulary: "units", eating_out: "dishes", exercises: "items",
  templates: "items", awards: "items", challenges: "items", copy: "overrides",
};

export function emptyPack(kind?: string): Record<string, unknown> {
  if (kind === "copy") return { overrides: {} };
  return { [LISTS[kind as PackKind] ?? "items"]: [] };
}

/** How many things a pack holds, for the dashboard's overview. */
export function summarize(kind: string, body: unknown): number {
  const v = (body as Record<string, unknown> | null)?.[LISTS[kind as PackKind] ?? "items"];
  if (Array.isArray(v)) return v.length;
  return v && typeof v === "object" ? Object.keys(v).length : 0;
}

// Checking ----------------------------------------------------------------------

const MAX_ITEMS = 500;
const ID = /^[a-z0-9_]{1,40}$/;
const EXERCISE_ID = /^[A-Za-z0-9_\-()]{1,80}$/;

type Obj = Record<string, any>;
const isObj = (v: unknown): v is Obj => v !== null && typeof v === "object" && !Array.isArray(v);

class Checker {
  errors: PackIssue[] = [];
  warnings: PackIssue[] = [];

  err(key: string, message: string) {
    this.errors.push({ key, message });
  }

  /** A list of at most 500 objects; anything else in it is an error. */
  list(src: Obj, field: string, prefix = ""): Obj[] {
    const key = `${prefix}${field}`;
    const v = src[field];
    if (v == null) return [];
    if (!Array.isArray(v)) {
      this.err(key, "Must be a list");
      return [];
    }
    if (v.length > MAX_ITEMS) this.err(key, `At most ${MAX_ITEMS} items`);
    return v.slice(0, MAX_ITEMS).map((x, i) => {
      if (!isObj(x)) this.err(`${key}.${i}`, "Must be an entry");
      return isObj(x) ? x : {};
    });
  }

  t3(v: unknown, key: string, max = 240) {
    const out: Record<string, string> = {};
    for (const l of LANGS) {
      const s = isObj(v) ? v[l] : undefined;
      if (typeof s !== "string" || !s.trim()) this.err(`${key}.${l}`, "Needed in English, Arabic and Spanish");
      else if (s.trim().length > max) this.err(`${key}.${l}`, `Keep it under ${max} characters`);
      out[l] = typeof s === "string" ? s.trim() : "";
    }
    return out;
  }

  num(v: unknown, key: string, min: number, max: number, int = false) {
    if (typeof v !== "number" || !Number.isFinite(v) || (int && !Number.isInteger(v))) {
      this.err(key, int ? "Must be a whole number" : "Must be a number");
    } else if (v < min || v > max) this.err(key, `Must be between ${min} and ${max}`);
    return v as number;
  }

  oneOf(v: unknown, key: string, options: readonly string[]) {
    if (!options.includes(v as string)) this.err(key, `Must be one of ${options.join(", ")}`);
    return v as string;
  }

  id(v: unknown, key: string, seen: Set<string>, pattern = ID) {
    if (typeof v !== "string" || !pattern.test(v)) {
      this.err(key, pattern === ID ? "Use lowercase letters, digits and _ (up to 40)" : "Use letters, digits, _ - ( ) (up to 80)");
    } else if (seen.has(v)) this.err(key, `Used twice: ${v}`);
    else seen.add(v);
    return v as string;
  }

  strings(v: unknown, key: string, max: number) {
    if (!Array.isArray(v)) {
      this.err(key, "Must be a list");
      return [];
    }
    return v.slice(0, 50).map((s, i) => {
      if (typeof s !== "string" || !s.trim()) this.err(`${key}.${i}`, "Can't be empty");
      else if (s.length > max) this.err(`${key}.${i}`, `Keep it under ${max} characters`);
      return typeof s === "string" ? s.trim() : "";
    });
  }
}

const fold = (s: string) => s.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
const foldAr = (s: string) => s.replace(/[ً-ْـ]/g, "").replace(/[أإآ]/g, "ا").replace(/ة/g, "ه").replace(/ى/g, "ي");
const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const blocked = Object.fromEntries(LANGS.map((l) => [l, l === "ar"
  ? AWARD_BLOCKED_WORDS.ar.map(foldAr)
  : AWARD_BLOCKED_WORDS[l].map((w) => new RegExp(`(?<![\\p{L}\\p{N}])${escape(fold(w))}(?![\\p{L}\\p{N}])`, "u"))]));

function rewardsWeightLoss(lang: "en" | "ar" | "es", text: string) {
  if (lang === "ar") return (blocked.ar as string[]).some((w) => foldAr(text).includes(w));
  return (blocked[lang] as RegExp[]).some((re) => re.test(fold(text)));
}

const AWARD_RULE = "Awards can’t reward weight loss or eating less. Try showing up instead: “Logged 30 days” or “Trained 12 times this month”.";

const plural = (n: number) => `${n} template${n === 1 ? "" : "s"}`;

const kinds: Record<PackKind, (src: Obj, c: Checker, ctx: PackContext) => Obj> = {
  foods(src, c) {
    const seen = new Set<string>();
    return {
      items: c.list(src, "items").map((x, i) => {
        const k = `items.${i}`;
        const out: Obj = {
          id: c.id(x.id, `${k}.id`, seen),
          name: c.t3(x.name, `${k}.name`, 80),
          kcal: c.num(x.kcal, `${k}.kcal`, 0, 900),
          protein: c.num(x.protein, `${k}.protein`, 0, 100),
          carbs: c.num(x.carbs, `${k}.carbs`, 0, 100),
          fat: c.num(x.fat, `${k}.fat`, 0, 100),
        };
        if (x.serving_g != null) out.serving_g = c.num(x.serving_g, `${k}.serving_g`, 1, 2000);
        const [p, cb, f, kcal] = [out.protein, out.carbs, out.fat, out.kcal];
        if ([p, cb, f, kcal].every((n) => typeof n === "number" && Number.isFinite(n))) {
          if (p + cb + f > 100) c.err(k, "Protein, carbs and fat add up to more than 100 g per 100 g");
          // Labels round, so only a clear mismatch is worth a second look.
          const fromMacros = 4 * p + 4 * cb + 9 * f;
          const off = Math.abs(fromMacros - kcal);
          if (off > 0.25 * kcal && off > 20) {
            c.warnings.push({ key: `${k}.kcal`, message: `${out.name.en || out.id}: macros add up to ${Math.round(fromMacros)} kcal, but kcal says ${kcal} per 100 g. Check the numbers.` });
          }
        }
        return out;
      }),
    };
  },

  vocabulary(src, c) {
    const seen = new Set<string>();
    return {
      units: c.list(src, "units").map((x, i) => {
        const k = `units.${i}`;
        const word = typeof x.word === "string" ? x.word.trim() : "";
        if (!word || word.length > 30) c.err(`${k}.word`, "Use 1 to 30 characters");
        const lang = c.oneOf(x.lang, `${k}.lang`, LANGS);
        const unit = c.oneOf(x.unit, `${k}.unit`, UNITS);
        const pair = `${word.toLowerCase()}|${lang}`;
        if (word && seen.has(pair)) c.err(`${k}.word`, `Used twice: ${word}`);
        seen.add(pair);
        return { word, lang, unit };
      }),
    };
  },

  eating_out(src, c) {
    const seen = new Set<string>();
    return {
      dishes: c.list(src, "dishes").map((x, i) => {
        const k = `dishes.${i}`;
        return {
          id: c.id(x.id, `${k}.id`, seen),
          group: c.oneOf(x.group, `${k}.group`, ["main", "side"]),
          name: c.t3(x.name, `${k}.name`, 80),
          g: c.num(x.g, `${k}.g`, 1, 2000),
          kcal: c.num(x.kcal, `${k}.kcal`, 0, 3000),
          p: c.num(x.p, `${k}.p`, 0, 300),
          c: c.num(x.c, `${k}.c`, 0, 300),
          f: c.num(x.f, `${k}.f`, 0, 300),
        };
      }),
    };
  },

  exercises(src, c, ctx) {
    const seen = new Set<string>();
    const muscles = (v: unknown, key: string) => {
      if (!Array.isArray(v)) {
        if (v != null) c.err(key, "Must be a list");
        return [];
      }
      v.forEach((m, j) => c.oneOf(m, `${key}.${j}`, MUSCLES));
      return [...v];
    };
    const items = c.list(src, "items").map((x, i) => {
      const k = `items.${i}`;
      const out: Obj = {
        id: c.id(x.id, `${k}.id`, seen, EXERCISE_ID),
        name: c.t3(x.name, `${k}.name`, 80),
        primary: muscles(x.primary, `${k}.primary`),
        secondary: muscles(x.secondary, `${k}.secondary`),
      };
      if (!out.primary.length) c.err(`${k}.primary`, "Pick at least one muscle");
      if (x.equipment != null) {
        if (typeof x.equipment !== "string" || !x.equipment.trim() || x.equipment.length > 80) c.err(`${k}.equipment`, "Use 1 to 80 characters");
        out.equipment = typeof x.equipment === "string" ? x.equipment.trim() : x.equipment;
      }
      if (x.level != null) out.level = c.oneOf(x.level, `${k}.level`, ["beginner", "intermediate", "expert"]);
      if (x.images != null) out.images = c.strings(x.images, `${k}.images`, 200);
      if (x.instructions != null) out.instructions = c.strings(x.instructions, `${k}.instructions`, 1000);
      return out;
    });
    const out: Obj = { items };
    if (src.removed != null) {
      if (!Array.isArray(src.removed)) c.err("removed", "Must be a list");
      // Past workouts keep showing a removed exercise; new ones just can't pick it.
      const uses = (id: string) => new Set([...(BUILT_IN_TEMPLATE_EXERCISES.get(id) ?? []), ...(ctx.templateExercises?.get(id) ?? [])]).size;
      const gone = new Set<string>();
      out.removed = (Array.isArray(src.removed) ? src.removed.slice(0, MAX_ITEMS) : []).map((id: unknown, i: number) => {
        c.id(id, `removed.${i}`, gone, EXERCISE_ID);
        const n = typeof id === "string" ? uses(id) : 0;
        if (n) c.err(`removed.${i}`, `Removes “${id}”, used in ${plural(n)}`);
        return id;
      });
    }
    return out;
  },

  templates(src, c, ctx) {
    const seen = new Set<string>();
    return {
      items: c.list(src, "items").map((x, i) => {
        const k = `items.${i}`;
        const routines = c.list(x, "routines", `${k}.`);
        if (routines.length < 1 || routines.length > 7) c.err(`${k}.routines`, "Use 1 to 7 routines");
        return {
          id: c.id(x.id, `${k}.id`, seen),
          name: c.t3(x.name, `${k}.name`, 80),
          level: c.oneOf(x.level, `${k}.level`, ["beginner", "intermediate", "expert"]),
          routines: routines.slice(0, 7).map((r, j) => {
            const rk = `${k}.routines.${j}`;
            const items = c.list(r, "items", `${rk}.`);
            if (items.length < 1 || items.length > 15) c.err(`${rk}.items`, "Use 1 to 15 exercises");
            return {
              name: c.t3(r.name, `${rk}.name`, 80),
              weekday: c.num(r.weekday, `${rk}.weekday`, 0, 6, true),
              items: items.slice(0, 15).map((e, n) => {
                const ek = `${rk}.items.${n}`;
                if (typeof e.exercise !== "string" || !EXERCISE_ID.test(e.exercise)) c.err(`${ek}.exercise`, "Pick an exercise");
                else if (ctx.removedExercises?.has(e.exercise)) c.err(`${ek}.exercise`, `“${e.exercise}” is removed by the published exercises pack`);
                const low = c.num(e.rep_low, `${ek}.rep_low`, 1, 50, true);
                const out: Obj = {
                  exercise: e.exercise,
                  sets: c.num(e.sets, `${ek}.sets`, 1, 10, true),
                  rep_low: low,
                  rep_high: c.num(e.rep_high, `${ek}.rep_high`, Number.isInteger(low) && low >= 1 && low <= 50 ? low : 1, 50, true),
                  rest_s: c.num(e.rest_s, `${ek}.rest_s`, 0, 600, true),
                };
                if (e.rir != null) out.rir = c.num(e.rir, `${ek}.rir`, 0, 5, true);
                return out;
              }),
            };
          }),
        };
      }),
    };
  },

  awards(src, c) {
    const seen = new Set<string>();
    return {
      items: c.list(src, "items").map((x, i) => {
        const k = `items.${i}`;
        const out = {
          id: c.id(x.id, `${k}.id`, seen),
          name: c.t3(x.name, `${k}.name`, 80),
          description: c.t3(x.description, `${k}.description`),
          metric: c.oneOf(x.metric, `${k}.metric`, ["logged_days", "workouts", "streak_days"]),
          threshold: c.num(x.threshold, `${k}.threshold`, 1, 1000, true),
        };
        // Awards reward showing up, never weight loss or eating less.
        for (const field of ["name", "description"] as const) {
          for (const l of LANGS) if (rewardsWeightLoss(l, out[field][l])) c.err(`${k}.${field}.${l}`, AWARD_RULE);
        }
        return out;
      }),
    };
  },

  challenges(src, c) {
    const seen = new Set<string>();
    return {
      items: c.list(src, "items").map((x, i) => {
        const k = `items.${i}`;
        if (typeof x.month !== "string" || !/^\d{4}-(0[1-9]|1[0-2])$/.test(x.month)) c.err(`${k}.month`, "Use YYYY-MM");
        else if (seen.has(x.month)) c.err(`${k}.month`, `One challenge per month: ${x.month} is used twice`);
        else seen.add(x.month);
        return {
          month: x.month,
          title: c.t3(x.title, `${k}.title`, 80),
          target: c.num(x.target, `${k}.target`, 4, 31, true),
        };
      }),
    };
  },

  copy(src, c) {
    const overrides: Obj = {};
    const v = src.overrides;
    if (v != null && !isObj(v)) c.err("overrides", "Must be a set of texts");
    for (const [key, text] of Object.entries(isObj(v) ? v : {})) {
      if (!(COPY_KEYS as readonly string[]).includes(key)) c.err(`overrides.${key}`, "Unknown text key");
      else overrides[key] = c.t3(text, `overrides.${key}`);
    }
    return { overrides };
  },
};

/** Normalise [body] for [kind], keeping only known fields; errors block publishing, warnings don't. */
export function validatePack(kind: string, body: unknown, ctx: PackContext = {}): { ok: boolean; body: unknown; errors: PackIssue[]; warnings: PackIssue[] } {
  if (!(PACK_KINDS as readonly string[]).includes(kind)) {
    return { ok: false, body: null, errors: [{ key: "kind", message: "Unknown pack kind" }], warnings: [] };
  }
  const c = new Checker();
  const out = kinds[kind as PackKind](isObj(body) ? body : {}, c, ctx);
  return { ok: c.errors.length === 0, body: out, errors: c.errors, warnings: c.warnings };
}
