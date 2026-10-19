// Pure helpers for the Content page: one field description per pack kind
// (it drives the one form renderer), the contract's checks mirrored so
// mistakes show while typing, and the names and summaries the table shows.
// The server's packs.check stays the authority; these only show it sooner.
// Contract: docs/superpowers/plans/2026-10-19-content-packs.md.

export const KINDS = [
  { id: "foods", label: "Foods", list: "items", noun: "food" },
  { id: "vocabulary", label: "Write parser", list: "units", noun: "unit word" },
  { id: "eating_out", label: "Eating out", list: "dishes", noun: "dish" },
  { id: "exercises", label: "Exercises", list: "items", noun: "exercise" },
  { id: "templates", label: "Routine templates", list: "items", noun: "template" },
  { id: "awards", label: "Awards", list: "items", noun: "award" },
  { id: "challenges", label: "Monthly challenges", list: "items", noun: "challenge" },
  { id: "copy", label: "Onboarding & copy", list: null, noun: "text" },
];

export const kindOf = (id) => KINDS.find((k) => k.id === id) ?? KINDS[0];

export const LANG_NAME = { en: "English", ar: "Arabic", es: "Spanish" };
export const MUSCLES = ["chest", "shoulders", "triceps", "biceps", "forearms", "lats", "middle back", "lower back", "traps", "abdominals", "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors", "neck"];
export const LEVELS = ["beginner", "intermediate", "expert"];
export const UNITS = ["piece", "scoop", "slice", "tbsp", "tsp", "cup", "handful", "bowl"];
export const METRICS = ["logged_days", "workouts", "streak_days"];
export const METRIC_LABEL = { logged_days: "Days logged", workouts: "Workouts finished", streak_days: "Best streak (days)" };
export const WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
const EQUIPMENT = ["barbell", "dumbbell", "cable", "machine", "kettlebells", "bands", "body only", "e-z curl bar", "medicine ball", "exercise ball", "foam roll", "other"];

// The app's built-in English, shown as a hint next to each override.
export const COPY_KEYS = [
  ["emptyDayTitle", "A fresh day"],
  ["emptyDayBody", "Start with whatever you ate first. One meal is a good start."],
  ["obWelcomeBody", "Targets that adapt to what you actually eat and weigh. No guessing, no punishment."],
  ["welcomeBody", "Log food in seconds, train with a plan, and keep a streak worth protecting."],
  ["welcomeLogBody", "Write it, say it, snap a photo or scan the barcode. Gymco reads the meal and you confirm before it is added."],
  ["welcomeTrainBody", "Routines for your week, 870+ exercises with photos, a rest timer and last time’s numbers on every set."],
  ["welcomeProgressBody", "A trend weight that ignores daily noise, strength through your cut, and awards for showing up."],
  ["obTargetsBody", "An estimate, not a verdict. After two or three weeks of logging, Gymco replaces it with your measured expenditure."],
  ["remindMealBody", "Write it, say it or snap it — it takes a few seconds."],
  ["remindWorkoutBody", "Your plan has a session today. Ready when you are."],
].map(([key, en]) => ({ key, en }));

export const AWARD_RULE = "Awards can’t reward weight loss or eating less. Try showing up instead: “Logged 30 days” or “Trained 12 times this month”.";

// A short copy of the server's blocked words, to flag the obvious ones early.
const AWARD_HINT_WORDS = {
  en: ["weight loss", "lose weight", "lost weight", "lose ", "lost ", "fat loss", "burn fat", "slim", "skinny", "eat less", "ate less", "calorie deficit", "skip meal", "fasting"],
  ar: ["خسارة الوزن", "فقدان الوزن", "نزول الوزن", "إنقاص الوزن", "انقاص الوزن", "تخسيس", "رجيم", "حرق الدهون", "خسرت", "أكل أقل"],
  es: ["perder peso", "pérdida de peso", "bajar de peso", "adelgaz", "perdiste", "comer menos", "quemar grasa", "dieta"],
};

const ID = /^[a-z0-9_]{1,40}$/;
const EXERCISE_ID = /^[A-Za-z0-9_\-()]{1,80}$/;
const MONTH = /^\d{4}-(0[1-9]|1[0-2])$/;
const MAX_ITEMS = 500;

const t3 = (key, label, max = 240, extra = {}) => ({ key, label, type: "t3", max, ...extra });
const num = (key, label, min, max, extra = {}) => ({ key, label, type: "num", min, max, ...extra });
const int = (key, label, min, max, extra = {}) => ({ key, label, type: "int", min, max, ...extra });
const one = (key, label, options, extra = {}) => ({ key, label, type: "enum", options, ...extra });

