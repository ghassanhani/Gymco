// Pure helpers for the Support inbox: tab labels with counts, ticket age,
// the 30-day deletion deadline and reply templates.

import { dayLabel } from "./format.js";

export const DAY = 86400000;

export const TABS = [["new", "New"], ["waiting", "Waiting"], ["solved", "Solved"], ["deletion", "Deletion requests"]];

export const LANG_NAME = { en: "English", ar: "Arabic", es: "Spanish" };

export const TEMPLATE_LABEL = { deletion_confirmed: "Deletion confirmed", restore_help: "Restore help", cap_reset: "Scan cap reset", nothing_stored: "Nothing stored" };

/** "New · 4", "Solved" (no count), "Deletion requests · 2". */
export function tabLabel(id, counts = {}) {
  const n = { new: counts.new, waiting: counts.waiting, deletion: counts.deletion_open }[id];
  const name = TABS.find(([k]) => k === id)?.[1] ?? id;
  return n ? `${name} · ${n}` : name;
}

/** How long a ticket has waited: "Just now", "35 min", "6 h", "3 d". */
export function ageLabel(iso, now = new Date()) {
  const s = Math.max(0, (now - new Date(iso)) / 1000);
  if (s < 90) return "Just now";
  if (s < 3600) return `${Math.round(s / 60)} min`;
  if (s < DAY / 1000) return `${Math.round(s / 3600)} h`;
  return `${Math.floor(s / (DAY / 1000))} d`;
}

/** A new ticket nobody has answered for over 24 hours is shown in red. */
export const ageLate = (t, now = new Date()) => t.status === "new" && now - new Date(t.created_at) > DAY;

/** Whole days until the deadline; negative when it has passed. */
export const daysLeft = (deadlineAt, now = new Date()) => (deadlineAt ? Math.ceil((new Date(deadlineAt) - now) / DAY) : null);

/** The big number on a deletion ticket: yellow from 7 days, red once overdue. */
export function deadlineLine(days, deadlineAt) {
  if (days == null) return null;
  const from = deadlineAt ? dayLabel(new Date(new Date(deadlineAt) - 30 * DAY).toISOString()) : null;
  const legal = from ? `Legal deadline: 30 days from ${from}` : "Legal deadline: 30 days";
  if (days < 0) return { number: `−${-days}`, label: `day${days === -1 ? "" : "s"} overdue`, tone: "bad", legal };
  return { number: String(days), label: `day${days === 1 ? "" : "s"} left to complete deletion`, tone: days <= 7 ? "warn" : "", legal };
}

/** "user@example.com · Arabic · v1.0.2 · via support@gymcoapp.com". */
export function ticketMeta(t) {
  const via = { email: "via support@gymcoapp.com", app: "via the in-app form", admin: "added here" }[t.source] ?? (t.source ? `via ${t.source}` : null);
  return [t.email, LANG_NAME[t.locale] ?? t.locale, t.app_version ? `v${t.app_version}` : null, via].filter(Boolean).join(" · ");
}

export const fillTemplate = (text, email) => String(text ?? "").replaceAll("{email}", email ?? "");

/** Tickets that match a search, by subject, email or tag (case-insensitive). */
export function matchTickets(items, q) {
  const needle = (q ?? "").trim().toLowerCase();
  if (!needle) return items;
  return items.filter((t) => `${t.subject} ${t.email} ${(t.tags ?? []).join(" ")}`.toLowerCase().includes(needle));
}
