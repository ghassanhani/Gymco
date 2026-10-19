import { test } from "node:test";
import assert from "node:assert/strict";
import {
  blankItem, checkBody, checkLines, COPY_KEYS, countItemChanges, FIELDS, getList, itemIndex, itemSub, itemTitle, KINDS,
  keyedBody, kindOf, matchUnits, mergeChecks, setList, weeklySets,
} from "../../site/admin/lib/packs_form.js";

const t3 = (en, ar = `${en} ar`, es = `${en} es`) => ({ en, ar, es });
const keys = (list) => list.map((e) => e.key);

test("the eight kinds, in the library's order, and an unknown kind falls back to foods", () => {
  assert.deepEqual(KINDS.map((k) => k.id), ["foods", "vocabulary", "eating_out", "exercises", "templates", "awards", "challenges", "copy"]);
  assert.equal(kindOf("exercises").label, "Exercises");
  assert.equal(kindOf("nope").id, "foods");
  for (const k of KINDS) if (k.id !== "copy") assert.ok(FIELDS[k.id]?.length, `${k.id} has fields`);
});

test("lists are read and written by the kind's list key", () => {
  assert.deepEqual(getList("vocabulary", { units: [1] }), [1]);
  assert.deepEqual(getList("eating_out", {}), []);
  assert.deepEqual(setList("eating_out", { dishes: [] }, [2]), { dishes: [2] });
});

test("a valid food passes; bounds and a missing language say where", () => {
  const ok = { id: "labneh", name: t3("Labneh"), kcal: 200, protein: 10, carbs: 4, fat: 17.3 };
  assert.deepEqual(checkBody("foods", { items: [ok] }).errors, []);
  const bad = { id: "Labneh!", name: { en: "Labneh", ar: "لبنة", es: " " }, kcal: 950, protein: 60, carbs: 30, fat: 20 };
  const { errors } = checkBody("foods", { items: [bad] });
  assert.ok(keys(errors).includes("items.0.id"));
  assert.ok(keys(errors).includes("items.0.name.es"));
  assert.ok(keys(errors).includes("items.0.kcal"));
  assert.ok(errors.some((e) => /100/.test(e.message) && e.key === "items.0"), "macros together over 100 g");
  assert.match(errors.find((e) => e.key === "items.0.name.es").message, /Spanish/);
});

test("macros that don't add up to kcal are a warning in the contract's words", () => {
  const labneh = { id: "labneh", name: t3("Labneh"), kcal: 160, protein: 10, carbs: 4, fat: 17.3 };
  const { errors, warnings } = checkBody("foods", { items: [labneh] });
  assert.deepEqual(errors, []);
  assert.equal(warnings[0].message, "Labneh: macros add up to 212 kcal, but kcal says 160 per 100 g. Check the numbers.");
  // Within 20 kcal is fine even when the share is large.
  assert.deepEqual(checkBody("foods", { items: [{ ...labneh, kcal: 10, protein: 1, carbs: 1, fat: 1 }] }).warnings, []);
});

test("ids are unique within a pack; vocabulary words per language", () => {
  const f = { id: "a", name: t3("A"), kcal: 10, protein: 1, carbs: 1, fat: 0 };
  assert.ok(keys(checkBody("foods", { items: [f, f] }).errors).includes("items.1.id"));
  const u = { word: "scoop", lang: "en", unit: "scoop" };
  assert.ok(keys(checkBody("vocabulary", { units: [u, u] }).errors).includes("units.1.word"));
  assert.deepEqual(checkBody("vocabulary", { units: [u, { ...u, lang: "es" }] }).errors, []);
  assert.ok(keys(checkBody("vocabulary", { units: [{ ...u, unit: "litre" }] }).errors).includes("units.0.unit"));
});

test("exercises need a primary muscle and follow free-exercise-db ids", () => {
  const ex = { id: "Barbell_Hip_Thrust", name: t3("Hip thrust"), primary: ["glutes"], secondary: [] };
  assert.deepEqual(checkBody("exercises", { items: [ex], removed: ["Sissy_Squat"] }).errors, []);
  const { errors } = checkBody("exercises", { items: [{ ...ex, primary: [], secondary: ["wings"], level: "pro" }], removed: ["bad id!"] });
  assert.deepEqual(keys(errors).sort(), ["items.0.level", "items.0.primary", "items.0.secondary", "removed.0"]);
});

