// Renders the Control Center against made-up data and saves screenshots.
//   NODE_PATH=$(npm root -g) node --experimental-strip-types test/site/cc_shots.mjs <out dir> [filter]
// supabase-js and the admin function are stubbed; nothing leaves the machine.
// Each shot checks the page has no horizontal overflow and shows what it should.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import { createRequire } from "node:module";
import { fixtures } from "./cc_fixtures.mjs";

const { chromium } = createRequire(import.meta.url)("playwright");
const root = new URL("../../site/", import.meta.url).pathname;
const out = process.argv[2] ?? ".";
const only = process.argv[3] ?? "";
const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".png": "image/png" };

const server = createServer(async (req, res) => {
  let path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (path.endsWith("/")) path += "index.html";
  try {
    res.writeHead(200, { "Content-Type": types[extname(path)] ?? "application/octet-stream" });
    res.end(await readFile(join(root, path)));
  } catch {
    res.writeHead(404).end();
  }
}).listen(8765);

const SUPABASE_JS = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.2/dist/umd/supabase.js";

// auth: "out" (no session), "enroll" (aal1, no factor), "challenge" (aal1, factor), "in" (aal2).
const fakeSupabase = (auth) => `
  window.__calls = [];
  window.supabase = { createClient: () => ({ auth: {
    getSession: async () => ({ data: { session: ${auth === "out" ? "null" : '{ access_token: "t", user: { email: "owner@gymco.test" } }'} } }),
    signInWithOtp: async (a) => { window.__otp = a; return { error: null }; },
    verifyOtp: async () => ({ error: null }),
    signOut: async () => ({ error: null }),
    onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } }),
    mfa: {
      getAuthenticatorAssuranceLevel: async () => ({ data: { currentLevel: "${auth === "in" ? "aal2" : "aal1"}", nextLevel: "${auth === "enroll" ? "aal1" : "aal2"}" } }),
      listFactors: async () => ({ data: { totp: ${auth === "challenge" ? '[{ id: "f1" }]' : "[]"}, all: [] } }),
      enroll: async () => ({ data: { id: "f1", totp: { qr_code: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect width='10' height='10' fill='white'/><rect x='1' y='1' width='3' height='3'/><rect x='6' y='1' width='3' height='3'/><rect x='1' y='6' width='3' height='3'/></svg>", secret: "JBSWY3DPEHPK3PXP" } } }),
      challengeAndVerify: async () => ({ error: { message: "Invalid code" } }),
      unenroll: async () => ({}),
    },
  } }) };`;

