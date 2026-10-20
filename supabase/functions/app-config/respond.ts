// What a phone gets from app-config: the published config resolved for that
// device, the current pack versions, live announcements aimed at it, and the
// release note for its build when one is published.

import { type Device, resolve, validate } from "../_shared/config_schema.ts";
import { canonicalJson } from "../_shared/packs.ts";

interface Announcement {
  id: number;
  starts_at: string;
  ends_at: string;
  status: string;
  targeting: { platform?: string; locale?: string; min_build?: number; max_build?: number };
  [k: string]: unknown;
}

export interface ReleaseNote {
  build: number;
  version: string;
  body: unknown;
  published: boolean;
}

export function deviceOf(url: URL): Device {
  const q = url.searchParams;
  const int = (k: string, max: number) => {
    const n = Number(q.get(k));
    return q.has(k) && Number.isInteger(n) && n >= 0 && n <= max ? n : undefined;
  };
  const platform = q.get("platform");
  const locale = q.get("locale");
  return {
    platform: platform === "ios" || platform === "android" ? platform : undefined,
    locale: locale === "en" || locale === "ar" || locale === "es" ? locale : undefined,
    build: int("build", 1_000_000),
    bucket: int("bucket", 99),
  };
}

const aimedAt = (t: Announcement["targeting"], d: Device) =>
  (!t.platform || t.platform === d.platform) &&
  (!t.locale || t.locale === d.locale) &&
  (t.min_build == null || (d.build ?? 0) >= t.min_build) &&
  (t.max_build == null || (d.build ?? 0) <= t.max_build);

export function respond(input: {
  config: { version: number; body: unknown } | null;
  packs: { kind: string; version: number; checksum: string }[];
  announcements: Announcement[];
  release_notes?: ReleaseNote[];
  device: Device;
  now: Date;
}) {
  const body = validate(input.config?.body ?? {}).body;
  const { now, device } = input;
  return {
    config_version: input.config?.version ?? 0,
    config: resolve(body, device),
    packs: Object.fromEntries(input.packs.map((p) => [p.kind, { version: p.version, checksum: p.checksum }])),
    announcements: input.announcements
      .filter((a) => a.status === "published" && new Date(a.starts_at) <= now && now < new Date(a.ends_at) && aimedAt(a.targeting ?? {}, device))
      .map(({ status: _s, targeting: _t, ...a }) => a),
    whats_new: whatsNew(input.release_notes ?? [], device.build),
    generated_at: now.toISOString(),
  };
}

function whatsNew(notes: ReleaseNote[], build: number | undefined) {
  const n = build == null ? undefined : notes.find((x) => x.published && x.build === build);
  return n ? { build: n.build, version: n.version, body: n.body } : null;
}

/**
 * One published pack. The body goes out as the canonical string the checksum
 * was computed over at save time, so the phone hashes exactly what it got.
 */
export function packReply(row: { kind: string; version: number; checksum: string; body: unknown }) {
  return { kind: row.kind, version: row.version, checksum: row.checksum, body_json: canonicalJson(row.body) };
}

/** Which website document a request asks for: "landing", "unknown" for any other ?site=, or null without one. */
export function siteOf(url: URL): "landing" | "unknown" | null {
  const site = url.searchParams.get("site");
  return site == null ? null : site === "landing" ? "landing" : "unknown";
}

/** The published landing document for gymcoapp.com/, or version 0 with no body when none is published. */
export function landingReply(row: { version: number; body: unknown } | null) {
  return row ? { version: row.version, body: row.body } : { version: 0, body: null };
}
