import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import {
  AWARD_BLOCKED_WORDS,
  BUILT_IN_TEMPLATE_EXERCISES,
  canonicalJson,
  checksum,
  COPY_KEYS,
  emptyPack,
  PACK_KINDS,
  summarize,
  validatePack,
} from "./packs.ts";

const t3 = (en: string, ar = "ع", es = "e") => ({ en, ar, es });
const food = (over: Record<string, unknown> = {}) => ({ id: "labneh", name: t3("Labneh"), kcal: 160, protein: 6, carbs: 4, fat: 14, ...over });
const keys = (r: { errors: { key: string }[] }) => r.errors.map((e) => e.key);
const has = (r: { errors: { key: string }[] }, key: string) => keys(r).includes(key);

// Canonical JSON and checksum ------------------------------------------------

Deno.test("canonical JSON sorts keys recursively and has no whitespace", () => {
  assertEquals(canonicalJson({ b: 1, a: [{ z: "x", y: null }, 2.5], c: { e: true, d: "é" } }), '{"a":[{"y":null,"z":"x"},2.5],"b":1,"c":{"d":"é","e":true}}');
});

Deno.test("canonical JSON drops undefined fields like JSON.stringify", () => {
  assertEquals(canonicalJson({ a: undefined, b: 1 }), '{"b":1}');
});

Deno.test("checksum is the lowercase hex SHA-256 of the canonical JSON", async () => {
  // sha256("{}")
  assertEquals(await checksum({}), "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a");
  assertEquals(await checksum({ b: 1, a: 2 }), await checksum({ a: 2, b: 1 }));
});

// Kinds and helpers ------------------------------------------------------------

Deno.test("the kinds match the database check constraint", () => {
  assertEquals([...PACK_KINDS], ["foods", "vocabulary", "eating_out", "exercises", "templates", "awards", "challenges", "copy"]);
});

Deno.test("each kind has an empty base body that is valid", () => {
  for (const k of PACK_KINDS) assert(validatePack(k, emptyPack(k)).ok, k);
  assertEquals(emptyPack("foods"), { items: [] });
  assertEquals(emptyPack("vocabulary"), { units: [] });
  assertEquals(emptyPack("eating_out"), { dishes: [] });
  assertEquals(emptyPack("copy"), { overrides: {} });
});

Deno.test("summarize counts the items of a pack", () => {
  assertEquals(summarize("foods", { items: [food(), food({ id: "b" })] }), 2);
  assertEquals(summarize("vocabulary", { units: [{}] }), 1);
  assertEquals(summarize("eating_out", { dishes: [] }), 0);
  assertEquals(summarize("copy", { overrides: { emptyDayTitle: t3("a"), welcomeBody: t3("b") } }), 2);
  assertEquals(summarize("foods", null), 0);
});

Deno.test("built-in template exercises come from the app's three templates", () => {
  assertEquals(BUILT_IN_TEMPLATE_EXERCISES.get("Barbell_Hip_Thrust"), ["Upper / Lower", "Push Pull Legs"]);
  assertEquals(BUILT_IN_TEMPLATE_EXERCISES.get("Barbell_Bench_Press_-_Medium_Grip"), ["Upper / Lower", "Push Pull Legs", "Full body"]);
  assertEquals(BUILT_IN_TEMPLATE_EXERCISES.get("Face_Pull"), ["Push Pull Legs"]);
  assertEquals(BUILT_IN_TEMPLATE_EXERCISES.get("Dumbbell_Shoulder_Press"), ["Upper / Lower"]);
  assertEquals(BUILT_IN_TEMPLATE_EXERCISES.size, 21);
});

Deno.test("an unknown kind is an error", () => {
  const r = validatePack("recipes", {});
  assert(!r.ok);
  assertEquals(keys(r), ["kind"]);
});

// Common rules ----------------------------------------------------------------

