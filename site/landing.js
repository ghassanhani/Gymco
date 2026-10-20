// gymcoapp.com/ — language, theme, the Monthly/Yearly toggle, the Control
// Center's published settings and the email sign-up. Copy is rendered as text
// only; the pure logic lives in landing-lib.js.
import { COPY } from "./landing-copy.js";
import {
  LANGS, SECTIONS, pickLang, splitAccent, sanitizeLanding, readConfigResponse, copyFor, faqFor, storeHref, isEmail,
} from "./landing-lib.js";

const FN = "https://vncadogzpeoawikgafaj.supabase.co/functions/v1";
const APIKEY = "sb_publishable_8ZM7KKxLHCzpUpfygmyFcA_5kK_PY2P"; // public, publishable
const THEME_KEY = "gymco-site-theme";
const LANG_KEY = "gymco-site-lang";

const storage = {
  get(k) { try { return localStorage.getItem(k); } catch { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode */ } },
};

const BUILT_IN = sanitizeLanding(null);
const root = document.querySelector(".lp");
const $ = (s) => document.querySelector(s);
const $$ = (s) => [...document.querySelectorAll(s)];

const state = {
  lang: pickLang({
    query: location.search,
    saved: storage.get(LANG_KEY),
  }),
  settings: BUILT_IN,
  yearly: false,
  light: document.documentElement.getAttribute("data-theme") === "light",
  sent: false,
};

/** Text with *accent* parts as <em>, built from text nodes only. */
function setRich(el, s) {
  const parts = splitAccent(s);
  el.replaceChildren(...parts.map((p) => {
    if (!p.em) return document.createTextNode(p.text);
    const em = document.createElement("em");
    em.textContent = p.text;
    return em;
  }));
}

function setText(el, s) {
  if (el.textContent !== s) el.textContent = s;
}

function paint(s) {
  const lang = state.lang;
  const c = copyFor(COPY, lang, s);
  // beta off: the Join buttons read "Download" (an explicit hero.cta override still wins for the hero).
  if (!s.beta) {
    c["cta.join"] = c["cta.download"];
    if (!s.copy["hero.cta"]?.[lang]) c["hero.cta"] = c["cta.download"];
  }

  const html = document.documentElement;
  html.lang = lang;
  html.dir = lang === "ar" ? "rtl" : "ltr";
  document.title = c["meta.title"];
  $('meta[name="description"]')?.setAttribute("content", c["meta.description"]);

  for (const el of $$("[data-k]")) {
    const v = c[el.dataset.k];
    if (typeof v !== "string") continue;
    if (el.hasAttribute("data-rich")) setRich(el, v);
    else setText(el, v);
  }
  for (const el of $$("[data-k-aria]")) {
    const v = c[el.dataset.kAria];
    if (typeof v === "string") el.setAttribute("aria-label", v);
  }
  for (const el of $$("[data-k-ph]")) {
    const v = c[el.dataset.kPh];
    if (typeof v === "string") el.setAttribute("placeholder", v);
  }

  // Sections, and every link that points at a hidden one.
  for (const k of SECTIONS) {
    const sec = document.getElementById(k);
    if (sec) sec.hidden = !s.sections[k];
    for (const a of $$(`a[href="#${k}"]`)) {
      if (a.closest(`#${k}`)) continue;
      const li = a.parentElement?.tagName === "LI" ? a.parentElement : a;
      li.hidden = !s.sections[k];
    }
  }
  for (const el of $$("[data-beta]")) el.hidden = !s.beta;

  paintPrices(c, s);

  for (const a of $$("[data-store]")) {
    const href = storeHref(a.dataset.store, s.stores[a.dataset.store]);
    a.setAttribute("href", href);
    if (href === "#join") a.removeAttribute("rel");
    else a.setAttribute("rel", "noopener");
  }

  // FAQ: the published list or the built-in seven, first one open.
  const list = $("#faq-list");
  list.replaceChildren(...faqFor(COPY, lang, s).map(({ q, a }, i) => {
    const d = document.createElement("details");
    if (i === 0) d.open = true;
    const sum = document.createElement("summary");
    sum.textContent = q;
    const p = document.createElement("p");
    p.textContent = a;
    d.append(sum, p);
    return d;
  }));

  // Email sign-up.
  const form = $("#notify");
  form.hidden = !s.notify || state.sent;
  $("#consent").hidden = !s.notify;
  $("#notify-msg").hidden = !s.notify;
  const msg = $("#notify-msg");
  if (msg.dataset.k2) setText(msg, c[msg.dataset.k2] ?? "");

  for (const b of $$("[data-lang]")) {
    const on = b.dataset.lang === lang;
    b.classList.toggle("on", on);
    b.setAttribute("aria-pressed", String(on));
  }
  paintTheme(c);
}

function paintPrices(c, s) {
  setText($("#pro-price"), state.yearly ? s.prices.pro_year : s.prices.pro_month);
  setText($("#pro-per"), c[state.yearly ? "plans.perYear" : "plans.perMonth"]);
  setText($("#life-price"), s.prices.lifetime);
  setText($("#year-save"), s.prices.year_save);
  for (const [id, on] of [["#bill-month", !state.yearly], ["#bill-year", state.yearly]]) {
    const b = $(id);
    b.classList.toggle("on", on);
    b.setAttribute("aria-pressed", String(on));
  }
}

