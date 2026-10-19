// 12 System health: edge function errors, database and storage against the
// free plan, services, and where crashes will show once Crashlytics is
// connected. Links out to the consoles for depth instead of copying them.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { fmtBytes, fmtInt, relTime } from "../lib/format.js";
import { chip, empty, errorBanner, pageHead, table } from "../lib/ui.js";

const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const FREE_DB = 500_000_000;
const FREE_STORAGE = 1_000_000_000;
const ALERT_RATE = 0.02;
const LINKS = [
  ["Supabase", "https://supabase.com/dashboard/project/vncadogzpeoawikgafaj"],
  ["Firebase", "https://console.firebase.google.com"],
  ["GitHub", "https://github.com/ghassanhani/Gymco/actions"],
];
const STATE = { ok: ["OK", "good"], warn: ["Check", "warn"], bad: ["Down", "bad"], unknown: ["Unknown", "flat"] };
const pct = (n, of) => Math.min(100, Math.round(((n ?? 0) / of) * 100));

export async function render(el, { call, isCurrent }) {
  const banner = h("div");
  const tiles = h("section", { "aria-label": "Key numbers", class: "grid kpis" });
  const fnCard = h("section", { class: "card" });
  const crashCard = h("section", { class: "card" });
  const servicesCard = h("section", { class: "card" });
  el.append(
    pageHead("Monitor", "System", "health", h("div", { class: "pills" }, LINKS.map(([name, href]) => h("a", { class: "btn small", href, target: "_blank", rel: "noopener" }, name, icon("ext", 16))))),
    banner, tiles, h("div", { class: "grid two" }, fnCard, crashCard), servicesCard);

  async function load() {
    put(banner);
    let d = null;
    try {
      d = await call("health");
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) throw e;
      put(banner, errorBanner("Couldn’t load the numbers", `The health check didn’t answer${e instanceof ApiError && e.status === 0 ? " · you’re offline" : ""}. The links and the Crashlytics note still work.`, load));
    }
    if (!isCurrent()) return;
    drawTiles(d);
    drawFunctions(d);
    drawCrashes();
    drawServices(d);
  }

  /** A tile with a bar: label, value, note, share of the limit. */
  function tile({ label, value, note, share, tone = "", state }) {
    return h("div", { class: "card tight kpi" },
      h("div", { class: "top-line" }, h("span", { class: "label" }, label), state ? chip(state[0], state[1]) : null),
      h("div", { class: "value num" }, value),
      h("span", { class: "small muted" }, note),
      share != null ? h("div", { class: `track ${tone}`, role: "img", "aria-label": `${share}% of the limit` }, h("i", { style: { width: `${share}%` } })) : null);
  }

  function drawTiles(d) {
    const fns = d?.functions ?? [];
    const calls = fns.reduce((a, f) => a + (f.calls ?? 0), 0);
    const errors = fns.reduce((a, f) => a + (f.errors ?? 0), 0);
    const rate = calls ? errors / calls : 0;
    const db = d ? pct(d.db_bytes, FREE_DB) : null;
    const st = d ? pct(d.backups?.bytes, FREE_STORAGE) : null;
    put(tiles,
      tile({ label: "Crash-free sessions", value: "Not set up", note: "Crashlytics isn’t connected yet", state: ["Unknown", "flat"] }),
      tile({ label: "Edge function errors · 24 h", value: d ? `${(rate * 100).toFixed(rate && rate < 0.01 ? 2 : 1)}%` : "—", note: d ? `${fmtInt(errors)} of ${fmtInt(calls)} calls · Alert at 2%` : "Alert at 2%",
        share: d ? Math.min(100, Math.round((rate / ALERT_RATE) * 100)) : null, tone: rate > ALERT_RATE ? "bad" : rate > ALERT_RATE / 2 ? "warn" : "", state: d ? (rate > ALERT_RATE ? ["Errors", "bad"] : ["Healthy", "good"]) : null }),
      tile({ label: "Database size", value: d ? fmtBytes(d.db_bytes) : "—", note: d ? `${db}% of the 500 MB free plan` : "500 MB free plan", share: db, tone: db > 80 ? "warn" : "", state: d ? (db > 80 ? ["Near limit", "warn"] : ["OK", "good"]) : null }),
      tile({ label: "Storage · backups", value: d ? fmtBytes(d.backups?.bytes) : "—", note: d ? `${fmtInt(d.backups?.count)} backups · ${st}% of the 1 GB free plan` : "1 GB free plan", share: st, tone: st > 80 ? "warn" : "", state: d ? (st > 80 ? ["Near limit", "warn"] : ["OK", "good"]) : null }));
  }

  function drawFunctions(d) {
    put(fnCard,
      h("div", { class: "card-head" }, h("h2", {}, "Edge functions · last 24 h"), h("span", { class: "small muted" }, "Alert when error rate passes 2%")),
      d
        ? table([
            { label: "Function", class: "strong", cell: (f) => h("span", { class: "mono" }, f.fn) },
            { label: "Invocations", end: true, cell: (f) => fmtInt(f.calls) },
            { label: "Errors", end: true, cell: (f) => fmtInt(f.errors) },
            { label: "Error rate", end: true, cell: (f) => `${((f.rate ?? 0) * 100).toFixed(1)}%` },
            { label: "Status", cell: (f) => ((f.rate ?? 0) > ALERT_RATE ? chip("Errors", "bad") : chip("Healthy", "good")) },
          ], d.functions ?? [], { empty: empty("No calls yet", "Functions appear here after their first call today or yesterday.") })
        : h("span", { class: "small muted" }, "Numbers arrive once the health check answers."),
      d ? h("span", { class: "small muted" }, `${fmtInt(d.tokens)} push token${d.tokens === 1 ? "" : "s"} · ${fmtInt(d.tickets?.new)} new ticket${d.tickets?.new === 1 ? "" : "s"} · as of ${relTime(d.generated_at)}`) : null);
  }

  function drawCrashes() {
    put(crashCard,
      h("div", { class: "card-head" }, h("h2", {}, "Top crashes"), chip("Not connected", "flat")),
      empty("Crashlytics isn’t connected yet", "Crash-free sessions and the top crashes appear here once Firebase Crashlytics is configured in the app.",
        h("a", { class: "btn small", href: "https://console.firebase.google.com", target: "_blank", rel: "noopener" }, "Set up Crashlytics", icon("ext", 16))));
  }

  function drawServices(d) {
    const rows = d?.services ?? [];
    put(servicesCard,
      h("div", { class: "card-head" }, h("h2", {}, "Services"), d?.ci ? h("a", { class: "small", href: d.ci.url, target: "_blank", rel: "noopener", style: { fontWeight: "600" } }, `${d.ci.name} run · ${d.ci.status} · ${relTime(d.ci.when)}`) : null),
      rows.length
        ? h("div", { class: "stack", style: { gap: "0" } }, rows.map((s) => {
            const [label, tone] = STATE[s.state] ?? STATE.unknown;
            return h("div", { class: "cfg-row svc" },
              h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } }, h("span", { class: "strong" }, s.name), h("span", { class: "small muted" }, s.note ?? "")),
              chip(label, tone));
          }))
        : h("span", { class: "small muted" }, d ? "No services reported." : "Service states arrive with the health check."),
      h("span", { class: "small muted" }, "Auth email delivery isn’t tracked yet; ImprovMX forwards support@gymcoapp.com to the inbox."));
  }

  await load();
}
