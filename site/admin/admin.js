// The Gymco admin dashboard: sign in with the email code, then show the
// totals admin-stats returns. The page holds no secrets; the function decides
// who gets numbers.

import { aiCost, barGeometry, cleanCode, fmtBytes, fmtInt, weekCompare } from "./view.js";

const SUPABASE_URL = "https://vncadogzpeoawikgafaj.supabase.co";
const PUBLISHABLE_KEY = "sb_publishable_8ZM7KKxLHCzpUpfygmyFcA_5kK_PY2P";
const FREE_DB_BYTES = 500_000_000;
const ADMIN_URL = "https://gymcoapp.com/admin/";

const $ = (id) => document.getElementById(id);
// supabase-js comes from a CDN; if it didn't load, say so instead of a blank page.
const sb = window.supabase?.createClient(SUPABASE_URL, PUBLISHABLE_KEY);
const show = (...ids) => {
  for (const id of ["login", "locked", "dash", "error", "bar-actions"]) $(id).hidden = !ids.includes(id);
};

const usd = (n) => new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 2 }).format(n);
const dayLabel = (iso) => new Date(iso + "T00:00:00Z").toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

// ---- Signing in ----------------------------------------------------------

let pendingEmail = "";

$("email-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = $("email").value.trim();
  if (!email) return loginError("Enter your email.");
  await busy(e.submitter, async () => {
    // The email may hold a link, a code or both: the link comes back here signed in.
    const { error } = await sb.auth.signInWithOtp({ email, options: { shouldCreateUser: false, emailRedirectTo: ADMIN_URL } });
    if (error) return loginError(/signup|not found|not allowed/i.test(error.message) ? "No Gymco account uses that email." : "Couldn't send the code. Try again in a minute.");
    pendingEmail = email;
    $("code-sent").textContent = `We emailed ${email}. Open the link in it, or type the code.`;
    $("email-form").hidden = true;
    $("code-form").hidden = false;
    loginError("");
    $("code").focus();
  });
});

$("code-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const token = cleanCode($("code").value);
  if (token.length < 6) return loginError("Enter the 6-digit code from the email.");
  await busy(e.submitter, async () => {
    const { error } = await sb.auth.verifyOtp({ email: pendingEmail, token, type: "email" });
    if (error) return loginError("That code didn't work. Check it, or send a new one.");
    loginError("");
    $("code").value = "";
    load();
  });
});

$("other-email").addEventListener("click", () => {
  $("code-form").hidden = true;
  $("email-form").hidden = false;
  loginError("");
  $("email").focus();
});

function loginError(text) {
  $("login-error").textContent = text;
}

async function busy(button, work) {
  if (button) button.disabled = true;
  try {
    await work();
  } finally {
    if (button) button.disabled = false;
  }
}

async function signOut() {
  await sb.auth.signOut({ scope: "local" });
  $("email-form").hidden = false;
  $("code-form").hidden = true;
  show("login");
}

$("signout").addEventListener("click", signOut);
$("locked-signout").addEventListener("click", signOut);
$("refresh").addEventListener("click", () => load());
$("retry").addEventListener("click", () => load());

// ---- Loading -------------------------------------------------------------

async function load() {
  if (!sb) return location.reload();
  const { data } = await sb.auth.getSession();
  const session = data.session;
  if (!session) return show("login");

  show("dash", "bar-actions");
  $("dash").classList.add("skeleton");
  $("dash").setAttribute("aria-busy", "true");
  if (!$("metrics").children.length) renderMetrics(null);

  let res;
  try {
    res = await fetch(`${SUPABASE_URL}/functions/v1/admin-stats`, {
      method: "POST",
      headers: { Authorization: `Bearer ${session.access_token}`, apikey: PUBLISHABLE_KEY },
    });
  } catch {
    return failed();
  }
  if (res.status === 401) return signOut();
  if (res.status === 403) {
    $("locked-email").textContent = session.user.email ?? "";
    return show("locked");
  }
  if (!res.ok) return failed();
  render(await res.json());
}

function failed() {
  show("error", "bar-actions");
}

// ---- Rendering -----------------------------------------------------------