function paintTheme(c = copyFor(COPY, state.lang, state.settings)) {
  root.classList.toggle("light", state.light);
  document.documentElement.setAttribute("data-theme", state.light ? "light" : "dark");
  const label = c[state.light ? "theme.toDark" : "theme.toLight"];
  const t = $("#theme");
  t.setAttribute("aria-label", label);
  t.setAttribute("title", label);
  $('meta[name="theme-color"]')?.setAttribute("content", state.light ? "#ffffff" : "#0a0b09");
}

/** Render from state; if the published settings break anything, fall back to the built-in page. */
function render() {
  try {
    paint(state.settings);
  } catch (e) {
    if (state.settings === BUILT_IN) throw e;
    state.settings = BUILT_IN;
    paint(BUILT_IN);
  }
}

function setLang(lang) {
  if (!LANGS.includes(lang) || lang === state.lang) return;
  state.lang = lang;
  storage.set(LANG_KEY, lang);
  try {
    const u = new URL(location.href);
    if (lang === "en") u.searchParams.delete("lang");
    else u.searchParams.set("lang", lang);
    history.replaceState(history.state, "", u.pathname + u.search + u.hash);
  } catch { /* file:// or sandboxed */ }
  render();
}

async function loadSettings() {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 4000);
  try {
    const r = await fetch(`${FN}/app-config?site=landing`, { headers: { apikey: APIKEY }, signal: ctl.signal });
    if (!r.ok) return;
    const s = readConfigResponse(await r.json());
    if (!s) return;
    state.settings = s;
    render();
  } catch {
    /* offline, timeout or bad JSON: the built-in page stays */
  } finally {
    clearTimeout(timer);
  }
}

function showMsg(key, kind) {
  const msg = $("#notify-msg");
  msg.dataset.k2 = key;
  msg.className = `notify-msg ${kind}`;
  msg.textContent = copyFor(COPY, state.lang, state.settings)[key];
}

async function onNotify(ev) {
  ev.preventDefault();
  const input = $("#lp-email");
  const button = $("#notify button");
  const email = input.value.trim();
  if (!isEmail(email)) {
    input.setAttribute("aria-invalid", "true");
    showMsg("join.invalid", "bad");
    input.focus();
    return;
  }
  input.removeAttribute("aria-invalid");
  const c = copyFor(COPY, state.lang, state.settings);
  button.disabled = true;
  button.classList.add("is-busy");
  setText(button, c["join.sending"]);
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`${FN}/waitlist`, {
      method: "POST",
      headers: { apikey: APIKEY, "Content-Type": "application/json" },
      body: JSON.stringify({ email, locale: state.lang }),
      signal: ctl.signal,
    });
    if (r.status === 201 || r.status === 200) {
      state.sent = true;
      $("#notify").hidden = true;
      showMsg("join.ok", "ok");
    } else {
      showMsg(r.status === 400 ? "join.invalid" : "join.err", "bad");
    }
  } catch {
    showMsg("join.err", "bad");
  } finally {
    clearTimeout(timer);
    button.disabled = false;
    button.classList.remove("is-busy");
    setText(button, copyFor(COPY, state.lang, state.settings)["join.notify"]);
  }
}

// Sections without a menu entry of their own light up the entry they belong to.
const NAV_FOR = { food: "food", coaching: "food", streak: "food", train: "train", privacy: "privacy", plans: "plans", faq: "faq" };

/** Mark the menu link for the section crossing the upper third of the screen. */
function watchSections() {
  if (!("IntersectionObserver" in window)) return;
  const links = new Map($$(".nav a[href^='#']").map((a) => [a.getAttribute("href").slice(1), a]));
  const mark = (id) => {
    for (const [k, a] of links) {
      const on = k === NAV_FOR[id];
      a.classList.toggle("on", on);
      if (on) a.setAttribute("aria-current", "true");
      else a.removeAttribute("aria-current");
    }
  };
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) if (e.isIntersecting) mark(e.target.id);
  }, { rootMargin: "-30% 0px -65% 0px" });
  for (const sec of $$("section[id]")) io.observe(sec);
}

function wire() {
  $("#theme").addEventListener("click", () => {
    state.light = !state.light;
    storage.set(THEME_KEY, state.light ? "light" : "dark");
    paintTheme();
  });
  for (const b of $$("[data-lang]")) b.addEventListener("click", () => setLang(b.dataset.lang));
  const bill = (yearly) => () => {
    state.yearly = yearly;
    paintPrices(copyFor(COPY, state.lang, state.settings), state.settings);
  };
  $("#bill-month").addEventListener("click", bill(false));
  $("#bill-year").addEventListener("click", bill(true));
  $("#notify").addEventListener("submit", onNotify);
  $("#lp-email").addEventListener("input", (e) => e.target.removeAttribute("aria-invalid"));
  watchSections();
  const hdr = $(".hdr");
  const onScroll = () => hdr?.classList.toggle("scrolled", scrollY > 8);
  addEventListener("scroll", onScroll, { passive: true });
  onScroll();
}

wire();
try {
  render();
} finally {
  document.documentElement.classList.remove("lp-pending");
}
loadSettings();
