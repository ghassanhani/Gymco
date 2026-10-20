// Renders the landing page (site/index.html) and saves screenshots.
//   NODE_PATH=$(npm root -g) timeout 900 node test/site/landing_shots.mjs <out dir> [filter]
// The app-config and waitlist functions are faked and Google Fonts gets an empty
// stylesheet, so nothing leaves the machine. Each shot checks: no horizontal
// overflow (document or any element sticking out of the page), no page errors,
// no stray null/undefined text, and what the variant should show.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import { createRequire } from "node:module";

const { chromium } = createRequire(import.meta.url)("playwright");
const root = new URL("../../site/", import.meta.url).pathname;
const out = process.argv[2] ?? ".";
const only = process.argv[3] ?? "";
const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".png": "image/png", ".jpg": "image/jpeg" };

const server = createServer(async (req, res) => {
  let path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (path.endsWith("/")) path += "index.html";
  try {
    const body = await readFile(join(root, path));
    res.writeHead(200, { "Content-Type": types[extname(path)] ?? "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404).end();
  }
}).listen(8765);

const FN = "https://vncadogzpeoawikgafaj.supabase.co/functions/v1";
const APIKEY = "sb_publishable_8ZM7KKxLHCzpUpfygmyFcA_5kK_PY2P";
const t3 = (en, ar, es) => ({ en, ar, es });
const PUBLISHED = {
  version: 4,
  body: {
    sections: { proof: true, food: true, train: true, coaching: false, streak: true, privacy: true, plans: true, faq: true, join: true },
    beta: false,
    copy: { "hero.title": t3("Eat well, lift *heavy*", "كُل جيدًا وارفع *بثقل*", "Come bien, levanta *pesado*") },
    prices: { pro_month: "€4.99", pro_year: "€39.99", lifetime: "€89", year_save: "−33%" },
    stores: { ios_url: "https://apps.apple.com/app/gymco/id6700000000", android_url: "https://play.google.com/store/apps/details?id=app.gymco" },
    faq: [],
    notify: true,
  },
};

// Checks run in the page; each returns an error string or "".
const checks = {
  builtIn: () => {
    const h1 = document.querySelector("h1").textContent;
    if (h1 !== "Diet and training for lifters") return `hero title "${h1}"`;
    if (document.getElementById("coaching").hidden) return "coaching hidden";
    if (document.querySelectorAll("#faq-list details").length !== 7) return "faq count";
    if (document.getElementById("notify").hidden) return "notify hidden";
    if (document.querySelector('[data-store="ios_url"]').getAttribute("href") !== "#join") return "store href";
    if (!document.querySelector("h1 em")) return "no accent em";
    return "";
  },
  rtl: () => {
    const h = document.documentElement;
    if (h.dir !== "rtl" || h.lang !== "ar") return `dir=${h.dir} lang=${h.lang}`;
    if (!/[؀-ۿ]/.test(document.querySelector("h1").textContent)) return "hero not Arabic";
    if (!new URL(location.href).searchParams.get("lang")) return "no ?lang";
    return "";
  },
  es: () => {
    const h = document.documentElement;
    if (h.lang !== "es" || h.dir !== "ltr") return `lang=${h.lang}`;
    if (document.querySelector("h1").textContent !== "Dieta y entrenamiento de fuerza") return "hero not Spanish";
    if (document.querySelector("#faq-list summary").textContent !== "¿Necesito una cuenta?") return "faq not Spanish";
    return "";
  },
  published: () => {
    const h1 = document.querySelector("h1");
    if (h1.textContent !== "Eat well, lift heavy" || h1.querySelector("em")?.textContent !== "heavy") return `hero title "${h1.textContent}"`;
    const co = document.getElementById("coaching");
    if (!co.hidden || co.offsetHeight !== 0) return "coaching still shown";
    if (document.querySelector('.ftr a[href="#coaching"]')?.closest("li")?.hidden !== true) return "footer coaching link shown";
    if (!document.querySelector("#plans .banner").hidden || !document.querySelector(".plan .badge").hidden) return "beta bits shown";
    if (document.querySelector(".hdr .btn").textContent !== "Download") return "header cta not Download";
    if (document.querySelector('[data-store="ios_url"]').href !== "https://apps.apple.com/app/gymco/id6700000000") return "ios href";
    if (!document.querySelector('[data-store="android_url"]').href.startsWith("https://play.google.com/")) return "android href";
    return "";
  },
  waitlist: () => {
    const m = document.getElementById("notify-msg");
    if (m.textContent !== "You're on the list. One email at launch.") return `msg "${m.textContent}"`;
    if (!document.getElementById("notify").hidden) return "form still shown";
    return "";
  },
};

// [name, path, scheme, width, opts]
const SHOTS = [
  ["desktop-dark", "/", "dark", 1440, { check: "builtIn" }],
  ["desktop-light", "/", "light", 1440, { check: "builtIn", light: true }],
  ["phone-dark", "/", "dark", 390, { check: "builtIn" }],
  ["phone-light", "/", "light", 390, { check: "builtIn", light: true }],
  ["ar-desktop", "/?lang=ar", "dark", 1440, { check: "rtl" }],
  ["ar-phone", "/?lang=ar", "dark", 390, { check: "rtl" }],
  ["ar-phone-light", "/?lang=ar", "light", 390, { check: "rtl", light: true }],
  ["es-phone", "/?lang=es", "dark", 390, { check: "es" }],
  ["es-desktop", "/?lang=es", "light", 1440, { check: "es", locale: "es-ES", light: true }],
  // English unless asked: a Spanish browser and a light system still get English and dark.
  ["browser-es", "/", "light", 1440, { check: "builtIn", locale: "es-ES", light: false }],
  ["published", "/", "dark", 1440, { config: "published", check: "published" }],
  ["published-phone-ar", "/?lang=ar", "dark", 390, { config: "published", check: "rtl", expectH1: "كُل جيدًا وارفع بثقل" }],
  ["failure", "/", "dark", 1440, { config: "fail", check: "builtIn" }],
  ["waitlist-success", "/", "dark", 390, { check: "waitlist", notify: true }],
];

let failures = 0;
const browser = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
for (const [name, path, scheme, width, o] of SHOTS) {
  if (only && !name.includes(only)) continue;
  const ctx = await browser.newContext({ viewport: { width, height: 900 }, colorScheme: scheme, reducedMotion: "reduce", locale: o.locale ?? "en-GB" });
  const page = await ctx.newPage();
  // Light is a choice the visitor saves; dark is the default.
  if (o.light) await page.addInitScript(() => localStorage.setItem("gymco-site-theme", "light"));
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  page.on("console", (m) => { if (m.type() === "error" && !/Failed to load resource/.test(m.text())) errors.push(m.text()); });
  const seen = { config: 0, waitlist: null };
  await page.route("https://fonts.googleapis.com/**", (r) => r.fulfill({ contentType: "text/css", body: "" }));
  await page.route("https://fonts.gstatic.com/**", (r) => r.fulfill({ status: 404, body: "" }));
  await page.route(`${FN}/app-config?site=landing`, async (r) => {
    seen.config++;
    if (r.request().headers().apikey !== APIKEY) errors.push("app-config without apikey");
    if (o.config === "fail") return r.abort("failed");
    const body = o.config === "published" ? PUBLISHED : { version: 0, body: null };
    return r.fulfill({ status: 200, contentType: "application/json", headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify(body) });
  });
  await page.route(`${FN}/waitlist`, async (r) => {
    if (r.request().method() === "OPTIONS") return r.fulfill({ status: 204, headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "apikey, content-type" } });
    seen.waitlist = JSON.parse(r.request().postData() || "{}");
    await new Promise((res) => setTimeout(res, 150));
    return r.fulfill({ status: 201, contentType: "application/json", headers: { "Access-Control-Allow-Origin": "*" }, body: '{"ok":true}' });
  });
  await page.goto(`http://localhost:8765${path}`);
  await page.waitForTimeout(700);

  if (o.notify) {
    await page.fill("#lp-email", "lifter@example.com");
    await page.click("#notify button");
    await page.waitForTimeout(500);
    if (seen.waitlist?.email !== "lifter@example.com" || seen.waitlist?.locale !== "en") errors.push(`waitlist got ${JSON.stringify(seen.waitlist)}`);
    await page.locator("#join").screenshot({ path: join(out, `${name}-join.png`) });
    await page.evaluate(() => scrollTo(0, 0));
  }
  if (!seen.config) errors.push("app-config not called");
  if (o.light !== undefined && (await page.evaluate(() => document.querySelector(".lp").classList.contains("light"))) !== !!o.light) errors.push("theme wrong");

  const overflow = await page.evaluate(() => {
    if (document.documentElement.scrollWidth > innerWidth + 1) return [`document ${document.documentElement.scrollWidth}px`];
    // .lp clips, so also look for anything that sticks out of the page without a card clipping it.
    const lp = document.querySelector(".lp");
    const clipped = (el) => {
      for (let p = el.parentElement; p && p !== lp; p = p.parentElement) if (getComputedStyle(p).overflowX !== "visible") return true;
      return false;
    };
    return [...lp.querySelectorAll("*")].filter((e) => {
      if (e.closest(".aura") || !e.getClientRects().length) return false;
      const r = e.getBoundingClientRect();
      return (r.right > innerWidth + 1 || r.left < -1) && r.width > 0 && !clipped(e);
    }).slice(0, 5).map((e) => `${e.tagName.toLowerCase()}.${e.className?.baseVal ?? e.className} ${Math.round(e.getBoundingClientRect().left)}..${Math.round(e.getBoundingClientRect().right)}px`);
  });
  if (overflow.length) console.log("  overflow:\n   " + overflow.join("\n   "));
  const stray = await page.evaluate(() => { const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); const out = []; while (w.nextNode()) if (/^(null|undefined|NaN|\[object Object\])$/.test(w.currentNode.textContent.trim())) out.push(w.currentNode.textContent.trim()); return out; });
  if (stray.length) errors.push(`stray text: ${stray.join(", ")}`);
  // Keys in the copy table with no text on the page.
  const leftover = await page.evaluate(() => [...document.querySelectorAll("[data-k]")].filter((e) => !e.textContent.trim()).map((e) => e.dataset.k));
  if (leftover.length) errors.push(`empty: ${leftover.join(", ")}`);
  const problem = o.check ? await page.evaluate(checks[o.check]) : "";
  if (problem) errors.push(problem);
  if (o.expectH1) {
    const h1 = await page.textContent("h1");
    if (h1 !== o.expectH1) errors.push(`h1 "${h1}"`);
  }
  await page.screenshot({ path: join(out, `${name}.png`), fullPage: true });
  const ok = !overflow.length && !errors.length;
  if (!ok) failures++;
  console.log(name, ok ? "ok" : `FAIL${overflow.length ? " overflow" : ""}${errors.length ? ` errors: ${errors.join(" | ")}` : ""}`);
  await ctx.close();
}
await browser.close();
server.close();
console.log(failures ? `${failures} failed` : "all shots ok");
process.exit(failures ? 1 : 0);
