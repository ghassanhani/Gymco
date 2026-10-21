import { test } from "node:test";
import assert from "node:assert/strict";
import {
  accentParts, checkLanding, cleanBody, comparable, errorsFor, fieldChanges, groupKeys, maxFor, moveItem, PRICE_MAX, resetCopy, SECTIONS, setCopy, startBody, STORES,
} from "../../site/admin/lib/landing_form.js";

const T = (en, ar, es) => ({ en, ar, es });
const KEYS = ["hero.cta", "hero.title", "hero.lede", "food.title", "join.title", "footer.tagline"];
const defaults = {
  sections: Object.fromEntries(SECTIONS.map(([k]) => [k, true])),
  beta: true,
  copy: { "hero.title": { en: "Diet and training for *lifters*" }, "join.title": { en: "Start your *streak*" } },
  prices: { pro_month: "€4.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" },
  stores: { ios_url: "", android_url: "" },
  faq: [],
  notify: true,
};

test("the nine sections are listed in page order with human labels", () => {
  assert.deepEqual(SECTIONS.map(([k]) => k), ["proof", "food", "train", "coaching", "streak", "privacy", "plans", "faq", "join"]);
  for (const [, label] of SECTIONS) assert.ok(label.length > 2);
});

test("the working body starts from the draft, then published, then defaults without their English hints", () => {
  const fresh = startBody({ defaults, draft: null, published: null });
  assert.deepEqual(fresh.copy, {}, "default English is a hint, never an override");
  assert.deepEqual(fresh.faq, []);
  assert.equal(fresh.prices.pro_month, "€4.99");
  assert.equal(fresh.sections.coaching, true);

  const pub = { sections: { coaching: false }, copy: { "hero.cta": T("a", "b", "c") } };
  const fromPub = startBody({ defaults, published: { body: pub }, draft: null });
  assert.equal(fromPub.sections.coaching, false);
  assert.equal(fromPub.sections.food, true, "missing sections keep the built-in value");
  assert.deepEqual(fromPub.copy, pub.copy);
  assert.equal(fromPub.notify, true);

  const fromDraft = startBody({ defaults, published: { body: pub }, draft: { body: { beta: false } } });
  assert.equal(fromDraft.beta, false);
  assert.deepEqual(fromDraft.copy, {});
  pub.sections.coaching = true;
  assert.equal(fromPub.sections.coaching, false, "a copy, not the server's object");
});

test("comparing fills built-in values, so an untouched page counts no changes", () => {
  assert.deepEqual(comparable({}, defaults), comparable(startBody({ defaults }), defaults));
  const a = comparable({ prices: { lifetime: "€99" } }, defaults);
  assert.equal(a.prices.lifetime, "€99");
  assert.equal(a.prices.pro_month, "€4.99");
  assert.deepEqual(a.copy, {}, "no default copy in the comparison");
});

test("titles take 80 characters, other copy 300", () => {
  assert.equal(maxFor("hero.title"), 80);
  assert.equal(maxFor("join.title"), 80);
  assert.equal(maxFor("hero.lede"), 300);
  assert.equal(maxFor("hero.cta"), 300);
});

test("keys are grouped by section prefix in their given order", () => {
  assert.deepEqual(groupKeys(KEYS), [
    { prefix: "hero", keys: ["hero.cta", "hero.title", "hero.lede"] },
    { prefix: "food", keys: ["food.title"] },
    { prefix: "join", keys: ["join.title"] },
    { prefix: "footer", keys: ["footer.tagline"] },
  ]);
});

test("a clean body passes", () => {
  const b = startBody({ defaults });
  b.copy["hero.title"] = T("Food and *lifting*", "طعام و*رفع*", "Comida y *pesas*");
  b.faq = [{ q: T("Q?", "س؟", "¿P?"), a: T("A.", "ج.", "R.") }];
  b.stores.ios_url = "https://apps.apple.com/app/gymco/id1";
  assert.deepEqual(checkLanding(b, KEYS), []);
});