Deno.test("text needs all three languages", () => {
  const r = validatePack("foods", { items: [food({ name: { en: "Labneh", ar: " ", es: undefined } })] });
  assert(!r.ok);
  assertEquals(keys(r), ["items.0.name.ar", "items.0.name.es"]);
  assertEquals(r.errors[0].message, "Needed in English, Arabic and Spanish");
});

Deno.test("names are at most 80 characters and other text at most 240", () => {
  assert(has(validatePack("foods", { items: [food({ name: t3("x".repeat(81)) })] }), "items.0.name.en"));
  assert(validatePack("foods", { items: [food({ name: t3("x".repeat(80)) })] }).ok);
  const award = (description: string) => ({ items: [{ id: "a", name: t3("Showed up"), description: t3(description), metric: "workouts", threshold: 5 }] });
  assert(validatePack("awards", award("x".repeat(240))).ok);
  assert(has(validatePack("awards", award("x".repeat(241))), "items.0.description.en"));
});

Deno.test("ids are lowercase letters, digits and underscores, up to 40", () => {
  for (const id of ["Labneh", "lab-neh", "", "x".repeat(41), 5]) assert(has(validatePack("foods", { items: [food({ id })] }), "items.0.id"), String(id));
  assert(validatePack("foods", { items: [food({ id: "lab_neh_2" })] }).ok);
});

Deno.test("ids are unique within a pack", () => {
  const r = validatePack("foods", { items: [food(), food()] });
  assertEquals(keys(r), ["items.1.id"]);
});

Deno.test("a list holds at most 500 items", () => {
  const items = Array.from({ length: 501 }, (_, i) => food({ id: `f${i}` }));
  const r = validatePack("foods", { items });
  assert(has(r, "items"));
  assert(validatePack("foods", { items: items.slice(0, 500) }).ok);
});

Deno.test("unknown fields are dropped from the body", () => {
  const r = validatePack("foods", { extra: 1, items: [food({ brand: "x", name: { ...t3("Labneh"), fr: "Labné" } })] });
  assert(r.ok);
  assertEquals(r.body, { items: [{ id: "labneh", name: t3("Labneh"), kcal: 160, protein: 6, carbs: 4, fat: 14 }] });
});

Deno.test("a non-object body is treated as empty", () => {
  const r = validatePack("foods", "nope");
  assert(r.ok);
  assertEquals(r.body, { items: [] });
});

// foods -----------------------------------------------------------------------

Deno.test("foods: kcal 0-900 and each macro 0-100", () => {
  assert(has(validatePack("foods", { items: [food({ kcal: 901 })] }), "items.0.kcal"));
  assert(has(validatePack("foods", { items: [food({ kcal: -1 })] }), "items.0.kcal"));
  assert(has(validatePack("foods", { items: [food({ kcal: "160" })] }), "items.0.kcal"));
  for (const m of ["protein", "carbs", "fat"]) {
    assert(has(validatePack("foods", { items: [food({ [m]: 101 })] }), `items.0.${m}`), m);
    assert(has(validatePack("foods", { items: [food({ [m]: -0.5 })] }), `items.0.${m}`), m);
  }
});

Deno.test("foods: macros together are at most 100 g per 100 g", () => {
  const r = validatePack("foods", { items: [food({ protein: 40, carbs: 40, fat: 21, kcal: 509 })] });
  assert(!r.ok);
  assertEquals(keys(r), ["items.0"]);
  assert(validatePack("foods", { items: [food({ protein: 40, carbs: 40, fat: 20, kcal: 500 })] }).ok);
});

Deno.test("foods: serving_g is optional and 1-2000", () => {
  assert(validatePack("foods", { items: [food({ serving_g: 30 })] }).ok);
  assertEquals((validatePack("foods", { items: [food({ serving_g: 30 })] }).body as any).items[0].serving_g, 30);
  assert(has(validatePack("foods", { items: [food({ serving_g: 0 })] }), "items.0.serving_g"));
  assert(has(validatePack("foods", { items: [food({ serving_g: 2001 })] }), "items.0.serving_g"));
});