const ROUTINE_ITEM = [
  { key: "exercise", label: "Exercise ID", type: "text", max: 80, pattern: EXERCISE_ID, mono: true },
  int("sets", "Sets", 1, 10), int("rep_low", "Reps from", 1, 50), int("rep_high", "Reps to", 1, 50),
  int("rest_s", "Rest (s)", 0, 600), int("rir", "RIR", 0, 5, { optional: true }),
];

/** What each item is made of, in the order the editor shows it. */
export const FIELDS = {
  foods: [
    { key: "id", label: "ID", type: "id" }, t3("name", "Name", 80),
    num("kcal", "kcal / 100 g", 0, 900), num("protein", "Protein g", 0, 100), num("carbs", "Carbs g", 0, 100), num("fat", "Fat g", 0, 100),
    num("serving_g", "Serving g", 1, 2000, { optional: true }),
  ],
  vocabulary: [
    { key: "word", label: "Word", type: "text", max: 30, dirFrom: "lang" },
    one("lang", "Language", ["en", "ar", "es"], { labels: LANG_NAME }), one("unit", "Means", UNITS),
  ],
  eating_out: [
    { key: "id", label: "ID", type: "id" }, one("group", "Group", ["main", "side"], { labels: { main: "Main", side: "Side" } }), t3("name", "Name", 80),
    num("g", "Portion g", 1, 2000), num("kcal", "kcal", 0, 3000), num("p", "Protein g", 0, 300), num("c", "Carbs g", 0, 300), num("f", "Fat g", 0, 300),
  ],
  exercises: [
    { key: "id", label: "ID (free-exercise-db)", type: "text", max: 80, pattern: EXERCISE_ID, mono: true }, t3("name", "Name", 80),
    { key: "primary", label: "Main muscles", type: "multi", options: MUSCLES, min: 1 },
    { key: "secondary", label: "Helper muscles", type: "multi", options: MUSCLES },
    { key: "equipment", label: "Equipment", type: "text", max: 40, optional: true, suggest: EQUIPMENT },
    one("level", "Level", LEVELS, { optional: true }),
    { key: "images", label: "Photo paths (one per line)", type: "lines", optional: true, mono: true },
    { key: "instructions", label: "Instructions (one step per line)", type: "lines", optional: true },
  ],
  templates: [
    { key: "id", label: "ID", type: "id" }, t3("name", "Name", 80), one("level", "Level", LEVELS),
    {
      key: "routines", label: "Routines", type: "rows", min: 1, max: 7, noun: "routine",
      blank: () => ({ name: blankT3(), weekday: 0, items: [blankRoutineItem()] }),
      fields: [
        t3("name", "Routine name", 80), one("weekday", "Day", [0, 1, 2, 3, 4, 5, 6], { labels: WEEKDAYS, number: true }),
        { key: "items", label: "Exercises", type: "rows", min: 1, max: 15, noun: "exercise", blank: () => blankRoutineItem(), fields: ROUTINE_ITEM, compact: true },
      ],
    },
  ],
  awards: [
    { key: "id", label: "ID", type: "id" }, t3("name", "Award name", 80), t3("description", "Description", 240, { multiline: true }),
    one("metric", "Earned by", METRICS, { labels: METRIC_LABEL }), int("threshold", "Threshold", 1, 1000),
  ],
  challenges: [
    { key: "month", label: "Month", type: "month" }, t3("title", "Title", 80), int("target", "Target (times)", 4, 31),
  ],
};

const blankT3 = () => ({ en: "", ar: "", es: "" });
const blankRoutineItem = () => ({ exercise: "", sets: 3, rep_low: 8, rep_high: 12, rest_s: 90 });

export const getList = (kind, body) => {
  const k = kindOf(kind).list;
  return k ? (Array.isArray(body?.[k]) ? body[k] : []) : [];
};
export const setList = (kind, body, list) => ({ ...body, [kindOf(kind).list]: list });

const blank = (v) => v == null || v === "";
const isT3 = (v) => v && typeof v === "object" && !Array.isArray(v);