test("templates check routine counts and that the rep range runs upwards", () => {
  const item = { exercise: "Barbell_Squat", sets: 3, rep_low: 8, rep_high: 6, rest_s: 120 };
  const tpl = { id: "ppl", name: t3("PPL"), level: "intermediate", routines: [{ name: t3("Legs"), weekday: 3, items: [item] }] };
  assert.ok(keys(checkBody("templates", { items: [tpl] }).errors).includes("items.0.routines.0.items.0.rep_high"));
  const none = { ...tpl, routines: [] };
  assert.ok(keys(checkBody("templates", { items: [none] }).errors).includes("items.0.routines"));
});

test("awards that reward weight loss or eating less are blocked with the rule's message", () => {
  const good = { id: "logged_30", name: t3("Logged 30 days"), description: t3("Thirty full days logged"), metric: "logged_days", threshold: 30 };
  assert.deepEqual(checkBody("awards", { items: [good] }).errors, []);
  const bad = { ...good, id: "lost", name: t3("Lost 5 kg") };
  const e = checkBody("awards", { items: [bad] }).errors.find((x) => x.key === "items.0.name");
  assert.match(e.message, /^Awards can’t reward weight loss or eating less\. Try showing up instead/);
});

test("challenges are one per month in YYYY-MM with a target of 4–31", () => {
  const c = { month: "2026-11", title: t3("Train 12 times"), target: 12 };
  assert.deepEqual(checkBody("challenges", { items: [c] }).errors, []);
  const { errors } = checkBody("challenges", { items: [c, { ...c, target: 2 }, { ...c, month: "2026-13" }] });
  assert.deepEqual(keys(errors).sort(), ["items.1.month", "items.1.target", "items.2.month"]);
});

test("copy overrides only known keys, each in all three languages", () => {
  assert.equal(COPY_KEYS.length, 10);
  assert.deepEqual(checkBody("copy", { overrides: { emptyDayTitle: t3("A fresh start") } }).errors, []);
  const { errors } = checkBody("copy", { overrides: { nope: t3("x"), remindMealBody: { en: "Log it", ar: "", es: "Anótalo" } } });
  assert.deepEqual(keys(errors).sort(), ["overrides.nope", "overrides.remindMealBody.ar"]);
});

test("error keys point back at their item", () => {
  assert.equal(itemIndex("items.3.name.es"), 3);
  assert.equal(itemIndex("units.0"), 0);
  assert.equal(itemIndex("removed.2"), null);
  assert.equal(itemIndex("overrides.emptyDayTitle.es"), null);
});

test("client and server checks merge without repeating a key", () => {
  const merged = mergeChecks([{ key: "items.0.name.es", message: "a" }], [{ key: "items.0.name.es", message: "b" }, { key: "removed.0", message: "c" }]);
  assert.deepEqual(merged, [{ key: "items.0.name.es", message: "b" }, { key: "removed.0", message: "c" }]);
});

test("the checks card groups missing languages and lists the rest", () => {
  const errors = [
    { key: "items.0.name.es", message: "Add the Spanish name" }, { key: "items.2.name.es", message: "Missing Spanish" }, { key: "items.2.name.ar", message: "Add the Arabic name" },
    { key: "removed.0", message: "Removes “Barbell_Hip_Thrust”, used in 2 templates" },
  ];
  const lines = checkLines(errors, [{ key: "items.1", message: "Labneh: check" }]);
  assert.deepEqual(lines.map((l) => [l.tone, l.title]), [
    ["bad", "2 items missing Spanish"], ["bad", "1 item missing Arabic"],
    ["bad", "Removes “Barbell_Hip_Thrust”, used in 2 templates"], ["warn", "Labneh: check"],
  ]);
  assert.deepEqual(checkLines([], []).map((l) => l.tone), ["good"]);
});

