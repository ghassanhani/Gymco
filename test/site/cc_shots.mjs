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
    const [status, json] = fixtures(body, { role, empty: !!o.empty, review: !!o.review });
    return r.fulfill({ status, contentType: "application/json", body: JSON.stringify(json) });
  });
  await page.goto(`http://localhost:8765/admin/${hash}`);
  await page.waitForTimeout(500);
  if (o.wrongCode) {
    await page.fill("#totp", "123456");
    await page.click("form button[type=submit]");
    await page.waitForTimeout(200);
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
  if (overflow) {
    // Name the widest offenders so a failure says where to look.
    console.log(await page.evaluate(() => [...document.querySelectorAll("body *")]
      .filter((e) => e.getBoundingClientRect().right > innerWidth + 1 && getComputedStyle(e).position !== "fixed" && !e.closest(".table-wrap"))
      .slice(0, 5).map((e) => `  ${e.tagName.toLowerCase()}.${e.className} → ${Math.round(e.getBoundingClientRect().right)}px`).join("\n")));
  }
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