Deno.test("foods: macros far from kcal are a warning, not an error", () => {
  // 4*10 + 4*10 + 9*14.67 = 212
  const r = validatePack("foods", { items: [food({ protein: 10, carbs: 10, fat: 14.67, kcal: 160 })] });
  assert(r.ok);
  assertEquals(r.warnings, [{ key: "items.0.kcal", message: "Labneh: macros add up to 212 kcal, but kcal says 160 per 100 g. Check the numbers." }]);
});

Deno.test("foods: small kcal differences are not warned about", () => {
  // 25% off but under 20 kcal: 4*5 = 20 vs 12.
  assertEquals(validatePack("foods", { items: [food({ protein: 5, carbs: 0, fat: 0, kcal: 12 })] }).warnings, []);
  // Over 20 kcal but within 25%: 4*6 + 4*4 + 9*14 = 166 vs 160.
  assertEquals(validatePack("foods", { items: [food()] }).warnings, []);
});

// vocabulary ------------------------------------------------------------------

const unit = (over: Record<string, unknown> = {}) => ({ word: "pinch", lang: "en", unit: "tsp", ...over });

Deno.test("vocabulary: word 1-30 characters, known language and unit", () => {
  assert(validatePack("vocabulary", { units: [unit()] }).ok);
  assert(has(validatePack("vocabulary", { units: [unit({ word: " " })] }), "units.0.word"));
  assert(has(validatePack("vocabulary", { units: [unit({ word: "x".repeat(31) })] }), "units.0.word"));
  assert(has(validatePack("vocabulary", { units: [unit({ lang: "fr" })] }), "units.0.lang"));
  assert(has(validatePack("vocabulary", { units: [unit({ unit: "litre" })] }), "units.0.unit"));
  for (const u of ["piece", "scoop", "slice", "tbsp", "tsp", "cup", "handful", "bowl"]) assert(validatePack("vocabulary", { units: [unit({ unit: u })] }).ok, u);
});

Deno.test("vocabulary: a word is unique per language", () => {
  assertEquals(keys(validatePack("vocabulary", { units: [unit(), unit({ word: "Pinch", unit: "cup" })] })), ["units.1.word"]);
  assert(validatePack("vocabulary", { units: [unit(), unit({ lang: "es" })] }).ok);
});

// eating_out ------------------------------------------------------------------

const dish = (over: Record<string, unknown> = {}) => ({ id: "shawarma", group: "main", name: t3("Shawarma"), g: 350, kcal: 650, p: 35, c: 60, f: 28, ...over });

Deno.test("eating_out: group, portion grams and macro ranges", () => {
  assert(validatePack("eating_out", { dishes: [dish()] }).ok);
  assert(has(validatePack("eating_out", { dishes: [dish({ group: "dessert" })] }), "dishes.0.group"));
  assert(has(validatePack("eating_out", { dishes: [dish({ g: 0 })] }), "dishes.0.g"));
  assert(has(validatePack("eating_out", { dishes: [dish({ g: 2001 })] }), "dishes.0.g"));
  assert(has(validatePack("eating_out", { dishes: [dish({ kcal: 3001 })] }), "dishes.0.kcal"));
  for (const m of ["p", "c", "f"]) assert(has(validatePack("eating_out", { dishes: [dish({ [m]: 301 })] }), `dishes.0.${m}`), m);
});

Deno.test("eating_out: ids are unique", () => {
  assertEquals(keys(validatePack("eating_out", { dishes: [dish(), dish({ group: "side" })] })), ["dishes.1.id"]);
});

// exercises -------------------------------------------------------------------

const ex = (over: Record<string, unknown> = {}) => ({ id: "Cable_Hip_Abduction", name: t3("Cable hip abduction"), primary: ["abductors"], secondary: [], ...over });