test("titles and summaries name each item the way the table shows it", () => {
  assert.equal(itemTitle("foods", { name: t3("Labneh") }), "Labneh");
  assert.equal(itemTitle("vocabulary", { word: "كوب" }), "كوب");
  assert.equal(itemTitle("challenges", { month: "2026-11", title: t3("Train 12 times") }), "Train 12 times");
  assert.equal(itemTitle("foods", { name: { en: "" }, id: "x" }), "x");
  assert.equal(itemSub("foods", { kcal: 160, protein: 10, carbs: 4, fat: 17.3 }), "160 kcal · P 10 · C 4 · F 17.3 per 100 g");
  assert.equal(itemSub("vocabulary", { lang: "ar", unit: "cup" }), "Arabic · cup");
  assert.equal(itemSub("exercises", { primary: ["glutes", "hamstrings"], level: "beginner" }), "Glutes, hamstrings · beginner");
});

test("a new item has a unique id and empty texts in every language", () => {
  const a = blankItem("foods", [{ id: "new_food" }]);
  assert.equal(a.id, "new_food_2");
  assert.deepEqual(a.name, { en: "", ar: "", es: "" });
  assert.ok(checkBody("foods", { items: [a] }).errors.length > 0, "a blank item still needs filling in");
  assert.match(blankItem("challenges", [{ month: "2026-11" }]).month, /^\d{4}-\d{2}$/);
  assert.equal(blankItem("templates", []).routines.length, 1);
});

test("changes are counted per item, added, removed or edited", () => {
  const a = { items: [{ id: "a", kcal: 1 }, { id: "b", kcal: 2 }] };
  const b = { items: [{ id: "a", kcal: 5 }, { id: "c", kcal: 2 }] };
  assert.equal(countItemChanges("foods", a, b), 3);
  assert.equal(countItemChanges("foods", a, structuredClone(a)), 0);
  assert.equal(countItemChanges("exercises", { items: [], removed: [] }, { items: [], removed: ["X"] }), 1);
  assert.equal(countItemChanges("copy", { overrides: {} }, { overrides: { emptyDayTitle: t3("x") } }), 1);
});

test("the test box finds the pack's unit words in a meal, plurals too", () => {
  const units = [{ word: "scoop", lang: "en", unit: "scoop" }, { word: "كوب", lang: "ar", unit: "cup" }, { word: "handful", lang: "en", unit: "handful" }];
  const m = matchUnits("2 scoops whey, كوب حليب", units);
  assert.deepEqual(m.found.map((f) => [f.token, f.unit]), [["scoops", "scoop"], ["كوب", "cup"]]);
  assert.deepEqual(m.other, ["2", "whey", "حليب"]);
  assert.deepEqual(matchUnits("", units).found, []);
});

test("weekly sets add up per routine and per exercise", () => {
  const r = (name, items) => ({ name: t3(name), weekday: 1, items });
  const it = (exercise, sets) => ({ exercise, sets, rep_low: 6, rep_high: 10, rest_s: 90 });
  const w = weeklySets({ routines: [r("Push", [it("Bench", 4), it("Dips", 3)]), r("Push B", [it("Bench", 3)])] });
  assert.equal(w.total, 10);
  assert.deepEqual(w.routines.map((x) => [x.name, x.sets, x.exercises]), [["Push", 7, 2], ["Push B", 3, 1]]);
  assert.deepEqual(w.exercises, [{ exercise: "Bench", sets: 7, routines: 2 }, { exercise: "Dips", sets: 3, routines: 1 }]);
});

test("bodies are keyed by item for the diff, so a change reads as id.field", () => {
  const body = { items: [{ id: "labneh", kcal: 160 }], removed: ["X"] };
  assert.deepEqual(keyedBody("exercises", body), { labneh: { id: "labneh", kcal: 160 }, removed: ["X"] });
  assert.deepEqual(keyedBody("vocabulary", { units: [{ word: "كوب", lang: "ar", unit: "cup" }] }), { "ar:كوب": { word: "كوب", lang: "ar", unit: "cup" } });
  assert.deepEqual(keyedBody("copy", { overrides: { a: 1 } }), { a: 1 });
});
