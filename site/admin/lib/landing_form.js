// Pure helpers for the landing page editor: the contract's bounds (so
// mistakes show before saving, under the same keys the server uses), the
// working body, change comparison and small list moves.

export const SECTIONS = [
  ["proof", "Proof numbers", "The four figures under the hero"],
  ["food", "Food logging", "Six ways to log, with the Write demo"],
  ["train", "Training", "Routines, the workout card and progress chart"],
  ["coaching", "Coaching", "Trend weight and the weekly check-in"],
  ["streak", "Streaks and awards", "Freezes, repair and badges"],
  ["privacy", "Privacy", "What stays on the phone and what Gymco never does"],
  ["plans", "Plans", "Free, Pro and Lifetime with prices"],
  ["faq", "FAQ", "Questions and answers"],
  ["join", "Join and sign-up", "The closing call to action and the email box"],
];

export const PRICES = [["pro_month", "Pro · monthly"], ["pro_year", "Pro · yearly"], ["lifetime", "Lifetime"], ["year_save", "Yearly saving"]];
export const STORES = [["ios_url", "App Store link", "https://apps.apple.com/"], ["android_url", "Google Play link", "https://play.google.com/"]];
/** The hero's five phones, in the order the card shows them: [slot, name, where]. */
export const SCREENS = [
  ["today", "Centre", "The phone in front, usually Today"],
  ["l1", "Left, near", "Just left of centre"],
  ["r1", "Right, near", "Just right of centre"],
  ["l2", "Left, far", "The outer phone on the left"],
  ["r2", "Right, far", "The outer phone on the right"],
];
/** Every hero picture is drawn at this size (a phone screen, 660 × 1434). */
export const SCREEN_W = 660;
export const SCREEN_H = 1434;
/** The page's own picture for a slot: "today" on the dark page, "today_light" on the light one. */
export const builtInScreen = (key) => `/img/landing/screen-${key.replace(/_light$/, "")}${key.endsWith("_light") ? "-light" : ""}.jpg`;
/** The two pages the phones are shown on, and the suffix their slots carry. */
export const LOOKS = [["", "Dark page"], ["_light", "Light page"]];

/** The part of a [sw]×[sh] picture that fills [tw]×[th] without stretching: centred, the long side trimmed. */
export function coverCrop(sw, sh, tw = SCREEN_W, th = SCREEN_H) {
  if (!(sw > 0 && sh > 0)) return { x: 0, y: 0, w: 0, h: 0 };
  const want = tw / th;
  if (sw / sh > want) {
    const w = Math.round(sh * want);
    return { x: Math.round((sw - w) / 2), y: 0, w, h: sh };
  }
  const h = Math.round(sw / want);
  return { x: 0, y: Math.round((sh - h) / 2), w: sw, h };
}

export const PRICE_MAX = 12;
export const TITLE_MAX = 80;
export const TEXT_MAX = 300;
const LANG_KEYS = ["en", "ar", "es"];

export const maxFor = (key) => (/\.title$/.test(key) ? TITLE_MAX : TEXT_MAX);

const str = (v) => (typeof v === "string" ? v : "");
const trim3 = (v) => Object.fromEntries(LANG_KEYS.map((l) => [l, str(v?.[l]).trim()]));
const blank3 = (v) => LANG_KEYS.every((l) => !str(v?.[l]).trim());

/** The editable body: the draft, else the published body, else the defaults (whose English copy is only a hint). */
export function startBody(data) {
  const d = data?.defaults ?? {};
  const src = data?.draft?.body ?? data?.published?.body ?? null;
  const b = structuredClone(src ?? {});
  return {
    ...b,
    sections: { ...d.sections, ...b.sections },
    beta: typeof b.beta === "boolean" ? b.beta : d.beta ?? true,
    copy: b.copy && typeof b.copy === "object" ? b.copy : {},
    prices: { ...d.prices, ...b.prices },
    stores: { ios_url: "", android_url: "", ...d.stores, ...b.stores },
    faq: Array.isArray(b.faq) ? b.faq : [],
    notify: typeof b.notify === "boolean" ? b.notify : d.notify ?? true,
    screens: b.screens && typeof b.screens === "object" ? b.screens : {},
  };
}

/** A body with the built-in values filled in, for counting and showing changes. */
export function comparable(body, defaults) {
  const d = defaults ?? {};
  const b = body ?? {};
  return {
    sections: { ...d.sections, ...b.sections },
    beta: b.beta ?? d.beta ?? true,
    copy: b.copy ?? {},
    prices: { ...d.prices, ...b.prices },
    stores: { ios_url: "", android_url: "", ...d.stores, ...b.stores },
    faq: b.faq ?? [],
    notify: b.notify ?? d.notify ?? true,
    screens: b.screens ?? {},
  };
}

/** Keys in their given order, grouped by the part before the first dot. */
export function groupKeys(keys) {
  const out = [];
  for (const k of keys ?? []) {
    const prefix = k.split(".")[0];
    let g = out.find((x) => x.prefix === prefix);
    if (!g) out.push((g = { prefix, keys: [] }));
    g.keys.push(k);
  }
  return out;
}

