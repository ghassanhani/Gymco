import { test } from "node:test";
import assert from "node:assert/strict";
import { noteErrors, noteGroups, notePreview, setNoteText } from "../../site/admin/lib/notes_form.js";
import { NOTES } from "../../site/admin/lib/notes_catalog.js";

test("the catalog has every notification the app schedules, in its groups", () => {
  assert.equal(NOTES.length, 19);
  assert.deepEqual(noteGroups(NOTES).map(([g]) => g), ["Daily habit", "Workout timer", "Streak & awards", "Progress & coaching", "Account & system"]);
  const lunch = NOTES.find((n) => n.kind === "lunch");
  assert.equal(lunch.title.en, "🥗 Lunch");
  assert.equal(lunch.body.ar_f, "وقت الغدا. صوّريه أو اكتبيه، والحسبة علينا.");
});

test("a preview fills in sample numbers, and an edit wins over the app's words", () => {
  const protein = NOTES.find((n) => n.kind === "protein");
  assert.equal(notePreview(protein, null, "en").body, "You're 40 g short on protein. A shake or Greek yogurt closes it.");
  assert.equal(notePreview(protein, { body: { en: "{g} g to go 💪" } }, "en").body, "40 g to go 💪");
  // The feminine Arabic falls back to the Arabic edit.
  assert.equal(notePreview(protein, { body: { ar: "باقي {g} غ" } }, "ar_f").body, "باقي 40 غ");
});

test("unknown placeholders and long text are caught before saving", () => {
  assert.deepEqual(noteErrors({ text: { protein: { body: { en: "{grams} short" } } } }), ["{grams} isn’t a placeholder this notification has"]);
  assert.equal(noteErrors({ text: { lunch: { title: { en: "x".repeat(61) } } } }).length, 1);
  assert.deepEqual(noteErrors({ text: { water: { body: { en: "{l} L left" } } } }), []);
});

test("clearing a language drops it, and an empty part goes", () => {
  const t = setNoteText({}, "title", "en", "Hi");
  assert.deepEqual(t, { title: { en: "Hi" } });
  assert.deepEqual(setNoteText(t, "title", "en", "  "), {});
});

test("each notification's preview reads with its own sample numbers", () => {
  const by = (k) => NOTES.find((n) => n.kind === k);
  assert.equal(notePreview(by("restOver"), null, "en").body, "Set 3 of Bench Press.");
  assert.equal(notePreview(by("freezeUsed"), null, "en").body, "A freeze saved your streak yesterday. 2 freezes left.");
  assert.equal(notePreview(by("challengeNew"), null, "en").body, "Train 12 times this month.");
});
