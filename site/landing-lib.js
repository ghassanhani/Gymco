// Pure logic for the landing page: no DOM, no network, so node:test can run it.
// The page (landing.js) uses these to choose the language, validate what the
// Control Center published and merge it over the built-in copy.

/** The copy the Control Center may change (the contract's LANDING_KEYS). */
export const LANDING_KEYS = [
  "hero.title", "hero.lede", "hero.cta", "hero.cta2",
  "food.eyebrow", "food.title", "food.sub",
  "train.title", "train.sub", "train.cta",
  "coaching.eyebrow", "coaching.title", "coaching.sub",
  "streak.eyebrow", "streak.title", "streak.sub",
  "privacy.eyebrow", "privacy.title", "privacy.sub",
  "plans.eyebrow", "plans.title", "plans.banner",
  "faq.eyebrow", "faq.title",
  "join.title", "join.sub", "join.consent",
  "footer.tagline",
];
export const LANGS = ["en", "ar", "es"];
export const SECTIONS = ["proof", "food", "train", "coaching", "streak", "privacy", "plans", "faq", "join"];
export const DEFAULT_PRICES = { pro_month: "€4.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" };
export const STORE_PREFIX = { ios_url: "https://apps.apple.com/", android_url: "https://play.google.com/" };
const FAQ_MAX = 20;

/** The five hero phones: the centre one and two either side. */
export const SCREENS = ["today", "l1", "l2", "r1", "r2"];
/** Each phone has a picture for the dark page and one for the light page ("<slot>_light"). */
export const SCREEN_KEYS = [...SCREENS, ...SCREENS.map((s) => `${s}_light`)];
/** Replacements come only from the Control Center's uploads: Gymco's public bucket, named by SHA-256. */
export const SCREEN_PREFIX = "https://vncadogzpeoawikgafaj.supabase.co/storage/v1/object/public/site/landing/";
const SCREEN_FILE = /^[0-9a-f]{64}\.(jpg|png|webp)$/;

/** True for a picture the Control Center uploaded to Gymco's bucket. */
export const isScreenUrl = (url) => typeof url === "string" && url.startsWith(SCREEN_PREFIX) && SCREEN_FILE.test(url.slice(SCREEN_PREFIX.length));

/** The picture for a hero phone in a look: the published replacement if it is one of ours, else the page's own. */
export function screenSrc(slot, url, light = false) {
  if (isScreenUrl(url)) return url;
  return `/img/landing/screen-${slot}${light ? "-light" : ""}.jpg`;
}

const isObj = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const lang2 = (v) => (typeof v === "string" ? v.trim().toLowerCase().slice(0, 2) : "");
const known = (l) => (LANGS.includes(l) ? l : null);

/** ?lang= in the URL, else the saved choice, else the browser's ar/es, else English. */
export function pickLang({ query = "", saved = null } = {}) {
  let fromUrl = null;
  try { fromUrl = new URLSearchParams(query || "").get("lang"); } catch { /* bad query */ }
  const a = known(lang2(fromUrl));
  if (a) return a;
  // English unless the visitor picked a language: the browser's doesn't count.
  return known(lang2(saved)) ?? "en";
}

/** "Log food *your way*" → [{text:"Log food ",em:false},{text:"your way",em:true}]. Nothing else is markup. */
export function splitAccent(s) {
  if (typeof s !== "string" || !s) return [];
  const out = [];
  let last = 0;
  for (const m of s.matchAll(/\*([^*\s][^*]*?)\*/g)) {
    if (m.index > last) out.push({ text: s.slice(last, m.index), em: false });
    out.push({ text: m[1], em: true });
    last = m.index + m[0].length;
  }
  if (last < s.length) out.push({ text: s.slice(last), em: false });
  return out;
}

/** A store link, if it starts with the allowed prefix; otherwise the page's own #join. */
export function storeHref(kind, url) {
  const prefix = STORE_PREFIX[kind];
  if (!prefix || typeof url !== "string" || url.length > 500 || /\s/.test(url) || !url.startsWith(prefix)) return "#join";
  try {
    const u = new URL(url);
    if (u.protocol !== "https:" || u.origin + "/" !== prefix) return "#join";
    return u.href;
  } catch {
    return "#join";
  }
}