function check3(errs, base, v, max) {
  for (const l of LANG_KEYS) {
    const t = str(v?.[l]).trim();
    if (!t) errs.push({ key: `${base}.${l}`, message: "Missing: all three languages are needed" });
    else if (t.length > max) errs.push({ key: `${base}.${l}`, message: `At most ${max} characters (now ${t.length})` });
  }
}

/** The contract's checks, as [{key, message}] with the server's keys. */
export function checkLanding(body, keys) {
  const errs = [];
  const allowed = new Set(keys ?? []);
  for (const [k, v] of Object.entries(body?.copy ?? {})) {
    if (!allowed.has(k)) errs.push({ key: `copy.${k}`, message: "This text can’t be changed from here" });
    else check3(errs, `copy.${k}`, v, maxFor(k));
  }
  for (const [k] of PRICES) {
    const v = body?.prices?.[k];
    if (v == null) continue;
    if (typeof v !== "string") errs.push({ key: `prices.${k}`, message: "Must be text, like €4.99" });
    else if (v.trim().length > PRICE_MAX) errs.push({ key: `prices.${k}`, message: `At most ${PRICE_MAX} characters, like €4.99` });
  }
  for (const [k, , prefix] of STORES) {
    const v = str(body?.stores?.[k]).trim();
    if (v && !v.startsWith(prefix)) errs.push({ key: `stores.${k}`, message: `Leave empty or start with ${prefix}` });
  }
  (body?.faq ?? []).forEach((item, i) => {
    check3(errs, `faq.${i}.q`, item?.q, TEXT_MAX);
    check3(errs, `faq.${i}.a`, item?.a, TEXT_MAX);
  });
  return errs;
}

/** Messages for one field (a key or its languages); the languages a message is about are named first. */
export function errorsFor(errors, base) {
  const byMsg = new Map();
  for (const e of errors ?? []) {
    const rest = e.key === base ? "" : e.key?.startsWith(`${base}.`) ? e.key.slice(base.length + 1) : null;
    if (rest == null) continue;
    if (!byMsg.has(e.message)) byMsg.set(e.message, new Set());
    byMsg.get(e.message).add(LANG_KEYS.includes(rest) ? rest.toUpperCase() : "");
  }
  return [...byMsg].map(([msg, langs]) => {
    const ls = LANG_KEYS.map((l) => l.toUpperCase()).filter((l) => langs.has(l));
    return langs.has("") || !ls.length ? msg : `${ls.join(", ")} · ${msg}`;
  });
}

/** Changes counted per field: a copy text or an FAQ list counts once, not per language. */
export function fieldChanges(a, b) {
  const flat = (x) => {
    const out = {};
    for (const [g, v] of Object.entries(x ?? {})) {
      if (v && typeof v === "object" && !Array.isArray(v)) for (const [k, w] of Object.entries(v)) out[`${g}.${k}`] = JSON.stringify(w);
      else out[g] = JSON.stringify(v);
    }
    return out;
  };
  const x = flat(a);
  const y = flat(b);
  return [...new Set([...Object.keys(x), ...Object.keys(y)])].filter((k) => x[k] !== y[k]).length;
}

/** A copy of [body] with one copy override set; all languages empty removes it. */
export function setCopy(body, key, value) {
  const out = structuredClone(body);
  out.copy = { ...out.copy };
  if (blank3(value)) delete out.copy[key];
  else out.copy[key] = { en: str(value.en), ar: str(value.ar), es: str(value.es) };
  return out;
}

export function resetCopy(body, key) {
  const out = structuredClone(body);
  out.copy = { ...out.copy };
  delete out.copy[key];
  return out;
}

/** What is sent: text trimmed, empty overrides and empty prices dropped. */
export function cleanBody(body) {
  const out = structuredClone(body);
  out.copy = Object.fromEntries(Object.entries(out.copy ?? {}).filter(([, v]) => !blank3(v)).map(([k, v]) => [k, trim3(v)]));
  out.prices = Object.fromEntries(Object.entries(out.prices ?? {}).map(([k, v]) => [k, typeof v === "string" ? v.trim() : v]).filter(([, v]) => v !== ""));
  out.stores = Object.fromEntries(Object.entries(out.stores ?? {}).map(([k, v]) => [k, str(v).trim()]));
  out.faq = (out.faq ?? []).map((it) => ({ q: trim3(it?.q), a: trim3(it?.a) }));
  out.screens = Object.fromEntries(Object.entries(out.screens ?? {}).filter(([, v]) => typeof v === "string" && v));
  return out;
}

/** A copy of [list] with item i moved by delta (−1 up, +1 down); out of range leaves it. */
export function moveItem(list, i, delta) {
  const j = i + delta;
  const out = [...list];
  if (i < 0 || i >= out.length || j < 0 || j >= out.length) return out;
  [out[i], out[j]] = [out[j], out[i]];
  return out;
}

/** Text split on *word* pairs: the italic accent. An unpaired * stays as text. */
export function accentParts(text) {
  const out = [];
  const re = /\*([^*]+)\*/g;
  let last = 0;
  let m;
  const s = str(text);
  while ((m = re.exec(s))) {
    if (m.index > last) out.push({ text: s.slice(last, m.index), em: false });
    out.push({ text: m[1], em: true });
    last = m.index + m[0].length;
  }
  if (last < s.length) out.push({ text: s.slice(last), em: false });
  return out;
}