test("copy needs all three languages and stays inside its bound, keyed like the server", () => {
  const b = startBody({ defaults });
  b.copy["hero.title"] = T("x".repeat(81), "", "ok");
  b.copy["hero.lede"] = T("y".repeat(301), "ok", "ok");
  b.copy["nope.key"] = T("a", "b", "c");
  const errs = checkLanding(b, KEYS);
  const keys = errs.map((e) => e.key);
  assert.ok(keys.includes("copy.hero.title.en"));
  assert.ok(keys.includes("copy.hero.title.ar"));
  assert.ok(!keys.includes("copy.hero.title.es"));
  assert.ok(keys.includes("copy.hero.lede.en"));
  assert.ok(keys.includes("copy.nope.key"));
  assert.match(errs.find((e) => e.key === "copy.hero.title.en").message, /80/);
  assert.match(errs.find((e) => e.key === "copy.hero.title.ar").message, /all three languages/);
});

test("length is counted after trimming", () => {
  const b = startBody({ defaults });
  b.copy["hero.title"] = T(`  ${"x".repeat(80)}  `, "a", "b");
  assert.deepEqual(checkLanding(b, KEYS), []);
});

test("prices are short text", () => {
  const b = startBody({ defaults });
  b.prices.pro_month = "€4.99 per month!";
  b.prices.lifetime = "€89";
  const errs = checkLanding(b, KEYS);
  assert.deepEqual(errs.map((e) => e.key), ["prices.pro_month"]);
  assert.match(errs[0].message, new RegExp(String(PRICE_MAX)));
});

test("store links are empty or start with the store's own address", () => {
  assert.deepEqual(STORES.map(([k, , p]) => [k, p]), [["ios_url", "https://apps.apple.com/"], ["android_url", "https://play.google.com/"]]);
  const b = startBody({ defaults });
  b.stores.ios_url = "https://play.google.com/store/apps/details?id=x";
  b.stores.android_url = "http://play.google.com/store";
  const errs = checkLanding(b, KEYS);
  assert.deepEqual(errs.map((e) => e.key), ["stores.ios_url", "stores.android_url"]);
  assert.match(errs[0].message, /apps\.apple\.com/);
  b.stores.ios_url = "";
  b.stores.android_url = "https://play.google.com/store/apps/details?id=com.gymco";
  assert.deepEqual(checkLanding(b, KEYS), []);
});

test("each FAQ item needs a question and an answer in all three languages", () => {
  const b = startBody({ defaults });
  b.faq = [
    { q: T("Q?", "س؟", "¿P?"), a: T("A.", "ج.", "R.") },
    { q: T("Q?", "س؟", "¿P?"), a: T("A.", "ج.", "R.") },
    { q: T("Q?", "س؟", ""), a: T("A.", "ج.", "z".repeat(301)) },
  ];
  assert.deepEqual(checkLanding(b, KEYS).map((e) => e.key), ["faq.2.q.es", "faq.2.a.es"]);
});

test("errors for a field gather its languages, naming each one", () => {
  const errs = [{ key: "copy.hero.title.ar", message: "Needed" }, { key: "copy.hero.title.es", message: "Needed" }, { key: "copy.hero.cta.en", message: "Too long" }, { key: "prices.pro_month", message: "At most 12" }];
  assert.deepEqual(errorsFor(errs, "copy.hero.title"), ["AR, ES · Needed"]);
  assert.deepEqual(errorsFor([...errs, { key: "copy.hero.title.en", message: "Too long" }], "copy.hero.title"), ["AR, ES · Needed", "EN · Too long"]);
  assert.deepEqual(errorsFor(errs, "prices.pro_month"), ["At most 12"]);
  assert.deepEqual(errorsFor(errs, "copy.hero.t"), [], "a partial key isn't a match");
});

test("setting copy adds an override, clearing every language removes it", () => {
  let b = startBody({ defaults });
  b = setCopy(b, "hero.title", T("New *title*", "", ""));
  assert.deepEqual(b.copy["hero.title"], T("New *title*", "", ""));
  b = setCopy(b, "hero.title", T("", " ", ""));
  assert.equal("hero.title" in b.copy, false);
  b = setCopy(b, "hero.cta", T("a", "b", "c"));
  const before = b;
  b = resetCopy(b, "hero.cta");
  assert.equal("hero.cta" in b.copy, false);
  assert.ok("hero.cta" in before.copy, "returns a copy");
});

