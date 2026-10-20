// The landing page's pure logic: language choice, the published settings,
// copy merging and the *accent* split. Run: node --test test/site/landing.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  LANDING_KEYS, SECTIONS, DEFAULT_PRICES, pickLang, splitAccent, sanitizeLanding,
  readConfigResponse, copyFor, faqFor, storeHref, interpolate, isEmail,
} from "../../site/landing-lib.js";
import { COPY } from "../../site/landing-copy.js";

const contract = readFileSync(new URL("../../docs/superpowers/plans/2026-10-20-landing-contract.md", import.meta.url), "utf8");
const contractKeys = (() => {
  const block = contract.split("### LANDING_KEYS")[1].split("Their built-in English")[0];
  return [...block.matchAll(/`([a-z]+\.[a-z0-9.]+)`/g)].map((m) => m[1]);
})();
const t3 = (en, ar = "ع", es = "e") => ({ en, ar, es });

test("LANDING_KEYS are exactly the contract's", () => {
  assert.equal(contractKeys.length, 28);
  assert.deepEqual([...LANDING_KEYS], contractKeys);
});

test("every LANDING_KEY exists in all three languages, and the languages share one key set", () => {
  for (const lang of ["en", "ar", "es"]) {
    for (const k of LANDING_KEYS) assert.equal(typeof COPY[lang][k], "string", `${lang} ${k}`);
  }
  const en = Object.keys(COPY.en).sort();
  assert.deepEqual(Object.keys(COPY.ar).sort(), en);
  assert.deepEqual(Object.keys(COPY.es).sort(), en);
  for (const lang of ["en", "ar", "es"]) {
    for (const [k, v] of Object.entries(COPY[lang])) assert.ok(v.trim() === v && v.length > 0, `${lang} ${k} empty or padded`);
  }
});

test("built-in English for the editable keys is the design's text", () => {
  assert.equal(COPY.en["hero.title"], "Diet and training for *lifters*");
  assert.equal(COPY.en["join.title"], "Start your *streak*");
  assert.equal(COPY.en["train.sub"], "Pick a split or build your own. Miss a day and the week moves with you, and last time's numbers sit on every set.");
  for (const k of LANDING_KEYS) assert.ok(COPY.en[k].length <= (k.endsWith(".title") ? 80 : 300), k);
  // Titles carry exactly one accent in every language.
  for (const lang of ["en", "ar", "es"]) {
    for (const k of LANDING_KEYS.filter((k) => k.endsWith(".title"))) {
      assert.equal(splitAccent(COPY[lang][k]).filter((p) => p.em).length, 1, `${lang} ${k}`);
    }
  }
});

test("the built-in FAQ has seven questions in each language", () => {
  for (const lang of ["en", "ar", "es"]) {
    const f = faqFor(COPY, lang, sanitizeLanding(null));
    assert.equal(f.length, 7);
    assert.ok(f.every((x) => x.q && x.a));
  }
  assert.equal(faqFor(COPY, "en", sanitizeLanding(null))[0].q, "Do I need an account?");
});

test("pickLang: URL first, then saved, else English whatever the browser says", () => {
  assert.equal(pickLang({ query: "?lang=ar", saved: "es", languages: ["en"] }), "ar");
  assert.equal(pickLang({ query: "?x=1&lang=es", saved: "ar" }), "es");
  assert.equal(pickLang({ query: "?lang=fr", saved: "ar" }), "ar");
  assert.equal(pickLang({ query: "", saved: "es", languages: ["ar-EG"] }), "es");
  assert.equal(pickLang({ query: "", saved: "xx", languages: ["ar-EG", "en"] }), "en");
  assert.equal(pickLang({ query: "", saved: null, languages: ["es-ES"] }), "en");
  assert.equal(pickLang({}), "en");
  assert.equal(pickLang({ query: "?lang=AR" }), "ar");
});

test("splitAccent: *word* becomes an accent part, nothing else is markup", () => {
  assert.deepEqual(splitAccent("Diet and training for *lifters*"), [{ text: "Diet and training for ", em: false }, { text: "lifters", em: true }]);
  assert.deepEqual(splitAccent("Log food *your way* now"), [{ text: "Log food ", em: false }, { text: "your way", em: true }, { text: " now", em: false }]);
  assert.deepEqual(splitAccent("no accent"), [{ text: "no accent", em: false }]);
  assert.deepEqual(splitAccent("a * b"), [{ text: "a * b", em: false }]);
  assert.deepEqual(splitAccent("<b>x</b> *y*"), [{ text: "<b>x</b> ", em: false }, { text: "y", em: true }]);
  assert.deepEqual(splitAccent(""), []);
  assert.deepEqual(splitAccent(null), []);
});

