// Gymco Control Center: sign in, then the sidebar shell and the section the
// address names. Sections load on demand from pages/<id>.js.

import { ApiError, call, onAuthLost, sb } from "./lib/api.js";
import { gate, idleTooLong, markActive } from "./lib/auth.js";
import { clear, h, icon } from "./lib/dom.js";
import { can, ROLE_LABEL } from "./lib/roles.js";
import { NAV, PAGES, parseHash } from "./lib/routes.js";
import { initTheme, themeToggle } from "./lib/theme.js";
import { empty, errorBanner, skeleton, toast } from "./lib/ui.js";

initTheme();
const root = document.getElementById("app");
let me = null;
let mounted = 0;

async function start(opts) {
  try {
    me = await gate(root, opts);
  } catch {
    clear(root).append(h("div", { class: "gate" }, h("div", { class: "card" },
      errorBanner("Couldn't reach the server", "Check your connection, then try again.", () => location.reload()))));
    return;
  }
  shell();
  route();
}

function shell() {
  const navLinks = NAV.map((g) =>
    h("div", { class: "navgroup" }, h("h2", {}, g.name),
      g.items.map((i) => h("a", { class: "nav", href: `#/${i.id}`, "data-id": i.id },
        h("span", {}, i.label), can(me.role, i.cap) ? null : h("span", { "aria-label": "Needs another role" }, icon("lock", 14))))));
  const initials = me.email.slice(0, 2).toUpperCase();
  const app = h("div", { class: "app" },
    h("nav", { class: "side", "aria-label": "Main" },
      h("a", { class: "brandmark", href: "#/overview" }, h("img", { src: "/icon.png", alt: "" }), h("span", {}, h("b", {}, "Gymco"), h("span", {}, "Control Center"))),
      navLinks),
    h("div", { class: "main" },
      h("header", { class: "top" },
        h("button", { type: "button", class: "icon-btn menu-btn", "aria-label": "Open menu", on: { click: () => app.classList.toggle("menu-open") } }, icon("menu")),
        h("div", { class: "seg", role: "group", "aria-label": "Environment" },
          h("button", { type: "button", "aria-pressed": "true" }, "Production"),
          h("button", { type: "button", "aria-pressed": "false", disabled: true, title: "Staging needs a second Supabase project (the free plan's 2-project limit is reached)." }, "Staging")),
        h("form", { class: "search", role: "search", on: { submit: search } },
          icon("search", 16), h("label", { class: "sr", for: "global-search" }, "Search"),
          h("input", { type: "search", id: "global-search", placeholder: "Search an email or content name" })),
        themeToggle(),
        h("button", { type: "button", class: "icon-btn", "aria-label": `Admin menu: ${me.email}`, on: { click: adminMenu } }, initials)),
      h("main", { class: "content", id: "page", tabindex: "-1" })));
  clear(root).append(app);
}

function search(e) {
  e.preventDefault();
  const q = e.target.querySelector("input").value.trim();
  if (!q) return;
  location.hash = q.includes("@") ? `#/accounts?email=${encodeURIComponent(q)}` : `#/content?q=${encodeURIComponent(q)}`;
}

function adminMenu(e) {
  const old = document.querySelector(".admin-pop");
  if (old) return old.remove();
  const r = e.currentTarget.getBoundingClientRect();
  const pop = h("div", { class: "dialog admin-pop", role: "dialog", "aria-label": "Admin", style: { top: `${r.bottom + 8}px`, left: "auto", right: "16px", transform: "none", width: "280px" } },
    h("b", {}, me.email), h("span", { class: "muted small" }, `${ROLE_LABEL[me.role]} · two-step sign-in on`),
    h("button", { type: "button", class: "btn", on: { click: async () => { await sb.auth.signOut({ scope: "local" }); location.reload(); } } }, icon("out"), "Sign out"));
  document.body.append(pop);
  setTimeout(() => document.addEventListener("click", function off(ev) { if (!pop.contains(ev.target)) { pop.remove(); document.removeEventListener("click", off); } }), 0);
}

async function route() {
  if (!me) return;
  const { id, params } = parseHash(location.hash);
  const page = PAGES.find((p) => p.id === id);
  document.querySelectorAll(".nav").forEach((a) => a.setAttribute("aria-current", a.dataset.id === id ? "page" : "false"));
  document.querySelector(".app")?.classList.remove("menu-open");
  document.title = `${page.label} · Gymco Control Center`;
  const el = document.getElementById("page");
  const ticket = ++mounted;
  if (!can(me.role, page.cap)) return clear(el).append(needsRole(page));
  clear(el).append(skeleton());
  try {
    const mod = await import(`./pages/${id}.js`);
    if (ticket !== mounted) return;
    clear(el);
    await mod.render(el, { me, call, params, toast, isCurrent: () => ticket === mounted });
  } catch (e) {
    if (ticket !== mounted) return;
    if (e instanceof ApiError && e.status === 401) return;
    clear(el).append(errorBanner(e instanceof ApiError && e.status === 0 ? "You're offline" : "Couldn't load this section",
      e instanceof ApiError && e.code === "forbidden" ? "Your role can't open this." : "Try again in a moment.", route));
  }
  el.focus({ preventScroll: true });
}

function needsRole(page) {
  const need = { read: "Viewer", support: "Support", draft: "Editor", team: "Owner" }[page.cap] ?? "Owner";
  const reach = PAGES.filter((p) => can(me.role, p.cap)).map((p) => p.label).join(", ");
  return h("div", { class: "card", style: { maxWidth: "560px" } },
    h("span", { style: { color: "var(--warn)" } }, icon("lock", 28)),
    h("h2", {}, `${page.label} needs the ${need} role`),
    h("p", { class: "muted", style: { margin: "0" } }, `You're signed in as ${ROLE_LABEL[me.role]}. You can open: ${reach}.`),
    h("div", { class: "pills" }, h("a", { class: "btn", href: "#/overview" }, "Back to Overview")));
}

window.addEventListener("hashchange", route);

// Idle sign-out after 12 hours; any input counts as activity.
let lastMark = 0;
for (const ev of ["pointerdown", "keydown"]) {
  addEventListener(ev, () => {
    if (Date.now() - lastMark > 60000) {
      lastMark = Date.now();
      markActive();
    }
  }, { passive: true });
}
setInterval(async () => {
  if (me && idleTooLong()) {
    me = null;
    await sb.auth.signOut({ scope: "local" });
    start({ expired: true });
  }
}, 60000);

onAuthLost.handler = (why) => {
  if (!me) return;
  me = null;
  toast(why === "mfa_required" ? "Two-step sign-in needed again" : "Signed out", "bad");
  start();
};

if (!sb) {
  clear(root).append(h("div", { class: "gate" }, h("div", { class: "card" },
    empty("Couldn't load the sign-in library", "A script from cdn.jsdelivr.net didn't load. Check the connection or an ad blocker, then reload.",
      h("button", { type: "button", class: "btn primary", on: { click: () => location.reload() } }, "Reload")))));
} else {
  start();
}