/** Problems with one value; pushes {key, message} onto [out]. */
function checkValue(spec, v, key, out) {
  const say = (message, k = key) => out.push({ key: k, message });
  if (spec.optional && (blank(v) || (Array.isArray(v) && !v.length))) return;
  switch (spec.type) {
    case "id":
      if (typeof v !== "string" || !ID.test(v)) say("Use 1–40 lowercase letters, digits or _");
      return;
    case "text":
      if (typeof v !== "string" || !v.trim()) return say(`${spec.label} is needed`);
      if (v.length > spec.max) return say(`At most ${spec.max} characters`);
      if (spec.pattern && !spec.pattern.test(v)) say("Use letters, digits, _ - ( ) only");
      return;
    case "t3":
      if (!isT3(v)) return say(`${spec.label} is needed in English, Arabic and Spanish`);
      for (const l of ["en", "ar", "es"]) {
        const s = typeof v[l] === "string" ? v[l] : "";
        if (!s.trim()) say(`Add the ${LANG_NAME[l]} ${spec.label.toLowerCase()}`, `${key}.${l}`);
        else if (s.length > spec.max) say(`${LANG_NAME[l]} is over ${spec.max} characters`, `${key}.${l}`);
      }
      return;
    case "num":
    case "int":
      if (typeof v !== "number" || !Number.isFinite(v)) return say(spec.type === "int" ? "Must be a whole number" : "Must be a number");
      if (spec.type === "int" && !Number.isInteger(v)) return say("Must be a whole number");
      if (v < spec.min || v > spec.max) say(`Must be between ${spec.min} and ${spec.max}`);
      return;
    case "enum":
      if (!spec.options.includes(v)) say(`Pick one of ${spec.options.join(", ")}`);
      return;
    case "multi":
      if (!Array.isArray(v)) return say("Must be a list");
      if (spec.min && v.length < spec.min) return say("Pick at least one");
      if (v.some((m) => !spec.options.includes(m))) say(`Unknown: ${v.filter((m) => !spec.options.includes(m)).join(", ")}`);
      return;
    case "month":
      if (typeof v !== "string" || !MONTH.test(v)) say("Use YYYY-MM, like 2026-11");
      return;
    case "lines":
      if (!Array.isArray(v) || v.some((s) => typeof s !== "string" || !s.trim())) say("One non-empty line each");
      return;
    case "rows":
      if (!Array.isArray(v)) return say("Must be a list");
      if (v.length < spec.min || v.length > spec.max) say(`Needs ${spec.min}–${spec.max} ${spec.noun}s`);
      v.forEach((row, i) => checkFields(spec.fields, row, `${key}.${i}`, out));
      return;
  }
}

function checkFields(fields, obj, prefix, out) {
  for (const f of fields) checkValue(f, obj?.[f.key], `${prefix}.${f.key}`, out);
  // Rep ranges run upwards.
  if (obj && typeof obj.rep_low === "number" && typeof obj.rep_high === "number" && obj.rep_high < obj.rep_low) {
    out.push({ key: `${prefix}.rep_high`, message: `Must be at least ${obj.rep_low}` });
  }
}

const words = (s) => String(s ?? "").toLowerCase();
const blockedIn = (t) => ["en", "ar", "es"].some((l) => AWARD_HINT_WORDS[l].some((w) => `${words(t?.[l])} `.includes(w)));

/** The contract's checks for a whole body: {errors, warnings}. */
export function checkBody(kind, body) {
  const errors = [];
  const warnings = [];
  if (kind === "copy") {
    const o = body?.overrides ?? {};
    const known = new Set(COPY_KEYS.map((c) => c.key));
    for (const [k, v] of Object.entries(o)) {
      if (!known.has(k)) errors.push({ key: `overrides.${k}`, message: "Not a text the app knows" });
      else checkValue(t3(k, "text"), v, `overrides.${k}`, errors);
    }
    return { errors, warnings };
  }
  const { list } = kindOf(kind);
  const items = body?.[list];
  if (!Array.isArray(items)) return { errors: [{ key: list, message: "Must be a list" }], warnings };
  if (items.length > MAX_ITEMS) errors.push({ key: list, message: `At most ${MAX_ITEMS} items` });
  const seen = new Set();
  items.forEach((it, i) => {
    const p = `${list}.${i}`;
    checkFields(FIELDS[kind], it, p, errors);
    const dupKey = kind === "vocabulary" ? `${words(it?.word).trim()}|${it?.lang}` : kind === "challenges" ? it?.month : it?.id;
    const dupField = kind === "vocabulary" ? "word" : kind === "challenges" ? "month" : "id";
    if (dupKey != null && seen.has(dupKey)) errors.push({ key: `${p}.${dupField}`, message: kind === "challenges" ? "One challenge per month" : "Already used in this pack" });
    seen.add(dupKey);
    if (kind === "foods" && [it.protein, it.carbs, it.fat].every((n) => typeof n === "number")) {
      if (it.protein + it.carbs + it.fat > 100) errors.push({ key: p, message: "Protein, carbs and fat add up to more than 100 g per 100 g" });
      const calc = Math.round(4 * it.protein + 4 * it.carbs + 9 * it.fat);
      const off = Math.abs(calc - it.kcal);
      if (typeof it.kcal === "number" && off > 20 && off > 0.25 * it.kcal) {
        warnings.push({ key: p, message: `${itemTitle(kind, it)}: macros add up to ${calc} kcal, but kcal says ${it.kcal} per 100 g. Check the numbers.` });
      }
    }
    if (kind === "awards") {
      for (const f of ["name", "description"]) if (blockedIn(it?.[f])) errors.push({ key: `${p}.${f}`, message: AWARD_RULE });
    }
  });
  if (kind === "exercises" && body.removed != null) {
    if (!Array.isArray(body.removed)) errors.push({ key: "removed", message: "Must be a list" });
    else body.removed.forEach((id, i) => typeof id === "string" && EXERCISE_ID.test(id) || errors.push({ key: `removed.${i}`, message: "Not an exercise ID" }));
  }
  return { errors, warnings };
}