Deno.test("exercises: ids follow free-exercise-db", () => {
  assert(validatePack("exercises", { items: [ex({ id: "Barbell_Bench_Press_-_Medium_Grip" })] }).ok);
  assert(validatePack("exercises", { items: [ex({ id: "Push-Up_(Wide)" })] }).ok);
  assert(has(validatePack("exercises", { items: [ex({ id: "bad id" })] }), "items.0.id"));
  assert(has(validatePack("exercises", { items: [ex({ id: "x".repeat(81) })] }), "items.0.id"));
  assertEquals(keys(validatePack("exercises", { items: [ex(), ex()] })), ["items.1.id"]);
});

Deno.test("exercises: muscles from the list, at least one primary", () => {
  assert(has(validatePack("exercises", { items: [ex({ primary: [] })] }), "items.0.primary"));
  assert(has(validatePack("exercises", { items: [ex({ primary: ["wings"] })] }), "items.0.primary.0"));
  assert(has(validatePack("exercises", { items: [ex({ secondary: ["glutes", "tail"] })] }), "items.0.secondary.1"));
  assert(validatePack("exercises", { items: [ex({ primary: ["middle back"], secondary: ["lower back", "biceps"] })] }).ok);
});

Deno.test("exercises: level, equipment, images and instructions are optional", () => {
  const r = validatePack("exercises", { items: [ex({ level: "expert", equipment: "cable", images: ["Cable_Hip_Abduction/0.jpg"], instructions: ["Stand side on."] })] });
  assert(r.ok);
  assertEquals((r.body as any).items[0].level, "expert");
  assert(has(validatePack("exercises", { items: [ex({ level: "pro" })] }), "items.0.level"));
  assert(has(validatePack("exercises", { items: [ex({ images: [3] })] }), "items.0.images.0"));
  assert(has(validatePack("exercises", { items: [ex({ instructions: [""] })] }), "items.0.instructions.0"));
});

Deno.test("exercises: removing one a built-in template uses is an error", () => {
  const r = validatePack("exercises", { items: [], removed: ["Barbell_Hip_Thrust"] });
  assert(!r.ok);
  assertEquals(r.errors, [{ key: "removed.0", message: "Removes “Barbell_Hip_Thrust”, used in 2 templates" }]);
  assertEquals(validatePack("exercises", { items: [], removed: ["Face_Pull"] }).errors[0].message, "Removes “Face_Pull”, used in 1 template");
});

Deno.test("exercises: removing one the published templates pack uses is an error", () => {
  const templateExercises = new Map([["Cable_Crunch", ["Core starter"]], ["Face_Pull", ["Core starter"]]]);
  const r = validatePack("exercises", { items: [], removed: ["Cable_Crunch", "Face_Pull", "Sit_Up"] }, { templateExercises });
  assertEquals(r.errors, [
    { key: "removed.0", message: "Removes “Cable_Crunch”, used in 1 template" },
    { key: "removed.1", message: "Removes “Face_Pull”, used in 2 templates" },
  ]);
  assertEquals((r.body as any).removed, ["Cable_Crunch", "Face_Pull", "Sit_Up"]);
});

Deno.test("exercises: removing an unused exercise is fine", () => {
  const r = validatePack("exercises", { items: [], removed: ["Sit_Up"] });
  assert(r.ok);
  assertEquals(r.body, { items: [], removed: ["Sit_Up"] });
});

// templates -------------------------------------------------------------------

const item = (over: Record<string, unknown> = {}) => ({ exercise: "Face_Pull", sets: 3, rep_low: 8, rep_high: 12, rest_s: 90, ...over });
const routine = (over: Record<string, unknown> = {}) => ({ name: t3("Day A"), weekday: 0, items: [item()], ...over });
const tpl = (over: Record<string, unknown> = {}) => ({ items: [{ id: "starter", name: t3("Starter"), level: "beginner", routines: [routine()], ...over }] });
const tplItem = (over: Record<string, unknown>) => tpl({ routines: [routine({ items: [item(over)] })] });

