import { assertEquals } from "jsr:@std/assert@1";
import { defaults, NOTE_KINDS, validate } from "./config_schema.ts";

Deno.test("notifications: every one is on by default, at most 3 a day", () => {
  const d = defaults();
  assertEquals(d.notifications.daily_cap, 3);
  for (const k of Object.keys(NOTE_KINDS)) assertEquals(d.notifications[k], true);
  assertEquals(d.notifications.text, {});
});

Deno.test("notifications: text takes known kinds, parts, languages and placeholders", () => {
  const ok = validate({ notifications: { text: { protein: { body: { en: "{g} g to go 💪", ar_f: "باقي لك {g} غ" } } } } });
  assertEquals(ok.errors, []);
  const bad = validate({
    notifications: {
      text: {
        nope: { title: { en: "x" } },
        protein: { body: { en: "{grams} short" }, footer: { en: "x" } },
        water: { title: { fr: "Eau" } },
      },
    },
  });
  assertEquals(bad.errors.map((e) => e.key).sort(), [
    "notifications.text.nope",
    "notifications.text.protein.body.en",
    "notifications.text.protein.footer",
    "notifications.text.water.title.fr",
  ]);
});

Deno.test("notifications: the text can't be targeted by a rule", () => {
  const r = validate({ rules: [{ key: "notifications.text", value: {}, target: {} }] });
  assertEquals(r.errors.map((e) => e.key), ["rules.0.key"]);
});