/** The item an error key points at (items.3.name.es → 3), or null. */
export function itemIndex(key) {
  const m = /^(items|units|dishes)\.(\d+)(\.|$)/.exec(key);
  return m ? Number(m[2]) : null;
}

/** Client and server findings together; the server's wording wins on a shared key. */
export function mergeChecks(client = [], server = []) {
  const byKey = new Map();
  for (const e of client) byKey.set(e.key, e);
  for (const e of server) byKey.set(e.key, e);
  return [...byKey.values()];
}

const MISSING = /missing|add the|needed|required|empty/i;

/** Lines for the checks card: grouped missing languages, then other errors, then warnings. */
export function checkLines(errors, warnings) {
  const lines = [];
  const missing = new Map();
  const rest = [];
  for (const e of errors) {
    const lang = /\.(en|ar|es)$/.exec(e.key)?.[1];
    if (lang && MISSING.test(e.message)) {
      if (!missing.has(lang)) missing.set(lang, { items: new Set(), key: e.key });
      missing.get(lang).items.add(e.key.split(".").slice(0, 2).join("."));
    } else rest.push(e);
  }
  for (const [lang, { items, key }] of missing) {
    const n = items.size;
    lines.push({ tone: "bad", title: `${n} item${n === 1 ? "" : "s"} missing ${LANG_NAME[lang]}`, note: "Every text needs EN, AR and ES before this pack can publish.", key });
  }
  for (const e of rest.slice(0, 6)) lines.push({ tone: "bad", title: e.message, note: e.key, key: e.key });
  if (rest.length > 6) lines.push({ tone: "bad", title: `${rest.length - 6} more errors`, note: "Fix the ones above first; the list updates as you go." });
  if (!errors.length) lines.push({ tone: "good", title: "Ready to publish", note: "Phones check the pack’s checksum after download and keep the old one if it doesn’t match." });
  for (const w of warnings) lines.push({ tone: "warn", title: w.message, note: "Doesn’t block publishing", key: w.key });
  return lines;
}

const cap = (s) => (s ? s[0].toUpperCase() + s.slice(1) : s);

export function itemTitle(kind, it) {
  const t = it?.name?.en?.trim() || it?.title?.en?.trim();
  return t || it?.word || it?.id || it?.month || "Untitled";
}

export function itemSub(kind, it) {
  switch (kind) {
    case "foods": return `${it.kcal} kcal · P ${it.protein} · C ${it.carbs} · F ${it.fat} per 100 g`;
    case "vocabulary": return `${LANG_NAME[it.lang] ?? it.lang} · ${it.unit}`;
    case "eating_out": return `${it.group === "side" ? "Side" : "Main"} · ${it.g} g · ${it.kcal} kcal`;
    case "exercises": return [cap((it.primary ?? []).join(", ")) || "No main muscle", it.level].filter(Boolean).join(" · ");
    case "templates": return `${(it.routines ?? []).length} routine${(it.routines ?? []).length === 1 ? "" : "s"} · ${it.level}`;
    case "awards": return `${METRIC_LABEL[it.metric] ?? it.metric} · ${it.threshold}`;
    case "challenges": return `${it.month} · train ${it.target} times`;
    default: return "";
  }
}

const NEW_ID = { foods: "new_food", eating_out: "new_dish", exercises: "New_Exercise", templates: "new_template", awards: "new_award" };

function uniqueId(base, list) {
  const taken = new Set(list.map((x) => x.id));
  if (!taken.has(base)) return base;
  let n = 2;
  while (taken.has(`${base}_${n}`)) n++;
  return `${base}_${n}`;
}