test("sanitizeLanding: nothing published is the built-in page", () => {
  for (const raw of [null, undefined, "x", 3, [], {}]) {
    const s = sanitizeLanding(raw);
    assert.deepEqual(s.sections, Object.fromEntries(SECTIONS.map((k) => [k, true])));
    assert.equal(s.beta, true);
    assert.equal(s.notify, true);
    assert.deepEqual(s.prices, DEFAULT_PRICES);
    assert.deepEqual(s.stores, { ios_url: "", android_url: "" });
    assert.deepEqual(s.copy, {});
    assert.deepEqual(s.faq, []);
  }
});

test("sanitizeLanding: takes valid fields and ignores wrong types and unknown keys", () => {
  const s = sanitizeLanding({
    sections: { coaching: false, faq: "no", bogus: false },
    beta: false, notify: "off",
    prices: { pro_month: " €5.99 ", pro_year: 40, lifetime: "a very long price text", year_save: "", nope: "x" },
    stores: { ios_url: "https://apps.apple.com/app/gymco/id1", android_url: "https://evil.example/play.google.com/" },
    copy: {
      "hero.title": { en: " Eat *well* ", ar: "كل *جيدًا*", es: 3 },
      "not.a.key": t3("x"),
      "hero.lede": "plain string",
      "join.sub": { en: "x".repeat(301), ar: "ok" },
      "food.title": { en: "y".repeat(81) },
    },
    extra: 1,
  });
  assert.equal(s.sections.coaching, false);
  assert.equal(s.sections.faq, true);
  assert.ok(!("bogus" in s.sections));
  assert.equal(s.beta, false);
  assert.equal(s.notify, true);
  assert.deepEqual(s.prices, { ...DEFAULT_PRICES, pro_month: "€5.99" });
  assert.deepEqual(s.stores, { ios_url: "https://apps.apple.com/app/gymco/id1", android_url: "" });
  assert.deepEqual(s.copy, { "hero.title": { en: "Eat *well*", ar: "كل *جيدًا*" }, "join.sub": { ar: "ok" } });
  assert.ok(!("extra" in s));
});

test("store URLs must match the allowed prefixes exactly", () => {
  assert.equal(storeHref("ios_url", ""), "#join");
  assert.equal(storeHref("ios_url", "https://apps.apple.com/app/id1"), "https://apps.apple.com/app/id1");
  assert.equal(storeHref("android_url", "https://play.google.com/store/apps/details?id=app.gymco"), "https://play.google.com/store/apps/details?id=app.gymco");
  for (const bad of ["http://apps.apple.com/x", "https://apps.apple.com.evil.com/x", "javascript:alert(1)", "https://play.google.com/x", " https://apps.apple.com/x y", 5, null]) {
    assert.equal(storeHref("ios_url", bad), "#join", String(bad));
  }
  assert.equal(storeHref("android_url", "https://apps.apple.com/x"), "#join");
  assert.equal(storeHref("other", "https://apps.apple.com/x"), "#join");
});

test("readConfigResponse: only { body: object } counts", () => {
  assert.equal(readConfigResponse({ version: 0, body: null }), null);
  assert.equal(readConfigResponse(null), null);
  assert.equal(readConfigResponse("x"), null);
  assert.equal(readConfigResponse({ version: 3, body: [] }), null);
  assert.deepEqual(readConfigResponse({ version: 3, body: { beta: false } }).beta, false);
});

test("copyFor: overrides per language, falling back to the built-in", () => {
  const s = sanitizeLanding({ copy: { "hero.title": { en: "Eat *well*", ar: "كل *جيدًا*" } } });
  assert.equal(copyFor(COPY, "en", s)["hero.title"], "Eat *well*");
  assert.equal(copyFor(COPY, "ar", s)["hero.title"], "كل *جيدًا*");
  assert.equal(copyFor(COPY, "es", s)["hero.title"], COPY.es["hero.title"]);
  assert.equal(copyFor(COPY, "en", s)["hero.lede"], COPY.en["hero.lede"]);
  // Unknown languages read as English; the table itself is untouched.
  assert.equal(copyFor(COPY, "fr", sanitizeLanding(null))["hero.lede"], COPY.en["hero.lede"]);
  assert.equal(COPY.en["hero.title"], "Diet and training for *lifters*");
});

