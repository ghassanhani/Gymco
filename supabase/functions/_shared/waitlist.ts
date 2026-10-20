// The landing page's "Notify me": what a sign-up must hold (the table's
// limits) and the day's ceiling. No auth, so the ceiling bounds a flood.

/** Sign-ups a UTC day from everyone together. */
export const WAITLIST_DAILY_LIMIT = 500;

export type WaitlistLocale = "en" | "ar" | "es";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function parseSignup(input: unknown): { ok: true; row: { email: string; locale: WaitlistLocale } } | { ok: false; row: null } {
  const b = (input && typeof input === "object" && !Array.isArray(input) ? input : {}) as Record<string, unknown>;
  const email = typeof b.email === "string" ? b.email.trim().toLowerCase() : "";
  if (!EMAIL.test(email) || email.length > 320) return { ok: false, row: null };
  const locale = b.locale === "ar" || b.locale === "es" ? b.locale : "en";
  return { ok: true, row: { email, locale } };
}

/** True once today's sign-ups reach the ceiling. */
export const overWaitlistCeiling = (today: number) => today >= WAITLIST_DAILY_LIMIT;