Deno.test("templates: a valid template passes", () => {
  assert(validatePack("templates", tpl()).ok);
  assert(validatePack("templates", tplItem({ rir: 2 })).ok);
});

Deno.test("templates: level is required and known", () => {
  assert(has(validatePack("templates", tpl({ level: undefined })), "items.0.level"));
  assert(has(validatePack("templates", tpl({ level: "pro" })), "items.0.level"));
});

Deno.test("templates: 1-7 routines with 1-15 items each", () => {
  assert(has(validatePack("templates", tpl({ routines: [] })), "items.0.routines"));
  assert(has(validatePack("templates", tpl({ routines: Array.from({ length: 8 }, () => routine()) })), "items.0.routines"));
  assert(has(validatePack("templates", tpl({ routines: [routine({ items: [] })] })), "items.0.routines.0.items"));
  assert(has(validatePack("templates", tpl({ routines: [routine({ items: Array.from({ length: 16 }, () => item()) })] })), "items.0.routines.0.items"));
  assert(has(validatePack("templates", tpl({ routines: [routine({ name: t3("") })] })), "items.0.routines.0.name.en"));
});

Deno.test("templates: weekday 0-6 as a whole number", () => {
  assert(has(validatePack("templates", tpl({ routines: [routine({ weekday: 7 })] })), "items.0.routines.0.weekday"));
  assert(has(validatePack("templates", tpl({ routines: [routine({ weekday: 1.5 })] })), "items.0.routines.0.weekday"));
});

Deno.test("templates: sets, reps, rest and rir ranges", () => {
  const at = (f: string) => `items.0.routines.0.items.0.${f}`;
  for (const [over, field] of [
    [{ sets: 0 }, "sets"], [{ sets: 11 }, "sets"],
    [{ rep_low: 0 }, "rep_low"], [{ rep_low: 51, rep_high: 51 }, "rep_low"],
    [{ rep_high: 7 }, "rep_high"], [{ rep_high: 51 }, "rep_high"],
    [{ rest_s: -1 }, "rest_s"], [{ rest_s: 601 }, "rest_s"],
    [{ rir: 6 }, "rir"], [{ sets: 2.5 }, "sets"],
  ] as const) assert(has(validatePack("templates", tplItem(over)), at(field)), JSON.stringify(over));
  assert(validatePack("templates", tplItem({ rep_low: 8, rep_high: 8, rest_s: 0, rir: 0 })).ok);
});

Deno.test("templates: an exercise id must look like one", () => {
  assert(has(validatePack("templates", tplItem({ exercise: "" })), "items.0.routines.0.items.0.exercise"));
});

Deno.test("templates: using an exercise the exercises pack removes is an error", () => {
  const r = validatePack("templates", tpl(), { removedExercises: new Set(["Face_Pull"]) });
  assertEquals(r.errors, [{ key: "items.0.routines.0.items.0.exercise", message: "“Face_Pull” is removed by the published exercises pack" }]);
});

Deno.test("templates: ids are unique", () => {
  const one = tpl().items[0];
  assertEquals(keys(validatePack("templates", { items: [one, one] })), ["items.1.id"]);
});

// awards ----------------------------------------------------------------------

const award = (over: Record<string, unknown> = {}) => ({ items: [{ id: "regular", name: t3("Regular", "منتظم", "Constante"), description: t3("Logged 30 days", "سجلت 30 يومًا", "30 días registrados"), metric: "logged_days", threshold: 30, ...over }] });
const RULE = "Awards can’t reward weight loss or eating less. Try showing up instead: “Logged 30 days” or “Trained 12 times this month”.";

