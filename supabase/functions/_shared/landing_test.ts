import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { defaultLanding, LANDING_DEFAULTS, LANDING_KEYS, validateLanding } from "./landing.ts";

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });
const keys = (r: { errors: { key: string }[] }) => r.errors.map((e) => e.key);

Deno.test("landing: the editable keys are the contract's, each with built-in English", () => {
  assertEquals([...LANDING_KEYS], [
    "hero.tag", "hero.title", "hero.lede", "hero.cta", "hero.cta2",
    "food.eyebrow", "food.title", "food.sub",
    "train.title", "train.sub", "train.cta",
    "coaching.eyebrow", "coaching.title", "coaching.sub",
    "streak.eyebrow", "streak.title", "streak.sub",
    "privacy.eyebrow", "privacy.title", "privacy.sub",
    "plans.eyebrow", "plans.title", "plans.banner",
    "faq.eyebrow", "faq.title",
    "join.title", "join.sub", "join.consent",
    "footer.tagline",
  ]);
  assertEquals(Object.keys(LANDING_DEFAULTS).sort(), [...LANDING_KEYS].sort());
  assertEquals(LANDING_DEFAULTS["hero.title"], "Diet and training for *lifters*");
  assertEquals(LANDING_DEFAULTS["join.title"], "Start your *streak*");
  for (const k of LANDING_KEYS) {
    const s = LANDING_DEFAULTS[k];
    assert(s.trim() === s && s.length > 0 && s.length <= (k.endsWith(".title") ? 80 : 300), k);
  }
});

Deno.test("landing: the default body has every section on, beta, the design's prices and no store links", () => {
  const d = defaultLanding();
  assertEquals(d.sections, { proof: true, food: true, train: true, coaching: true, streak: true, privacy: true, plans: true, faq: true, join: true });
  assertEquals(d.beta, true);
  assertEquals(d.prices, { pro_month: "€4.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" });
  assertEquals(d.stores, { ios_url: "", android_url: "" });
  assertEquals([d.copy, d.faq, d.notify], [{}, [], true]);
  // A fresh copy each time.
  d.sections.food = false;
  assertEquals(defaultLanding().sections.food, true);
});

Deno.test("landing: an empty input is the default body and valid", () => {
  for (const input of [undefined, null, {}, "x", 3]) {
    const r = validateLanding(input);
    assertEquals([r.ok, r.errors], [true, []]);
    assertEquals(r.body, defaultLanding());
  }
});

Deno.test("landing: values merge over the defaults and unknown keys are dropped", () => {
  const r = validateLanding({
    sections: { faq: false, bogus: true }, beta: false, notify: false, extra: 1,
    prices: { pro_month: " €5.99 ", nope: "x" }, stores: { ios_url: "https://apps.apple.com/app/id1", other: "x" },
    copy: { "hero.title": { en: " Eat *well* ", ar: "كل", es: "Come" } },
  });
  assertEquals(r.errors, []);
  assertEquals(r.body.sections.faq, false);
  assertEquals(r.body.sections.food, true);
  assert(!("bogus" in r.body.sections));
  assert(!("extra" in r.body));
  assertEquals([r.body.beta, r.body.notify], [false, false]);
  assertEquals(r.body.prices, { pro_month: "€5.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" });
  assertEquals(r.body.stores, { ios_url: "https://apps.apple.com/app/id1", android_url: "" });
  assertEquals(r.body.copy, { "hero.title": { en: "Eat *well*", ar: "كل", es: "Come" } });
});

Deno.test("landing: booleans must be booleans", () => {
  const r = validateLanding({ sections: { food: "yes" }, beta: 1, notify: null });
  assertEquals(keys(r), ["sections.food", "beta", "notify"]);
  assertEquals(r.ok, false);
});

Deno.test("landing: copy keys are whitelisted and every language is needed", () => {
  const r = validateLanding({ copy: { "hero.nope": t3("x"), "hero.lede": { en: "Hi", ar: " ", es: "Hola" } } });
  assertEquals(keys(r), ["copy.hero.nope", "copy.hero.lede.ar"]);
  assert(!("hero.nope" in r.body.copy));
});

Deno.test("landing: copy is at most 300 characters, titles at most 80", () => {
  const ok = validateLanding({ copy: { "hero.lede": t3("a".repeat(300)), "hero.title": t3("a".repeat(80)) } });
  assertEquals(ok.errors, []);
  const bad = validateLanding({ copy: { "hero.lede": t3("a".repeat(301)), "join.title": t3("a".repeat(81)), "hero.tag": t3("a".repeat(81)) } });
  assertEquals(keys(bad), ["copy.hero.lede.en", "copy.join.title.en"]);
});

Deno.test("landing: prices are non-empty text up to 12 characters", () => {
  const r = validateLanding({ prices: { pro_month: "", pro_year: "€39.99 a year!", lifetime: 89, year_save: "−40%" } });
  assertEquals(keys(r), ["prices.pro_month", "prices.pro_year", "prices.lifetime"]);
  assertEquals(r.body.prices.year_save, "−40%");
});

Deno.test("landing: store links are empty or on the stores' own sites", () => {
  assertEquals(validateLanding({ stores: { ios_url: "", android_url: "https://play.google.com/store/apps/details?id=app.gymco" } }).errors, []);
  for (const bad of ["http://apps.apple.com/x", "https://apps.apple.com.evil.test/x", "https://evil.test/https://apps.apple.com/", "javascript:alert(1)", 3]) {
    assertEquals(keys(validateLanding({ stores: { ios_url: bad } })), ["stores.ios_url"], String(bad));
  }
  assertEquals(keys(validateLanding({ stores: { android_url: "https://apps.apple.com/x" } })), ["stores.android_url"]);
});

Deno.test("landing: the FAQ is at most 20 questions, each in every language", () => {
  const item = { q: t3("Q?"), a: t3("A.") };
  const ok = validateLanding({ faq: [item, { q: t3(" Q2? "), a: t3("A2."), x: 1 }] });
  assertEquals(ok.errors, []);
  assertEquals(ok.body.faq, [item, { q: t3("Q2?"), a: t3("A2.") }]);
  assertEquals(keys(validateLanding({ faq: Array(21).fill(item) })), ["faq"]);
  assertEquals(keys(validateLanding({ faq: "no" })), ["faq"]);
  const bad = validateLanding({ faq: [item, item, { q: t3("a".repeat(201)), a: { en: "x", ar: "y", es: "" } }, null] });
  assertEquals(keys(bad), ["faq.2.q.en", "faq.2.a.es", "faq.3.q.en", "faq.3.q.ar", "faq.3.q.es", "faq.3.a.en", "faq.3.a.ar", "faq.3.a.es"]);
  assertEquals(keys(validateLanding({ faq: [{ q: t3("Q"), a: t3("a".repeat(1001)) }] })), ["faq.0.a.en"]);
});
