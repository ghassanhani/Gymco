import { assertEquals } from "jsr:@std/assert@1.0.13";
import { spokenLanguage } from "./spoken_language.ts";

Deno.test("reads the language a note was spoken in", () => {
  assertEquals(spokenLanguage("two eggs and toast with coffee"), "en");
  assertEquals(spokenLanguage("dos huevos y una tostada con café"), "es");
  assertEquals(spokenLanguage("deux oeufs et du pain avec un café"), "fr");
  assertEquals(spokenLanguage("iki yumurta ve ekmek yedim"), "tr");
  assertEquals(spokenLanguage("два яйца и хлеб с кофе"), "ru");
  assertEquals(spokenLanguage("मैंने दो अंडे और रोटी खाई"), "hi");
});

Deno.test("Arabic script is Arabic, even mixed with English", () => {
  assertEquals(spokenLanguage("أكلت كبسة دجاج مع رز"), "ar");
  assertEquals(spokenLanguage("chicken burger و بطاطس"), "ar");
});

Deno.test("too short to tell", () => {
  assertEquals(spokenLanguage("eggs"), "");
  assertEquals(spokenLanguage(""), "");
});