Deno.test("awards: metric and threshold", () => {
  assert(validatePack("awards", award()).ok);
  for (const m of ["logged_days", "workouts", "streak_days"]) assert(validatePack("awards", award({ metric: m })).ok, m);
  assert(has(validatePack("awards", award({ metric: "kg_lost" })), "items.0.metric"));
  assert(has(validatePack("awards", award({ threshold: 0 })), "items.0.threshold"));
  assert(has(validatePack("awards", award({ threshold: 1001 })), "items.0.threshold"));
  assert(has(validatePack("awards", award({ threshold: 2.5 })), "items.0.threshold"));
});

Deno.test("awards: rewarding weight loss is blocked in English", () => {
  const r = validatePack("awards", award({ name: t3("Lost 5 KG", "منتظم", "Constante") }));
  assertEquals(r.errors, [{ key: "items.0.name.en", message: RULE }]);
  assert(has(validatePack("awards", award({ description: t3("Eat less for a week", "x", "x") })), "items.0.description.en"));
  assert(has(validatePack("awards", award({ description: t3("Weight loss hero", "x", "x") })), "items.0.description.en"));
  assert(has(validatePack("awards", award({ description: t3("500 calories burned", "x", "x") })), "items.0.description.en"));
});

Deno.test("awards: rewarding weight loss is blocked in Arabic and Spanish", () => {
  assert(has(validatePack("awards", award({ name: t3("Regular", "بطل التخسيس", "Constante") })), "items.0.name.ar"));
  assert(has(validatePack("awards", award({ name: t3("Regular", "خسرت ٣ كيلو", "Constante") })), "items.0.name.ar"));
  assert(has(validatePack("awards", award({ name: t3("Regular", "منتظم", "Perdiste 3 kilos") })), "items.0.name.es"));
  assert(has(validatePack("awards", award({ description: t3("x", "x", "Déficit de calorías") })), "items.0.description.es"));
});

Deno.test("awards: blocked words match whole words only", () => {
  // "kg" inside another word, "slim" inside "Muslim".
  assert(validatePack("awards", award({ name: t3("Backgammon night"), description: t3("Muslim prayer friendly week") })).ok);
});

Deno.test("awards: the blocked word lists cover all three languages", () => {
  for (const l of ["en", "ar", "es"] as const) assert(AWARD_BLOCKED_WORDS[l].length > 5, l);
});

// challenges ------------------------------------------------------------------

const ch = (over: Record<string, unknown> = {}) => ({ month: "2026-11", title: t3("Train 12 times"), target: 12, ...over });

Deno.test("challenges: month is YYYY-MM and target 4-31", () => {
  assert(validatePack("challenges", { items: [ch()] }).ok);
  for (const month of ["2026-13", "2026-1", "26-11", "2026-00"]) assert(has(validatePack("challenges", { items: [ch({ month })] }), "items.0.month"), month);
  assert(has(validatePack("challenges", { items: [ch({ target: 3 })] }), "items.0.target"));
  assert(has(validatePack("challenges", { items: [ch({ target: 32 })] }), "items.0.target"));
});

Deno.test("challenges: one per month", () => {
  assertEquals(keys(validatePack("challenges", { items: [ch(), ch()] })), ["items.1.month"]);
});

// copy ------------------------------------------------------------------------

Deno.test("copy: known keys with text in three languages", () => {
  assertEquals(COPY_KEYS.length, 10);
  const r = validatePack("copy", { overrides: { emptyDayTitle: t3("Nothing yet") } });
  assert(r.ok);
  assertEquals(r.body, { overrides: { emptyDayTitle: t3("Nothing yet") } });
  assert(has(validatePack("copy", { overrides: { emptyDayTitle: { en: "x" } } }), "overrides.emptyDayTitle.ar"));
  assert(has(validatePack("copy", { overrides: { welcomeBody: t3("x".repeat(241)) } }), "overrides.welcomeBody.en"));
});

Deno.test("copy: unknown keys are errors", () => {
  assertEquals(keys(validatePack("copy", { overrides: { paywallTitle: t3("x") } })), ["overrides.paywallTitle"]);
});