function nextMonth(list) {
  const last = list.map((x) => x.month).filter((m) => MONTH.test(m ?? "")).sort().pop();
  const d = last ? new Date(`${last}-01T00:00:00Z`) : new Date();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + 1);
  return d.toISOString().slice(0, 7);
}

/** A fresh item for [kind], with an id that isn't taken yet. */
export function blankItem(kind, list = []) {
  const id = NEW_ID[kind] ? uniqueId(NEW_ID[kind], list) : undefined;
  switch (kind) {
    case "foods": return { id, name: blankT3(), kcal: 0, protein: 0, carbs: 0, fat: 0 };
    case "vocabulary": return { word: "", lang: "en", unit: "piece" };
    case "eating_out": return { id, group: "main", name: blankT3(), g: 300, kcal: 0, p: 0, c: 0, f: 0 };
    case "exercises": return { id, name: blankT3(), primary: [], secondary: [] };
    case "templates": return { id, name: blankT3(), level: "beginner", routines: [FIELDS.templates[3].blank()] };
    case "awards": return { id, name: blankT3(), description: blankT3(), metric: "workouts", threshold: 10 };
    case "challenges": return { month: nextMonth(list), title: blankT3(), target: 12 };
    default: return {};
  }
}

const itemKey = (kind, it) => (kind === "vocabulary" ? `${it.lang}:${it.word}` : kind === "challenges" ? it.month : it.id);

function mapDiff(a, b) {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  return [...keys].filter((k) => JSON.stringify(a[k]) !== JSON.stringify(b[k])).length;
}

/** Items added, removed or edited between two bodies of one kind. */
export function countItemChanges(kind, before, after) {
  if (kind === "copy") return mapDiff(before?.overrides ?? {}, after?.overrides ?? {});
  const index = (body) => Object.fromEntries(getList(kind, body).map((it, i) => [itemKey(kind, it) ?? `#${i}`, it]));
  let n = mapDiff(index(before), index(after));
  if (kind === "exercises") {
    const x = new Set(before?.removed ?? []);
    const y = new Set(after?.removed ?? []);
    n += [...x].filter((id) => !y.has(id)).length + [...y].filter((id) => !x.has(id)).length;
  }
  return n;
}

/** Which of the pack's unit words a typed meal uses. Plural -s / -es counts. */
export function matchUnits(text, units) {
  const tokens = String(text ?? "").match(/[\p{L}\p{M}]+|\d+(?:[.,]\d+)?/gu) ?? [];
  const byWord = new Map(units.filter((u) => u.word).map((u) => [words(u.word).trim(), u]));
  const found = [];
  const other = [];
  for (const tok of tokens) {
    const t = words(tok);
    const u = byWord.get(t) ?? byWord.get(t.replace(/es$/, "")) ?? byWord.get(t.replace(/s$/, ""));
    if (u) found.push({ token: tok, word: u.word, unit: u.unit, lang: u.lang });
    else other.push(tok);
  }
  // Words of more than one token, like "table spoon", match as a phrase.
  for (const u of units) {
    if (/\s/.test(u.word?.trim() ?? "") && words(text).includes(words(u.word).trim())) found.push({ token: u.word, word: u.word, unit: u.unit, lang: u.lang });
  }
  return { found, other };
}

/** Sets a week in a template, per routine and per exercise. */
export function weeklySets(tpl) {
  const routines = (tpl?.routines ?? []).map((r) => ({
    name: r.name?.en || "Untitled", weekday: r.weekday,
    sets: (r.items ?? []).reduce((a, it) => a + (Number(it.sets) || 0), 0), exercises: (r.items ?? []).length,
  }));
  const ex = new Map();
  (tpl?.routines ?? []).forEach((r, ri) => {
    for (const it of r.items ?? []) {
      const e = ex.get(it.exercise) ?? { exercise: it.exercise, sets: 0, in: new Set() };
      e.sets += Number(it.sets) || 0;
      e.in.add(ri);
      ex.set(it.exercise, e);
    }
  });
  return {
    total: routines.reduce((a, r) => a + r.sets, 0),
    routines,
    exercises: [...ex.values()].map((e) => ({ exercise: e.exercise, sets: e.sets, routines: e.in.size })),
  };
}

/** A body as {itemKey: item}, so a diff reads as labneh.kcal instead of one long array. */
export function keyedBody(kind, body) {
  if (kind === "copy") return { ...(body?.overrides ?? {}) };
  const out = Object.fromEntries(getList(kind, body).map((it, i) => [itemKey(kind, it) ?? `#${i}`, it]));
  if (kind === "exercises" && body?.removed) out.removed = body.removed;
  return out;
}