// [name, hash, scheme, width, opts]
const SHOTS = [
  ["gate-email", "", "dark", 1280, { auth: "out", expect: "#admin-email" }],
  ["gate-email-light", "", "light", 390, { auth: "out", expect: "#admin-email" }],
  ["gate-enroll", "", "dark", 1280, { auth: "enroll", expect: ".qr img" }],
  ["gate-challenge-wrong", "", "dark", 1280, { auth: "challenge", expect: "#totp", wrongCode: true }],
  ["gate-not-admin", "", "dark", 1280, { auth: "in", role: null, expectText: "isn't an admin" }],
  ["overview-dark", "#/overview", "dark", 1440, { expect: ".kpi" }],
  ["overview-light", "#/overview", "light", 1440, { expect: ".kpi" }],
  ["overview-phone", "#/overview", "dark", 390, { expect: ".kpi" }],
  ["overview-empty", "#/overview", "light", 1280, { expect: ".kpi", empty: true }],
  ["overview-error", "#/overview", "dark", 1280, { failing: ["stats"], expect: ".banner" }],
  ["accounts-card", "#/accounts?email=user%40example.com", "dark", 1440, { expect: ".lock-note" }],
  ["accounts-card-light", "#/accounts?email=user%40example.com", "light", 390, { expect: ".lock-note" }],
  ["accounts-none", "#/accounts?email=nobody%40example.com", "dark", 1280, { expectText: "No account for" }],
  ["team", "#/team", "dark", 1440, { expect: "table" }],
  ["team-light", "#/team", "light", 1280, { expect: "table" }],
  ["config", "#/config", "dark", 1440, { expect: ".cfg-row", expectText: "Draft v19" }],
  ["config-light", "#/config", "light", 1440, { expect: ".cfg-row", expectText: "Today’s spend" }],
  ["config-phone", "#/config", "dark", 390, { expect: ".cfg-row" }],
  ["config-empty", "#/config", "light", 1280, { expect: ".cfg-row", empty: true, expectText: "Built-in defaults" }],
  ["config-editor-review", "#/config", "dark", 1280, { role: "editor", review: true, expectText: "Sent to the Owner" }],
  ["support-role-config", "#/config", "dark", 1280, { role: "support", expectText: "needs the Editor role" }],
  ["content-foods", "#/content", "dark", 1440, { expect: ".check", expectText: "macros add up to 212 kcal" }],
  ["content-exercises", "#/content?kind=exercises", "dark", 1440, { expect: ".phone", expectText: "1 item missing Spanish" }],
  ["content-exercises-light", "#/content?kind=exercises", "light", 1440, { expect: ".phone", expectText: "used in 2 templates" }],
  ["content-exercises-phone", "#/content?kind=exercises", "dark", 390, { expect: ".phone" }],
  ["content-exercise-sheet", "#/content?kind=exercises", "dark", 1440, { click: "tbody tr.clickable:nth-child(4)", expect: ".sheet .langtabs", expectText: "Add the Spanish name" }],
  ["content-exercise-sheet-phone", "#/content?kind=exercises", "light", 390, { click: "tbody tr.clickable:nth-child(4)", expect: ".sheet .langtabs" }],
  ["content-vocabulary", "#/content?kind=vocabulary", "dark", 1440, { expectText: "Test box" }],
  ["content-templates", "#/content?kind=templates", "dark", 1440, { expectText: "sets a week" }],
  ["content-template-sheet", "#/content?kind=templates", "dark", 1440, { click: "tbody tr.clickable", expect: ".sheet .pack-rows.compact" }],
  ["content-awards", "#/content?kind=awards", "light", 1440, { expectText: "Awards can’t reward weight loss" }],
  ["content-challenges", "#/content?kind=challenges", "dark", 1280, { expect: ".phone .ptrack" }],
  ["content-copy", "#/content?kind=copy", "dark", 1440, { expectText: "Built-in English" }],
  ["content-copy-phone", "#/content?kind=copy", "light", 390, { expectText: "Built-in English" }],
  ["content-eating-out", "#/content?kind=eating_out", "dark", 1280, { expect: "table" }],
  ["content-empty", "#/content", "light", 1280, { empty: true, expectText: "No foods in this pack yet" }],
  ["content-editor", "#/content?kind=foods", "dark", 1280, { role: "editor", expectText: "Send for review" }],
  ["content-editor-review", "#/content?kind=challenges", "dark", 1280, { role: "editor", review: true, expectText: "Sent to the Owner" }],
  ["plans", "#/plans", "dark", 1440, { expect: ".plan-card", expectText: "Testing mode is on" }],
  ["plans-light", "#/plans", "light", 1440, { expect: ".plan-card", expectText: "tester1@example.com" }],
  ["plans-phone", "#/plans", "dark", 390, { expect: ".plan-card" }],
  ["plans-empty", "#/plans", "light", 1280, { empty: true, expectText: "No manual grants" }],
  ["plans-editor", "#/plans", "dark", 1280, { role: "editor", expectText: "Only the Owner can change these" }],
  ["messaging", "#/messaging", "dark", 1440, { expect: ".phone", expectText: "Voice checklist" }],
  ["messaging-light", "#/messaging", "light", 1280, { expect: ".phone", expectText: "Monthly challenges are here" }],
  ["messaging-phone", "#/messaging", "dark", 390, { expect: ".phone" }],
  ["messaging-voice", "#/messaging", "dark", 1280, { click: "tbody tr:nth-child(2) button", expectText: "Voice check: “burn off”" }],
  ["messaging-push", "#/messaging?tab=push", "dark", 1440, { expect: "table", expectText: "quiet hours 22:00–08:00" }],
  ["messaging-push-light", "#/messaging?tab=push", "light", 1280, { expect: "table", expectText: "Eating out estimates" }],
  ["messaging-push-clash", "#/messaging?tab=push", "dark", 1280, { flags: { week_taken: true }, click: ".btn.publish", expectText: "Schedule for 30 Oct" }],
  ["messaging-push-off", "#/messaging?tab=push", "dark", 1280, { flags: { push_off: true }, expectText: "Push isn’t set up yet" }],
  ["messaging-email", "#/messaging?tab=email", "dark", 1280, { expectText: "Deletion confirmed" }],
  ["messaging-empty", "#/messaging", "light", 1280, { empty: true, expectText: "No announcements yet" }],
  ["messaging-editor", "#/messaging?tab=push", "dark", 1280, { role: "editor", expectText: "Scheduling needs the Owner" }],
  ["support", "#/support", "dark", 1440, { expect: "table", expectText: "New · 4" }],
  ["support-light", "#/support", "light", 1280, { expect: "table", expectText: "Restore failed after new phone" }],
  ["support-phone", "#/support", "dark", 390, { expect: "table" }],
  ["support-ticket", "#/support?id=t1", "dark", 1440, { expect: ".deadline", expectText: "days left to complete deletion" }],
  ["support-ticket-light", "#/support?id=t2", "light", 1280, { expect: ".support-detail", expectText: "Open account" }],
  ["support-deletion", "#/support?tab=deletion&id=t5", "dark", 1440, { expect: ".deadline.bad", expectText: "days overdue" }],
  ["support-empty", "#/support", "light", 1280, { empty: true, expectText: "Inbox zero" }],
  ["support-search", "#/support?q=kettlebell", "dark", 1280, { expectText: "Nothing matches" }],
  ["support-role", "#/support", "dark", 1280, { role: "support", expect: "table" }],
  ["support-viewer", "#/support", "dark", 1280, { role: "viewer", expectText: "needs the Support role" }],
  ["releases", "#/releases", "dark", 1440, { expect: "table", expectText: "A hard block stops 26% of devices" }],
  ["releases-light", "#/releases", "light", 1280, { expect: "table", expectText: "1.0.3" }],
  ["releases-phone", "#/releases", "dark", 390, { expect: "table" }],
  ["releases-no-github", "#/releases", "dark", 1280, { flags: { no_github: true }, expectText: "Add a GITHUB_TOKEN secret to see runs here" }],
  ["releases-viewer", "#/releases", "light", 1280, { role: "viewer", expectText: "Changing the gate needs the Editor role" }],
  ["releases-editor", "#/releases", "dark", 1280, { role: "editor", expectText: "Save to Remote config draft" }],
  ["releases-empty", "#/releases", "dark", 1280, { empty: true, expectText: "No build yet" }],
  ["website", "#/website?page=privacy", "dark", 1440, { expect: ".md-preview", expectText: "What we never collect" }],
  ["website-light", "#/website?page=privacy", "light", 1280, { expect: ".md-preview", expectText: "Version history" }],
  ["website-phone", "#/website", "dark", 390, { expect: ".md-preview" }],
  ["website-ar", "#/website?page=privacy&lang=ar", "dark", 1280, { expect: ".md-preview[dir=rtl]" }],
  ["website-empty", "#/website", "light", 1280, { empty: true, expectText: "Nothing drafted yet" }],
  ["website-editor-review", "#/website?page=privacy", "dark", 1280, { role: "editor", review: true, expectText: "Sent to the Owner" }],
  ["health", "#/health", "dark", 1440, { expect: ".kpi", expectText: "Crashlytics isn’t connected yet" }],
  ["health-light", "#/health", "light", 1280, { expect: ".kpi", expectText: "ImprovMX forwarding" }],
  ["health-phone", "#/health", "dark", 390, { expect: ".kpi" }],
  ["health-error", "#/health", "dark", 1280, { failing: ["health"], expect: ".banner", expectText: "Couldn’t load the numbers" }],
  ["health-empty", "#/health", "light", 1280, { empty: true, expectText: "No calls yet" }],
];

