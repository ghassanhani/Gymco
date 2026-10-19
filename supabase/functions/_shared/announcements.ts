// What an announcement must hold before it can be saved, and the warnings
// shown beside the editor: an overlap with a live announcement for the same
// audience, and voice-check hits.

import { type Lang, voiceIssues } from "./voice.ts";

export interface T3 {
  en: string;
  ar: string;
  es: string;
}
export interface Targeting {
  platform?: "ios" | "android";
  locale?: Lang;
  min_build?: number;
  max_build?: number;
}
export interface Issue {
  key: string;
  message: string;
}
export interface AnnouncementBody {
  title: T3;
  body: T3;
  cta: { label: T3; url: string } | null;
  starts_at: string;
  ends_at: string;
  targeting: Targeting;
}

const LANGS: Lang[] = ["en", "ar", "es"];

/** Every language present and trimmed, each within [max] characters. */
export function checkT3(v: unknown, key: string, max: number): { value: T3; errors: Issue[] } {
  const src = (v && typeof v === "object" ? v : {}) as Record<string, unknown>;
  const value = { en: "", ar: "", es: "" };
  const errors: Issue[] = [];
  for (const l of LANGS) {
    const s = typeof src[l] === "string" ? (src[l] as string).trim() : "";
    value[l] = s;
    if (!s) errors.push({ key: `${key}.${l}`, message: "Needed in English, Arabic and Spanish" });
    else if (s.length > max) errors.push({ key: `${key}.${l}`, message: `Keep it under ${max} characters` });
  }
  return { value, errors };
}

/** Only the targeting keys the app understands. */
export function cleanTargeting(t: unknown): Targeting {
  const src = (t && typeof t === "object" ? t : {}) as Record<string, unknown>;
  const out: Targeting = {};
  if (src.platform === "ios" || src.platform === "android") out.platform = src.platform;
  if (src.locale === "en" || src.locale === "ar" || src.locale === "es") out.locale = src.locale;
  if (Number.isInteger(src.min_build)) out.min_build = src.min_build as number;
  if (Number.isInteger(src.max_build)) out.max_build = src.max_build as number;
  return out;
}

const date = (v: unknown) => (typeof v === "string" && !Number.isNaN(Date.parse(v)) ? new Date(v).toISOString() : null);

export function validateAnnouncement(input: unknown): { ok: boolean; body: AnnouncementBody; errors: Issue[] } {
  const b = (input && typeof input === "object" ? input : {}) as Record<string, unknown>;
  const errors: Issue[] = [];
  const title = checkT3(b.title, "title", 80);
  const body = checkT3(b.body, "body", 500);
  errors.push(...title.errors, ...body.errors);
  let cta: AnnouncementBody["cta"] = null;
  if (b.cta && typeof b.cta === "object") {
    const c = b.cta as Record<string, unknown>;
    const label = checkT3(c.label, "cta.label", 80);
    errors.push(...label.errors);
    const url = typeof c.url === "string" ? c.url.trim() : "";
    if (!/^https:\/\/\S+$/.test(url)) errors.push({ key: "cta.url", message: "Link must start with https://" });
    cta = { label: label.value, url };
  }
  const starts = date(b.starts_at);
  const ends = date(b.ends_at);
  if (!starts) errors.push({ key: "starts_at", message: "Enter a start date" });
  if (!ends) errors.push({ key: "ends_at", message: "Enter an end date" });
  else if (starts && ends <= starts) errors.push({ key: "ends_at", message: "End date is before the start date." });
  return {
    ok: errors.length === 0,
    body: { title: title.value, body: body.value, cta, starts_at: starts ?? "", ends_at: ends ?? "", targeting: cleanTargeting(b.targeting) },
    errors,
  };
}

interface Live {
  id: number;
  status: string;
  starts_at: string;
  ends_at: string;
  targeting: unknown;
}

/** Two audiences meet unless a platform, locale or build range keeps them apart. */
export function audiencesOverlap(a: Targeting, b: Targeting): boolean {
  if (a.platform && b.platform && a.platform !== b.platform) return false;
  if (a.locale && b.locale && a.locale !== b.locale) return false;
  const lo = Math.max(a.min_build ?? 0, b.min_build ?? 0);
  const hi = Math.min(a.max_build ?? Infinity, b.max_build ?? Infinity);
  return lo <= hi;
}

export function overlapWarning(mine: { starts_at: string; ends_at: string; targeting?: unknown }, others: Live[], now: Date, selfId?: number): Issue | null {
  const s = Date.parse(mine.starts_at), e = Date.parse(mine.ends_at);
  const t = cleanTargeting(mine.targeting);
  const n = others.filter((o) =>
    o.id !== selfId && o.status === "published" && Date.parse(o.ends_at) > now.getTime() &&
    Date.parse(o.starts_at) < e && Date.parse(o.ends_at) > s && audiencesOverlap(t, cleanTargeting(o.targeting))
  ).length;
  if (!n) return null;
  return { key: "starts_at", message: `Overlaps ${n} live announcement${n === 1 ? "" : "s"} · only the newest shows` };
}

/** Voice-check hits for every language of the title and body (and a cta label), keyed by field. */
export function voiceWarnings(b: { title: T3; body: T3; cta?: { label: T3 } | null }): Issue[] {
  const out: Issue[] = [];
  const fields: [string, T3][] = [["title", b.title], ["body", b.body], ...(b.cta ? [["cta.label", b.cta.label] as [string, T3]] : [])];
  for (const [key, t] of fields) {
    for (const l of LANGS) {
      for (const hit of voiceIssues(t[l] ?? "", l)) out.push({ key: `${key}.${l}`, message: `“${hit.phrase}” ${hit.hint}` });
    }
  }
  return out;
}
