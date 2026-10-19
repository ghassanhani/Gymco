// What push-register accepts: exactly the push_tokens columns, within the
// table's checks, so a bad request is a 400 and never a database error.

export interface TokenRow {
  token: string;
  platform: "ios" | "android";
  locale: "en" | "ar" | "es";
  utc_offset_min: number;
  app_version: string | null;
}

const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");

export function parseRegistration(input: unknown): { ok: true; row: TokenRow } | { ok: false; error: string } {
  const b = (input && typeof input === "object" ? input : {}) as Record<string, unknown>;
  const token = str(b.token);
  if (token.length < 1 || token.length > 4096) return { ok: false, error: "token" };
  const platform = str(b.platform);
  if (platform !== "ios" && platform !== "android") return { ok: false, error: "platform" };
  const locale = str(b.locale);
  if (locale !== "en" && locale !== "ar" && locale !== "es") return { ok: false, error: "locale" };
  const offset = b.utc_offset_min;
  if (typeof offset !== "number" || !Number.isInteger(offset) || offset < -840 || offset > 840) return { ok: false, error: "utc_offset_min" };
  const app_version = str(b.app_version);
  if (app_version.length > 32) return { ok: false, error: "app_version" };
  return { ok: true, row: { token, platform, locale, utc_offset_min: offset, app_version: app_version || null } };
}

export function parseUnregister(input: unknown): string | null {
  const b = (input && typeof input === "object" ? input : {}) as Record<string, unknown>;
  const token = str(b.token);
  return token.length >= 1 && token.length <= 4096 ? token : null;
}
