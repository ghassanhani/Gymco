// The push campaign rules the server enforces, mirrored so the editor can
// say what will happen before saving: quiet hours (22:00–07:59 local move
// to 08:00) and one campaign per ISO week.

const pad = (n) => String(n).padStart(2, "0");

const parts = (local) => {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(local ?? "");
  return m ? m.slice(1).map(Number) : null;
};

/** Where a send time lands after quiet hours: { send_at_local, moved }. */
export function quietHours(local) {
  const p = parts(local);
  if (!p) return { send_at_local: local, moved: false };
  const [y, mo, d, hh] = p;
  if (hh >= 8 && hh < 22) return { send_at_local: local, moved: false };
  const day = new Date(Date.UTC(y, mo - 1, d + (hh >= 22 ? 1 : 0)));
  return { send_at_local: `${day.getUTCFullYear()}-${pad(day.getUTCMonth() + 1)}-${pad(day.getUTCDate())}T08:00`, moved: true };
}

/** The editor's hint for a time inside quiet hours, or null. */
export function quietNote(local) {
  const r = quietHours(local);
  return r.moved ? `${local.slice(11, 16)} is inside quiet hours · phones in each time zone get it at 08:00 their time instead` : null;
}

/** "2026-W43" for a local date or date-time string. */
export function isoWeek(local) {
  const p = parts(`${local.slice(0, 10)}T00:00`);
  if (!p) return null;
  const d = new Date(Date.UTC(p[0], p[1] - 1, p[2]));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const jan1 = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return `${d.getUTCFullYear()}-W${pad(Math.ceil(((d - jan1) / 86400000 + 1) / 7))}`;
}

/** The campaign already holding this week, if any (scheduled or sent). */
export const weekTakenBy = (campaigns, local, exceptId = null) =>
  campaigns.find((c) => c.id !== exceptId && (c.status === "scheduled" || c.status === "sent") && isoWeek(c.send_at_local) === isoWeek(local)) ?? null;

/** The same time of day on another date: "2026-10-30" + "…T09:30" → "2026-10-30T09:30". */
export const onDate = (date, local) => `${date}T${local.slice(11, 16) || "09:00"}`;
