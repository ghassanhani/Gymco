// Made-up answers from the admin function, for the screenshot harness.
// None of this is real user data.

const days = (n) => Array.from({ length: n }, (_, i) => new Date(Date.UTC(2026, 9, 19 - (n - 1) + i)).toISOString().slice(0, 10));
const wave = (base, i, amp = 0.5) => Math.max(0, Math.round(base * (1 + amp * Math.sin(i / 5)) + i * base * 0.01));

export function stats(empty) {
  const d = days(90);
  return {
    range: 90,
    accounts: empty ? 0 : 1284,
    signups_today: empty ? 0 : 21,
    signups_7d: empty ? 0 : 148,
    signups_30d: empty ? 0 : 560,
    active_7d: empty ? 0 : 412,
    active_30d: empty ? 0 : 903,
    scans_today: empty ? 0 : 162,
    cost_today: empty ? 0 : 0.081,
    cost_month: empty ? 0 : 1.37,
    at_cap_today: empty ? 0 : 4,
    deletions_30d: empty ? 0 : 6,
    signups: d.map((day, i) => ({ day, n: empty ? 0 : wave(12 + i / 4, i) })),
    scans: d.map((day, i) => { const n = empty ? 0 : wave(110, i, 0.4); return { day, n, cost: +(n * 0.0005).toFixed(4) }; }),
    deletions: d.map((day, i) => ({ day, n: empty ? 0 : i % 13 === 0 ? 1 : 0 })),
    ai_failure_rate_today: 0,
    backups: { count: empty ? 0 : 1190, bytes: empty ? 0 : 38_400_000 },
    db_bytes: empty ? 9_100_000 : 61_700_000,
    mix: empty ? { locale: {}, platform: {}, app_version: {} } : { locale: { en: 610, ar: 330, es: 120, unknown: 130 }, platform: { ios: 700, android: 360, unknown: 130 }, app_version: { "1.0.2": 900, "1.0.1": 160, unknown: 130 } },
    generated_at: "2026-10-19T14:05:00Z",
  };
}

const card = {
  user_id: "u-1",
  email: "user@example.com",
  created_at: "2026-03-12T10:00:00Z",
  last_sign_in_at: "2026-10-18T20:00:00Z",
  backup: { updated_at: "2026-10-19T12:14:00Z", bytes: 4_200_000, platform: "ios", locale: "ar", app_version: "1.0.2" },
  scans_today: 10,
  scans_30d: 142,
  cap_today: 10,
  grant_today: null,
  entitlement: null,
  notes: [{ note: "Emailed about restore issue, asked for app version.", by: "owner@gymco.test", at: "2026-10-17T09:00:00Z" }],
  is_admin: false,
};

const audit = [
  { id: 5, at: "2026-10-19T09:42:00Z", admin_email: "owner@gymco.test", section: "accounts", action: "reset_cap", object_id: "u-1", reason: "support_ticket", before: null, after: { scans_today: 0 } },
  { id: 4, at: "2026-10-18T16:00:00Z", admin_email: "owner@gymco.test", section: "team", action: "invite", object_id: "helper@gymco.test", reason: null, before: null, after: { email: "helper@gymco.test", role: "support" } },
  { id: 3, at: "2026-10-17T11:00:00Z", admin_email: "owner@gymco.test", section: "accounts", action: "delete_account", object_id: "u-9", reason: "deletion_request", before: { account: true }, after: { account: false } },
];

const admins = [
  { user_id: "u-owner", email: "owner@gymco.test", role: "owner", mfa: true, last_sign_in_at: "2026-10-19T08:00:00Z" },
  { user_id: "u-help", email: "helper@gymco.test", role: "support", mfa: false, last_sign_in_at: null },
];

/** [status, body] for one admin request. */
export function fixtures(body, { role, empty }) {
  switch (body.action) {
    case "me": return [200, { email: "owner@gymco.test", role }];
    case "stats": return [200, stats(empty)];
    case "audit.list": return [200, { entries: empty ? [] : audit }];
    case "audit.export": return [200, { csv: "at,admin\n" }];
    case "team.list": return [200, { admins }];
    case "account.lookup": return body.email === card.email ? [200, card] : [404, { error: "no_account" }];
    default: return [400, { error: "unknown_action" }];
  }
}