function render(s) {
  const week = weekCompare(s.signups);
  const change =
    week.change === null
      ? "No sign-ups the week before"
      : `<b>${week.change >= 0 ? "+" : ""}${Math.round(week.change * 100)}%</b> vs the week before (${fmtInt(week.lastWeek)})`;
  renderMetrics([
    ["Accounts", fmtInt(s.accounts), "All time"],
    ["New this week", fmtInt(week.thisWeek), change],
    ["Active · 7 days", fmtInt(s.active_7d), "Backed up or used an AI scan"],
    ["Active · 30 days", fmtInt(s.active_30d), "Backed up or used an AI scan"],
    ["AI scans today", fmtInt(s.scans_today), `${fmtInt(s.scans_month)} this month`],
    ["AI cost this month", `≈ ${usd(aiCost(s.scans_month))}`, `Estimate · <a href="https://console.anthropic.com/usage" target="_blank" rel="noopener">exact spend</a>`],
  ]);

  chart($("chart-signups"), s.signups, "sign-ups");
  chart($("chart-scans"), s.scans, "scans");

  const deleted = s.deletions.slice(-7).reduce((a, d) => a + d.n, 0);
  const share = Math.min(1, s.db_bytes / FREE_DB_BYTES);
  $("health").innerHTML = `
    <div>
      <div class="row-head"><dt>Database</dt><dd>${fmtBytes(s.db_bytes)} of ${fmtBytes(FREE_DB_BYTES)}</dd></div>
      <div class="meter" role="meter" aria-label="Database size" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${Math.round(share * 100)}"><i style="width:${(share * 100).toFixed(1)}%"></i></div>
    </div>
    <div><dt>Backups stored</dt><dd>${fmtInt(s.backups.count)} · ${fmtBytes(s.backups.bytes)}</dd></div>
    <div><dt>Accounts that hit the daily scan cap · 7 days</dt><dd>${fmtInt(s.capped_7d)}</dd></div>
    <div><dt>Accounts deleted · 7 days</dt><dd>${fmtInt(deleted)}</dd></div>`;

  const at = new Date(s.generated_at);
  $("updated").textContent = `Updated ${at.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
  $("dash").classList.remove("skeleton");
  $("dash").setAttribute("aria-busy", "false");
}

/** Six metric tiles; null draws placeholders while loading. */
function renderMetrics(items) {
  const rows = items ?? Array.from({ length: 6 }, () => ["Loading", "0", "&nbsp;"]);
  $("metrics").innerHTML = rows
    .map(([label, value, note]) => `<dl class="card metric"><dt>${label}</dt><dd>${value}</dd><div class="note">${note}</div></dl>`)
    .join("");
}

const W = 600;
const H = 168;

/** Thirty bars with a hover readout, and the same numbers as a table for screen readers. */
function chart(el, series, noun) {
  const bars = barGeometry(series, W, H);
  const max = Math.max(0, ...series.map((d) => d.n));
  const empty = max === 0;
  el.innerHTML = `
    <svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" aria-hidden="true">
      <line class="grid" x1="0" x2="${W}" y1="${H - 0.5}" y2="${H - 0.5}"/>
      ${empty ? "" : `<line class="grid" x1="0" x2="${W}" y1="0.5" y2="0.5"/>`}
      ${bars
        .map(
          (b, i) => `<rect class="hit" data-i="${i}" x="${b.x}" y="0" width="${W / bars.length}" height="${H}"/>` +
            `<rect class="bar" x="${b.x + 1}" y="${b.y}" width="${b.w}" height="${b.h}" rx="${Math.min(4, b.h / 2)}"/>`,
        )
        .join("")}
    </svg>
    ${empty ? "" : `<span class="max" aria-hidden="true">${fmtInt(max)}</span>`}
    <div class="axis" aria-hidden="true"><span>${dayLabel(series[0].day)}</span><span>${dayLabel(series[series.length - 1].day)}</span></div>
    ${empty ? `<div class="empty">No ${noun} in the last 30 days</div>` : ""}
    <table class="visually-hidden"><caption>${esc(noun)} per day</caption>
      <tr><th scope="col">Day</th><th scope="col">${esc(noun)}</th></tr>
      ${series.map((d) => `<tr><td>${dayLabel(d.day)}</td><td>${d.n}</td></tr>`).join("")}
    </table>`;

  const tip = $("tip");
  el.querySelectorAll(".hit").forEach((hit) => {
    hit.addEventListener("mousemove", (e) => {
      const d = series[+hit.dataset.i];
      tip.innerHTML = `${fmtInt(d.n)} ${esc(noun)} <span>· ${dayLabel(d.day)}</span>`;
      tip.style.left = `${e.clientX}px`;
      tip.style.top = `${e.clientY}px`;
      tip.hidden = false;
    });
    hit.addEventListener("mouseleave", () => (tip.hidden = true));
  });
}

if (sb) {
  sb.auth.onAuthStateChange((event) => {
    if (event === "SIGNED_OUT") show("login");
    // Arriving from the email's link: the session lands after the first load.
    if (event === "SIGNED_IN" && !$("login").hidden) load();
  });
  load();
} else {
  show("error");
}
