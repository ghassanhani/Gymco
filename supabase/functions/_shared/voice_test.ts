import { assertEquals } from "jsr:@std/assert@1.0.13";
import { voiceIssues } from "./voice.ts";

Deno.test("voice: 'burn off' is flagged with the contract's hint", () => {
  assertEquals(voiceIssues("Burn off last night's dinner!", "en"), [
    { phrase: "burn off", hint: "ties exercise to food. Try “Start the week strong”." },
  ]);
});

Deno.test("voice: whole words only, case-insensitive, once per phrase", () => {
  assertEquals(voiceIssues("Burnoff is a word; so is guiltless.", "en"), []);
  assertEquals(voiceIssues("GUILT. Guilt. guilt!", "en").length, 1);
  assertEquals(voiceIssues("Lose weight fast and earn your dinner", "en").map((i) => i.phrase), ["earn your", "lose weight"]);
});

Deno.test("voice: 'cheat day' is allowed, 'fat' only as a word about people", () => {
  assertEquals(voiceIssues("Cheat day tomorrow? Log it.", "en"), []);
  assertEquals(voiceIssues("30 g fat per 100 g", "en"), []);
  assertEquals(voiceIssues("Feeling fat? Walk it off.", "en").map((i) => i.phrase), ["fat"]);
  assertEquals(voiceIssues("Fat people welcome", "en").map((i) => i.phrase), ["fat"]);
});

Deno.test("voice: Arabic and Spanish lists, with Arabic prefixes", () => {
  assertEquals(voiceIssues("لا تشعر بالذنب", "ar").map((i) => i.phrase), ["ذنب"]);
  assertEquals(voiceIssues("احرق السعرات الليلة", "ar").map((i) => i.phrase), ["احرق السعرات"]);
  assertEquals(voiceIssues("Quema lo que comiste y gánate la cena", "es").map((i) => i.phrase), ["quema lo que", "gánate"]);
  assertEquals(voiceIssues("Sin culpa", "es").length, 1);
  assertEquals(voiceIssues("Perder peso", "ar"), []);
});
