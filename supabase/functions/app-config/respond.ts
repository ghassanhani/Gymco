// What a phone gets from app-config: the published config resolved for that
// device, the current pack versions, and live announcements aimed at it.

import { type Device, resolve, validate } from "../_shared/config_schema.ts";

interface Announcement {
  id: number;
  starts_at: string;
  ends_at: string;
  status: string;
  targeting: { platform?: string; locale?: string; min_build?: number; max_build?: number };
  [k: string]: unknown;
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
    generated_at: now.toISOString(),
  };
}