let failures = 0;
const browser = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
for (const [name, hash, scheme, width, o] of SHOTS) {
  if (only && !name.includes(only)) continue;
  const page = await browser.newPage({ viewport: { width, height: 900 }, colorScheme: scheme });
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.addInitScript((t) => localStorage.setItem("gymco-admin-theme", t), scheme);
  await page.route("https://cdn.jsdelivr.net/**", (r) =>
    r.request().url() === SUPABASE_JS ? r.fulfill({ contentType: "text/javascript", body: fakeSupabase(o.auth ?? "in") }) : r.fulfill({ status: 404, body: "" }));
  await page.route("https://fonts.googleapis.com/**", (r) => r.fulfill({ contentType: "text/css", body: "" }));
  await page.route("https://vncadogzpeoawikgafaj.supabase.co/functions/v1/admin", async (r) => {
    const body = JSON.parse(r.request().postData() || "{}");
    const role = "role" in o ? o.role : "owner";
    if (!role) return r.fulfill({ status: 403, contentType: "application/json", body: JSON.stringify({ error: "not_admin" }) });
    if (o.failing?.includes(body.action)) return r.fulfill({ status: 500, contentType: "application/json", body: "{}" });
    const [status, json] = fixtures(body, { role, empty: !!o.empty, review: !!o.review, flags: o.flags ?? {} });
    return r.fulfill({ status, contentType: "application/json", body: JSON.stringify(json) });
  });
  await page.goto(`http://localhost:8765/admin/${hash}`);
  await page.waitForTimeout(500);
  if (o.wrongCode) {
    await page.fill("#totp", "123456");
    await page.click("form button[type=submit]");
    await page.waitForTimeout(200);
  }
  if (o.click) {
    await page.click(o.click);
    await page.waitForTimeout(300);
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
  if (overflow) {
    // Name the widest offenders so a failure says where to look.
    console.log(await page.evaluate(() => [...document.querySelectorAll("body *")]
      .filter((e) => e.getBoundingClientRect().right > innerWidth + 1 && getComputedStyle(e).position !== "fixed" && !e.closest(".table-wrap"))
      .slice(0, 5).map((e) => `  ${e.tagName.toLowerCase()}.${e.className} → ${Math.round(e.getBoundingClientRect().right)}px`).join("\n")));
  }
  // A stray null or undefined rendered as text.
  const stray = await page.evaluate(() => { const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); const out = []; while (w.nextNode()) if (/^(null|undefined|NaN)$/.test(w.currentNode.textContent.trim())) out.push(w.currentNode.textContent.trim()); return out; });
  if (stray.length) errors.push(`stray text: ${stray.join(", ")}`);
  const found = o.expect ? (await page.$(o.expect)) !== null : true;
  const text = o.expectText ? (await page.textContent("body")).includes(o.expectText) : true;
  await page.screenshot({ path: join(out, `${name}.png`), fullPage: true });
  const ok = !overflow && found && text && !errors.length;
  if (!ok) failures++;
  console.log(name, ok ? "ok" : `FAIL${overflow ? " overflow" : ""}${found ? "" : ` missing ${o.expect}`}${text ? "" : ` no "${o.expectText}"`}${errors.length ? ` errors: ${errors.join(" | ")}` : ""}`);
  await page.close();
}
await browser.close();
server.close();
console.log(failures ? `${failures} failed` : "all shots ok");
process.exit(failures ? 1 : 0);
