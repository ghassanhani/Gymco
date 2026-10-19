// Rules for push campaigns: nothing in quiet hours, one campaign a week.
// Times are the device's local time, "YYYY-MM-DDTHH:MM", never converted.

export const QUIET_FROM = 22;
export const QUIET_UNTIL = 8;

/** A local time as a Date whose UTC fields hold the local ones; null when not "YYYY-MM-DDTHH:MM". */
export function parseLocal(s: unknown): Date | null {
  if (typeof s !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s)) return null;
  const d = new Date(`${s}:00Z`);
  return Number.isNaN(d.getTime()) || d.toISOString().slice(0, 16) !== s ? null : d;
}

const fmt = (d: Date) => d.toISOString().slice(0, 16);

/** Moves a time inside quiet hours (22:00–07:59) to 08:00: the same day, or the next when it was ≥ 22:00. */
export function outsideQuietHours(sendAtLocal: string): { send_at_local: string; moved: boolean } {
  const d = parseLocal(sendAtLocal);
  if (!d) throw new Error("bad local time");
  const h = d.getUTCHours();
  if (h >= QUIET_UNTIL && h < QUIET_FROM) return { send_at_local: sendAtLocal, moved: false };
  if (h >= QUIET_FROM) d.setUTCDate(d.getUTCDate() + 1);
  d.setUTCHours(QUIET_UNTIL, 0, 0, 0);
  return { send_at_local: fmt(d), moved: true };
}

/** ISO 8601 week, as "YYYY-Www". */
export function isoWeek(sendAtLocal: string): string {
  const d = parseLocal(sendAtLocal) ?? new Date(sendAtLocal);
  const t = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  // Shift to the Thursday of this week: its year is the ISO year.
  t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
  const jan1 = Date.UTC(t.getUTCFullYear(), 0, 1);
  const week = Math.ceil(((t.getTime() - jan1) / 86_400_000 + 1) / 7);
  return `${t.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

export interface WeekSlot {
  id: number;
  send_at_local: string;
  status: string;
}

const holds = (c: WeekSlot) => c.status === "scheduled" || c.status === "sent";

/** Another campaign scheduled or sent in the same ISO week, or null. */
export function weekTakenBy<T extends WeekSlot>(campaigns: T[], sendAtLocal: string, selfId?: number): T | null {
  const week = isoWeek(sendAtLocal);
  return campaigns.find((c) => c.id !== selfId && holds(c) && isoWeek(c.send_at_local) === week) ?? null;
}

/** The Monday of the first ISO week after [sendAtLocal]'s week with no campaign in it. */
export function nextFreeDate(campaigns: WeekSlot[], sendAtLocal: string): string {
  const taken = new Set(campaigns.filter(holds).map((c) => isoWeek(c.send_at_local)));
  const d = parseLocal(sendAtLocal) ?? new Date(sendAtLocal);
  d.setUTCHours(0, 0, 0, 0);
  // Back to Monday, then forward a week at a time.
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  for (let i = 0; i < 520; i++) {
    d.setUTCDate(d.getUTCDate() + 7);
    if (!taken.has(isoWeek(fmt(d)))) break;
  }
  return d.toISOString().slice(0, 10);
}
