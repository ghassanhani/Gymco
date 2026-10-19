import { test } from "node:test";
import assert from "node:assert/strict";
import { voiceIssues, voiceIssuesT3, voiceLine } from "../../site/admin/lib/voice.js";

test("flags phrases that tie exercise to food or shame, whole-word and case-insensitive", () => {
  const hits = voiceIssues("Burn off the weekend with this challenge!", "en");
  assert.equal(hits.length, 1);
  assert.equal(hits[0].phrase, "burn off");
  assert.equal(voiceLine(hits[0]), "Voice check: “burn off” ties exercise to food. Try “Start the week strong”.");
  assert.deepEqual(voiceIssues("Start the week strong", "en"), []);
  // "fat" inside another word is not a hit; "cheat day" is allowed.
  assert.deepEqual(voiceIssues("Fatigue is normal on a cheat day", "en"), []);
  assert.equal(voiceIssues("No guilt here", "en")[0].phrase, "guilt");
});

test("Arabic and Spanish lists, and the three-language helper", () => {
  assert.equal(voiceIssues("احرق السعرات اليوم", "ar")[0].phrase, "احرق");
  assert.equal(voiceIssues("Vas a quemar calorías", "es")[0].phrase, "quemar");
  const all = voiceIssuesT3({ en: "Train today", ar: "", es: "Sin culpa" });
  assert.deepEqual(all.map((x) => x.lang), ["es"]);
  assert.deepEqual(voiceIssues("", "en"), []);
});