const text = (v, max) => {
  if (typeof v !== "string") return null;
  const s = v.trim();
  return s && s.length <= max ? s : null;
};
/** { en, ar, es } with only the languages that are valid strings. */
const t3 = (v, max) => {
  const out = {};
  if (!isObj(v)) return out;
  for (const l of LANGS) {
    const s = text(v[l], max);
    if (s) out[l] = s;
  }
  return out;
};

/** The settings to render: the published body over the built-in values, every field checked. */
export function sanitizeLanding(raw) {
  const src = isObj(raw) ? raw : {};
  const s = {
    sections: Object.fromEntries(SECTIONS.map((k) => [k, true])),
    beta: true,
    notify: true,
    prices: { ...DEFAULT_PRICES },
    stores: { ios_url: "", android_url: "" },
    copy: {},
    faq: [],
    screens: {},
  };
  if (isObj(src.sections)) for (const k of SECTIONS) if (typeof src.sections[k] === "boolean") s.sections[k] = src.sections[k];
  if (typeof src.beta === "boolean") s.beta = src.beta;
  if (typeof src.notify === "boolean") s.notify = src.notify;
  if (isObj(src.prices)) {
    for (const k of Object.keys(DEFAULT_PRICES)) {
      const v = text(src.prices[k], 12);
      if (v) s.prices[k] = v;
    }
  }
  if (isObj(src.stores)) {
    for (const k of Object.keys(STORE_PREFIX)) {
      const v = typeof src.stores[k] === "string" ? src.stores[k].trim() : "";
      if (v && storeHref(k, v) !== "#join") s.stores[k] = v;
    }
  }
  if (isObj(src.copy)) {
    for (const k of LANDING_KEYS) {
      const v = t3(src.copy[k], k.endsWith(".title") ? 80 : 300);
      if (Object.keys(v).length) s.copy[k] = v;
    }
  }
  if (isObj(src.screens)) {
    for (const k of SCREEN_KEYS) if (isScreenUrl(src.screens[k])) s.screens[k] = src.screens[k];
  }
  if (Array.isArray(src.faq)) {
    for (const item of src.faq.slice(0, FAQ_MAX)) {
      if (!isObj(item)) continue;
      const q = t3(item.q, 200);
      const a = t3(item.a, 1000);
      if (Object.keys(q).length && Object.keys(a).length) s.faq.push({ q, a });
    }
  }
  return s;
}

/** The app-config response: { version, body } with body an object, or null for nothing usable. */
export function readConfigResponse(json) {
  if (!isObj(json) || !isObj(json.body)) return null;
  return sanitizeLanding(json.body);
}

/** "{pro_month}"-style placeholders filled from the prices; unknown ones stay as they are. */
export function interpolate(s, prices) {
  return String(s).replace(/\{(pro_month|pro_year|lifetime|year_save)\}/g, (m, k) => prices?.[k] ?? DEFAULT_PRICES[k] ?? m);
}

/** The flat copy table for [lang]: built-in strings, the published overrides on top, prices filled in. */
export function copyFor(table, lang, settings) {
  const l = known(lang) ?? "en";
  const s = settings ?? sanitizeLanding(null);
  const out = { ...table.en, ...table[l] };
  for (const [k, v] of Object.entries(s.copy ?? {})) if (v[l]) out[k] = v[l];
  for (const k of Object.keys(out)) out[k] = interpolate(out[k], s.prices);
  return out;
}

/** The questions to show: the published list (each item in [lang], else English) or the built-in seven. */
export function faqFor(table, lang, settings) {
  const l = known(lang) ?? "en";
  const s = settings ?? sanitizeLanding(null);
  const fill = (v) => interpolate(v, s.prices);
  const list = (s.faq ?? [])
    .map(({ q, a }) => ({ q: q[l] ?? q.en, a: a[l] ?? a.en }))
    .filter((x) => x.q && x.a)
    .map((x) => ({ q: fill(x.q), a: fill(x.a) }));
  if (list.length) return list;
  const c = copyFor(table, l, s);
  const out = [];
  for (let i = 1; c[`faq.${i}.q`]; i++) out.push({ q: c[`faq.${i}.q`], a: c[`faq.${i}.a`] });
  return out;
}

/** A basic shape check; the server has the final say. */
export function isEmail(v) {
  return typeof v === "string" && v.length <= 320 && /^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$/.test(v);
}
