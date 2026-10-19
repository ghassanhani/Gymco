// 01 Overview: today at a glance. Every number is a server-side count.

import { alertsFor } from "../lib/alerts.js";
import { h } from "../lib/dom.js";
import { dayLabel, delta, fmtBytes, fmtEur, fmtInt, mixRows, relTime } from "../lib/format.js";
import { alertStrip, chip, dailyChart, empty, kpi, mixList, pageHead, statusChip, table } from "../lib/ui.js";

const FREE_DB = 500_000_000;
const LANG = { en: "English", ar: "Arabic", es: "Spanish" };
const PLATFORM = { ios: "iOS", android: "Android" };
const SECTION = { accounts: "Accounts", team: "Team", config: "Remote config", content: "Content", plans: "Plans", messaging: "Messaging", support: "Support", releases: "Releases", website: "Website" };

const sum = (xs) => xs.reduce((a, d) => a + d.n, 0);
const optional = (p) => p.catch(() => null);

export async function render(el, { call, isCurrent }) {
  let range = 90;
  const [stats, audit, config, tickets] = await Promise.all([
    call("stats", { range: 90 }),
    optional(call("audit.list", { limit: 5 })),
    optional(call("config.get")),
    optional(call("tickets.list", { tab: "new" })),
  ]);
  if (!isCurrent()) return;

  const body = h("div", { class: "stack", style: { gap: "24px" } });
  const pills = h("div", { class: "pills", role: "group", "aria-label": "Range" });
  function drawPills() {
    pills.replaceChildren(...[7, 30, 90].map((r) =>
      h("button", { type: "button", class: "pill", "aria-pressed": String(r === range), on: { click: () => { range = r; drawPills(); draw(); } } }, `${r} days`)));
  }
  const today = new Date();
  el.append(pageHead(`Monitor · ${today.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" })}`, "Today at", "a glance", pills), body);
  drawPills();

  function draw() {
    const s = stats;
    const su = s.signups.slice(-range);
    const sc = s.scans.slice(-range);
    const last7 = sum(s.signups.slice(-7));
    const prev7 = sum(s.signups.slice(-14, -7));
    const yesterdayScans = s.scans.at(-2)?.n ?? 0;
    const budget = config?.published?.body?.ai?.daily_budget_eur ?? config?.defaults?.ai?.daily_budget_eur;
    const capNow = config?.published?.body?.limits?.ai_scans_per_day ?? 10;
    const cumulative = s.signups.reduce((acc, d) => (acc.push((acc.at(-1) ?? s.accounts - sum(s.signups)) + d.n), acc), []);
    const alerts = alertsFor({ stats: s, config: config?.published?.body ?? null, tickets: tickets?.items ?? null });
    const scanDelta = budget ? { text: `${Math.round(((s.cost_today ?? 0) / budget) * 100)}% budget`, tone: (s.cost_today ?? 0) / budget >= 0.8 ? "warn" : "flat" } : delta(s.scans_today, yesterdayScans);

    const tiles = [
      { label: "Total accounts", value: fmtInt(s.accounts), delta: `+${fmtInt(s.signups_30d)} in 30 d`, tone: s.signups_30d ? "good" : "flat", spark: cumulative.slice(-30) },
      { label: "Sign-ups · 7 d", value: fmtInt(last7), ...pick(delta(last7, prev7)), spark: s.signups.slice(-14).map((d) => d.n) },
      { label: "Active · backup 7 d", value: fmtInt(s.active_7d), delta: `${fmtInt(s.active_30d)} in 30 d`, tone: "flat" },
      { label: "AI scans today", value: fmtInt(s.scans_today), ...pick(scanDelta), spark: s.scans.slice(-14).map((d) => d.n), sparkTone: scanDelta.tone === "warn" ? "warn" : "chart-1" },
      { label: "Est. AI cost today", value: fmtEur(s.cost_today), delta: `${fmtEur(s.cost_month)} this month`, tone: "flat", spark: s.scans.slice(-14).map((d) => d.cost), sparkTone: "chart-2" },
      { label: "At scan cap today", value: fmtInt(s.at_cap_today), delta: `cap ${capNow}`, tone: "flat" },
      { label: "Deletions · 30 d", value: fmtInt(s.deletions_30d), ...pick(delta(sum(s.deletions.slice(-30)), sum(s.deletions.slice(-60, -30)), { lowerIsBetter: true })), spark: s.deletions.slice(-14).map((d) => d.n) },
      { label: "Database size", value: fmtBytes(s.db_bytes), delta: `${Math.round((s.db_bytes / FREE_DB) * 100)}% of plan`, tone: s.db_bytes / FREE_DB > 0.8 ? "warn" : "flat" },
    ];

    const trendNote = s.accounts < 1 || s.signups.filter((d) => d.n).length < 2
      ? h("p", { class: "small muted", style: { margin: "0" } }, "Not enough data yet. Trends fill in as days pass; totals are live now.")
      : null;

    body.replaceChildren(
      alertStrip(alerts) ?? h("span", { class: "sr" }, "No alerts"),
      h("section", { "aria-label": "Key numbers", class: "grid kpis" }, tiles.map(kpi)),
      h("section", { class: "grid two" },
        h("div", { class: "card" },
          h("div", { class: "card-head" }, h("h2", {}, "Daily sign-ups"), h("span", { class: "small muted" }, `Last ${range} days`)),
          dailyChart({ series: su, label: `Daily sign-ups over ${range} days` }), trendNote),
        h("div", { class: "card" },
          h("div", { class: "card-head" }, h("h2", {}, "AI scans & cost"),
            h("div", { class: "legend" }, h("span", {}, h("i", {}), "Scans"), h("span", {}, h("i", { class: "line" }), "Cost (EUR)"))),
          dailyChart({ series: sc, label: `Daily AI scans as bars with cost per day as a line, last ${range} days`, kind: "bar", second: sc.map((d) => d.cost), secondLabel: "Cost", fmt2: fmtEur }))),
      h("section", { class: "row" },
        h("div", { class: "card", style: { flex: "1 1 320px" } },
          h("h2", {}, "Account mix"),
          mixList("App language", mixRows(s.mix?.locale ?? {}, LANG)),
          mixList("Platform", mixRows(s.mix?.platform ?? {}, PLATFORM), true),
          h("p", { class: "small muted", style: { margin: "0" } }, "From backup metadata only. Gymco sends no usage analytics.")),
        h("div", { class: "card", style: { flex: "2 1 560px" } },
          h("div", { class: "card-head" }, h("h2", {}, "Recent changes"), h("a", { href: "#/team", class: "small", style: { fontWeight: "600" } }, "Audit log")),
          audit
            ? table([
                { label: "Change", class: "strong", cell: (r) => describe(r) },
                { label: "Section", cell: (r) => SECTION[r.section] ?? r.section },
                { label: "By", cell: (r) => r.admin_email.split("@")[0] },
                { label: "Status", cell: (r) => (r.after?.status ? statusChip(r.after.status) : chip("Done", r.action.startsWith("delete") ? "bad" : "good")) },
                { label: "When", end: true, cell: (r) => relTime(r.at) },
              ], audit.entries, { empty: empty("Nothing changed yet", "Every change made here will be listed, with who, when and why.") })
            : h("p", { class: "muted small" }, "The audit log needs the Owner role."))));
  }
  draw();
}

const pick = (d) => ({ delta: d.text, tone: d.tone });

function describe(r) {
  const what = { lookup: "Opened an account", reset_cap: "Reset scan cap", grant_scans: "Granted extra scans", resend_code: "Resent sign-in code", delete_backup: "Deleted a backup", delete_account: "Deleted account + backup", grant_plan: "Granted a plan", revoke_plan: "Revoked a plan", note: "Added a note", invite: "Invited an admin", set_role: "Changed a role", remove: "Removed an admin", audit_export: "Exported the audit log" };
  return what[r.action] ?? `${r.action}${r.object_id ? ` · ${r.object_id}` : ""}`;
}

export const _test = { describe, dayLabel };
