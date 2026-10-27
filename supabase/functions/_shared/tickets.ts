// Support tickets: what a ticket must hold (the table's limits), the 30-day
// deletion deadline, and the reply link used when no email service is set.

export const DAILY_LIMIT = 5;
/** Tickets a day from everyone together: the form has no auth, so this bounds a flood. */
export const GLOBAL_DAILY_LIMIT = 300;
const DAY_MS = 86_400_000;

export interface TicketRow {
  email: string;
  subject: string;
  body: string;
  locale: "en" | "ar" | "es" | null;
  app_version: string | null;
  platform: "ios" | "android" | null;
  kind: "general" | "deletion" | "feature";
}

export interface FieldError {
  key: string;
  message: string;
}

const KINDS: TicketRow["kind"][] = ["general", "deletion", "feature"];
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");

export function parseTicket(input: unknown): { ok: true; row: TicketRow; errors: [] } | { ok: false; row: null; errors: FieldError[] } {
  const b = (input && typeof input === "object" ? input : {}) as Record<string, unknown>;
  const errors: FieldError[] = [];
  const email = str(b.email).toLowerCase();
  if (!EMAIL.test(email) || email.length > 320) errors.push({ key: "email", message: "Enter a valid email address" });
  const subject = str(b.subject);
  if (subject.length < 1 || subject.length > 200) errors.push({ key: "subject", message: "1 to 200 characters" });
  const body = str(b.body);
  if (body.length < 1 || body.length > 5000) errors.push({ key: "body", message: "1 to 5000 characters" });
  if (errors.length) return { ok: false, row: null, errors };
  const locale = ["en", "ar", "es"].includes(str(b.locale)) ? (str(b.locale) as TicketRow["locale"]) : null;
  const platform = ["ios", "android"].includes(str(b.platform)) ? (str(b.platform) as TicketRow["platform"]) : null;
  const app_version = str(b.app_version).slice(0, 32) || null;
  return { ok: true, row: { email, subject, body, locale, app_version, platform, kind: KINDS.includes(b.kind as TicketRow["kind"]) ? (b.kind as TicketRow["kind"]) : "general" }, errors: [] };
}

/** True once an email has sent today's allowance. */
export const overDailyLimit = (sentToday: number) => sentToday >= DAILY_LIMIT;

/** True once today's tickets from everyone reach the ceiling. */
export const overGlobalLimit = (allToday: number) => allToday >= GLOBAL_DAILY_LIMIT;

/** The row stored for a ticket from the app. Anyone can type any email into the
 *  form, so a deletion request is tagged until support confirms it's the owner.
 *  A feature request is tagged "feature" and has no deadline. */
export const appTicket = (row: TicketRow, now = new Date()) => ({
  ...row,
  source: "app" as const,
  deadline_at: row.kind === "deletion" ? deletionDeadline(now) : null,
  tags: row.kind === "deletion" ? ["unverified"] : row.kind === "feature" ? ["feature"] : [],
});

/** A deletion request must be answered within 30 days. */
export const deletionDeadline = (now = new Date()) => new Date(now.getTime() + 30 * DAY_MS).toISOString();

/** Whole days until [deadline]; negative once it has passed, null without one. */
export function daysLeft(deadline: string | null | undefined, now = new Date()): number | null {
  if (!deadline) return null;
  const t = Date.parse(deadline);
  return Number.isNaN(t) ? null : Math.floor((t - now.getTime()) / DAY_MS);
}

export const mailtoFor = (email: string, subject: string, body: string) =>
  `mailto:${email}?subject=${encodeURIComponent(`Re: ${subject}`)}&body=${encodeURIComponent(body)}`;