test("copyFor: prices fill the {placeholders}", () => {
  const def = copyFor(COPY, "en", sanitizeLanding(null));
  assert.ok(def["faq.6.a"].startsWith("€4.99 a month, €39.99 a year, or €89 once."));
  const s = sanitizeLanding({ prices: { pro_month: "€5.99", pro_year: "€49.99", lifetime: "€99" } });
  const c = copyFor(COPY, "es", s);
  assert.ok(c["faq.6.a"].includes("€5.99") && c["faq.6.a"].includes("€49.99") && c["faq.6.a"].includes("€99"));
  assert.ok(!Object.values(c).some((v) => /\{(pro_month|pro_year|lifetime|year_save)\}/.test(v)));
  assert.equal(interpolate("a {pro_month} b {x}", DEFAULT_PRICES), "a €4.99 b {x}");
});

test("faqFor: a published list replaces the built-in one, per language with English fallback", () => {
  const s = sanitizeLanding({ faq: [
    { q: t3("Q1", "س1", "P1"), a: t3("A1", "ج1", "R1") },
    { q: { en: "Q2" }, a: { en: "A2", es: "R2" } },
    { q: { ar: "only arabic" }, a: { ar: "x" } },
    "junk",
    { q: t3("Q4"), a: 5 },
  ] });
  assert.deepEqual(faqFor(COPY, "en", s), [{ q: "Q1", a: "A1" }, { q: "Q2", a: "A2" }]);
  assert.deepEqual(faqFor(COPY, "es", s), [{ q: "P1", a: "R1" }, { q: "Q2", a: "R2" }]);
  assert.deepEqual(faqFor(COPY, "ar", s), [{ q: "س1", a: "ج1" }, { q: "Q2", a: "A2" }, { q: "only arabic", a: "x" }]);
  // Nothing usable = the built-in seven.
  assert.equal(faqFor(COPY, "en", sanitizeLanding({ faq: ["junk", {}] })).length, 7);
  assert.equal(faqFor(COPY, "en", sanitizeLanding({ faq: "nope" })).length, 7);
});

test("isEmail: a basic check before sending", () => {
  for (const ok of ["a@b.co", "first.last+tag@mail.example.com"]) assert.ok(isEmail(ok), ok);
  for (const bad of ["", "a", "a@b", "a b@c.de", "@b.co", "a@.co", "x".repeat(320) + "@b.co", null]) assert.ok(!isEmail(bad), String(bad));
});

test("every key the page marks up is in the copy table, and the static page is the built-in English", () => {
  const html = readFileSync(new URL("../../site/index.html", import.meta.url), "utf8");
  const keys = [...html.matchAll(/data-k(?:-aria|-ph)?="([^"]+)"/g)].map((m) => m[1]);
  assert.ok(keys.length > 150);
  for (const k of keys) assert.equal(typeof COPY.en[k], "string", k);
  // Plain-text elements carry the English string as it renders (accents as <em>).
  const c = copyFor(COPY, "en", sanitizeLanding(null));
  for (const m of html.matchAll(/<([a-z0-9]+)[^>]*\sdata-k="([^"]+)"[^>]*>([^<]*(?:<em>[^<]*<\/em>[^<]*)?)<\/\1>/g)) {
    const text = m[3].replace(/<\/?em>/g, "").replace(/&amp;/g, "&");
    assert.equal(text, c[m[2]].replace(/\*/g, ""), m[2]);
  }
  for (const k of LANDING_KEYS) assert.ok(keys.includes(k), `${k} not on the page`);
});

test("the page script never writes HTML", () => {
  for (const f of ["landing.js", "landing-lib.js"]) {
    const src = readFileSync(new URL(`../../site/${f}`, import.meta.url), "utf8");
    assert.ok(!/innerHTML|outerHTML|insertAdjacentHTML|document\.write/.test(src), f);
  }
});
