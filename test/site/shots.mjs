// Renders the admin dashboard against made-up data and saves screenshots.
//   NODE_PATH=$(npm root -g) node test/site/shots.mjs <out dir>
// supabase-js and the admin-stats function are stubbed, so nothing leaves
// the machine. Each state is a separate page: dash, empty, locked, error, login.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import { createRequire } from "node:module";

const { chromium } = createRequire(import.meta.url)("playwright");
const root = new URL("../../site/", import.meta.url).pathname;
const out = process.argv[2] ?? ".";
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

const days = Array.from({ length: 30 }, (_, i) => new Date(Date.UTC(2026, 8, 20 + i)).toISOString().slice(0, 10));
const wave = (base, i) => Math.max(0, Math.round(base + base * 0.6 * Math.sin(i / 3) + (i % 5)));
const stats = (empty) => ({
  accounts: empty ? 0 : 1284,
  signups: days.map((day, i) => ({ day, n: empty ? 0 : wave(6 + i / 3, i) })),
  active_7d: empty ? 0 : 412,
  active_30d: empty ? 0 : 903,
  scans: days.map((day, i) => ({ day, n: empty ? 0 : wave(140, i), capped: empty ? 0 : i % 4 })),
  capped_7d: empty ? 0 : 3,
  scans_today: empty ? 0 : 162,
  scans_month: empty ? 0 : 2731,
  backups: { count: empty ? 0 : 1190, bytes: empty ? 0 : 38_400_000 },
  db_bytes: empty ? 9_100_000 : 61_700_000,
  deletions: days.map((day, i) => ({ day, n: empty ? 0 : i % 6 === 0 ? 1 : 0 })),
  generated_at: "2026-10-19T14:05:00Z",
});

// Stands in for supabase-js: signed in unless the state is "login".
const fakeSupabase = (state) => `
  window.supabase = { createClient: () => ({ auth: {
    getSession: async () => ({ data: { session: ${state === "login" ? "null" : '{ access_token: "t", user: { email: "someone@example.com" } }'} } }),
    signInWithOtp: async (args) => { window.__otp = args; return { error: null }; },
    verifyOtp: async () => ({ error: null }),
    signOut: async () => ({ error: null }),
    onAuthStateChange: () => {},
  } }) };`;

// supabase-js 2.117.2 ships dist/umd/supabase.js only (already minified).
const SUPABASE_JS = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.2/dist/umd/supabase.js";

const status = { dash: 200, empty: 200, locked: 403, error: 500, expired: 401 };
// The view each state must end on.
const expect = { dash: "dash", empty: "dash", locked: "locked", error: "error", expired: "login", login: "login", "cdn-down": "error" };

let failures = 0;
const browser = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
const shots = [
  ["dash", "light", 1280], ["dash", "dark", 1280], ["dash", "light", 390], ["dash", "dark", 390],
  ["empty", "light", 1280], ["locked", "light", 1280], ["error", "dark", 1280], ["login", "light", 390],
  ["expired", "light", 390], ["cdn-down", "light", 390],
];
for (const [state, scheme, width] of shots) {
  const page = await browser.newPage({ viewport: { width, height: 900 }, colorScheme: scheme });
  // Only the file the package really ships answers; any other path 404s, as on jsDelivr.
  await page.route("https://cdn.jsdelivr.net/**", (r) =>
    r.request().url() === SUPABASE_JS && state !== "cdn-down"
      ? r.fulfill({ contentType: "text/javascript", body: fakeSupabase(state) })
      : r.fulfill({ status: 404, body: "" }),
  );
  await page.route("https://fonts.googleapis.com/**", (r) => r.fulfill({ contentType: "text/css", body: "" }));
  await page.route("https://vncadogzpeoawikgafaj.supabase.co/**", (r) =>
    status[state] === 200
      ? r.fulfill({ contentType: "application/json", body: JSON.stringify(stats(state === "empty")) })
      : r.fulfill({ status: status[state], body: "" }),
  );
  await page.goto("http://localhost:8765/admin/");
  await page.waitForTimeout(400);
  if (state === "dash" && width === 1280 && scheme === "light" && (await page.$("#chart-scans .hit"))) {
    await page.hover("#chart-scans .hit[data-i='25']");
  }
  // A link-only email must bring the admin back here, signed in.
  if (state === "login") {
    await page.fill("#email", "someone@example.com");
    await page.click("#email-form button[type=submit]");
    await page.waitForTimeout(100);
    const redirect = await page.evaluate(() => window.__otp?.options?.emailRedirectTo);
    if (redirect !== "https://gymcoapp.com/admin/") {
      failures++;
      console.log("login link redirect WRONG:", redirect);
    }
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  const shown = await page.evaluate(() => ["login", "locked", "dash", "error"].filter((id) => !document.getElementById(id).hidden));
  const name = `${state}-${scheme}-${width}.png`;
  await page.screenshot({ path: join(out, name), fullPage: true });
  // The cap row counts accounts (capped_7d), not account-days summed from the series.
  const capped = state === "dash" ? await page.evaluate(() => [...document.querySelectorAll("#health > div")].find((d) => d.textContent.includes("scan cap"))?.querySelector("dd")?.textContent) : "3";
  const right = shown.length === 1 && shown[0] === expect[state] && capped === "3";
  if (overflow || !right) failures++;
  console.log(name, overflow ? "OVERFLOW" : "ok", right ? "" : `WRONG ${shown} (want ${expect[state]}) cap=${capped}`);
  await page.close();
}
await browser.close();
server.close();
console.log(failures ? `${failures} failed` : "all states ok");
process.exit(failures ? 1 : 0);