test("cleaning trims text and drops empty overrides before saving", () => {
  const b = startBody({ defaults });
  b.copy["hero.cta"] = T(" Beta ", " تجريبي", "Beta ");
  b.copy["hero.lede"] = T("", "", "");
  b.prices.pro_month = " €5 ";
  b.prices.lifetime = "";
  b.stores.ios_url = " https://apps.apple.com/x ";
  b.faq = [{ q: T(" Q ", "س", "P"), a: T("A", "ج", "R ") }];
  const c = cleanBody(b);
  assert.deepEqual(c.copy, { "hero.cta": T("Beta", "تجريبي", "Beta") });
  assert.equal(c.prices.pro_month, "€5");
  assert.equal("lifetime" in c.prices, false, "an empty price keeps the built-in one");
  assert.equal(c.stores.ios_url, "https://apps.apple.com/x");
  assert.deepEqual(c.faq[0].q, T("Q", "س", "P"));
  assert.equal(b.prices.pro_month, " €5 ", "the working body is left alone");
});

test("FAQ items move up and down within bounds", () => {
  assert.deepEqual(moveItem(["a", "b", "c"], 0, 1), ["b", "a", "c"]);
  assert.deepEqual(moveItem(["a", "b", "c"], 2, -1), ["a", "c", "b"]);
  assert.deepEqual(moveItem(["a", "b", "c"], 0, -1), ["a", "b", "c"]);
  assert.deepEqual(moveItem(["a", "b", "c"], 2, 1), ["a", "b", "c"]);
});

test("*word* marks the italic accent and nothing else is markup", () => {
  assert.deepEqual(accentParts("Diet and training for *lifters*"), [{ text: "Diet and training for ", em: false }, { text: "lifters", em: true }]);
  assert.deepEqual(accentParts("<b>no</b> *a* and *b"), [{ text: "<b>no</b> ", em: false }, { text: "a", em: true }, { text: " and *b", em: false }]);
  assert.deepEqual(accentParts(""), []);
});

test("a copy text counts as one change, whatever languages changed", () => {
  const a = comparable({}, defaults);
  const b = comparable({ copy: { "hero.title": T("a", "b", "c") }, sections: { coaching: false }, faq: [{ q: T("q", "q", "q"), a: T("a", "a", "a") }] }, defaults);
  assert.equal(fieldChanges(a, b), 3);
  assert.equal(fieldChanges(a, a), 0);
});

test("hero pictures: trimmed from the middle to the phone's shape", async () => {
  const { coverCrop, SCREENS: SHOTS, SCREEN_W, SCREEN_H, builtInScreen } = await import("../../site/admin/lib/landing_form.js");
  assert.deepEqual(SHOTS.map(([k]) => k).sort(), ["l1", "l2", "r1", "r2", "today"]);
  assert.equal(builtInScreen("today"), "/img/landing/screen-today.jpg");
  assert.equal(builtInScreen("l2_light"), "/img/landing/screen-l2-light.jpg");
  // The same shape fills exactly.
  assert.deepEqual(coverCrop(SCREEN_W, SCREEN_H), { x: 0, y: 0, w: SCREEN_W, h: SCREEN_H });
  // Wider: the sides go.
  const wide = coverCrop(2000, 1434);
  assert.equal(wide.h, 1434);
  assert.equal(wide.w, 660);
  assert.equal(wide.x, 670);
  // Taller: top and bottom go evenly.
  const tall = coverCrop(660, 2000);
  assert.deepEqual([tall.x, tall.w, tall.h, tall.y], [0, 660, 1434, 283]);
  assert.deepEqual(coverCrop(0, 10), { x: 0, y: 0, w: 0, h: 0 });
});

test("hero pictures: kept through the working body and dropped when empty", () => {
  const url = "https://x.supabase.co/storage/v1/object/public/site/landing/a.jpg";
  const b = startBody({ defaults, published: { body: { screens: { today: url } } }, draft: null });
  assert.deepEqual(b.screens, { today: url });
  assert.deepEqual(startBody({ defaults }).screens, {});
  assert.deepEqual(cleanBody({ ...b, screens: { today: url, l1: "" } }).screens, { today: url });
  assert.deepEqual(comparable({ screens: { r1: url } }, defaults).screens, { r1: url });
});
