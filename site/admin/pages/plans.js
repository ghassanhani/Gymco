// 08 Plans & pricing: the three plans and their store product IDs, the
// testing switch that unlocks Pro for everyone, and manual grants. Store
// prices live in App Store Connect and Play Console; nothing here invents one.
// The two switches are Remote config keys, published the same way that page does.

import { ApiError } from "../lib/api.js";
import { h } from "../lib/dom.js";
import { dayLabel, relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import { countChanges, setKey } from "../lib/config_form.js";
import { chip, confirmDialog, diffView, empty, pageHead, table, toggleSwitch } from "../lib/ui.js";

const PLANS = [
  { id: "free", name: "Free", ios: null, android: null, price: "€0", note: (scans) => `Diary, training and ${scans} AI scans a day` },
  { id: "pro", name: "Pro", ios: "gymco.pro.monthly", android: "gymco_pro_monthly", price: null, note: () => "Monthly subscription · intro offers are set in the stores" },
  { id: "lifetime", name: "Lifetime", ios: "gymco.lifetime", android: "gymco_lifetime", price: null, note: () => "One-time purchase" },
];

const BEHIND_PRO = [
  ["AI photo logging", "Free · capped"], ["Eating out estimates", "Free"], ["Account backup", "Free"],
  ["Custom routine templates", "Pro"], ["Advanced progress charts", "Pro"], ["Extra daily scans", "Pro"],
];

const SWITCHES = [
  ["plans.testing_unlock_all", "Testing mode", "Every Pro feature unlocked for everyone"],
  ["plans.paywall_enabled", "Paywall", "Free users can see and buy Pro"],
];

export async function render(el, { call, toast, me }) {
  const owner = can(me.role, "owner_keys");
  let cfg;
  const banner = h("section", { class: "card" });
  const grants = h("section", { class: "card" });
  el.append(pageHead("App · Owner only", "Plans &", "pricing"), banner,
    h("div", { class: "grid plan-cards" }, PLANS.map(() => h("div"))),
    h("div", { class: "grid two" }, behindPro(), h("div", { class: "stack", style: { gap: "16px" } }, regions(), promos())),
    grants);
  const cards = el.querySelector(".plan-cards");

  const live = () => cfg.published?.body ?? cfg.base;
  const get = (body, path) => path.split(".").reduce((o, k) => o?.[k], body);

  async function loadConfig() {
    cfg = await call("config.get");
    drawBanner();
    cards.replaceChildren(...PLANS.map(planCard));
  }

  function drawBanner() {
    const body = live();
    const testing = !!get(body, "plans.testing_unlock_all");
    const paywall = !!get(body, "plans.paywall_enabled");
    const [title, sub, tone] = testing
      ? ["Testing mode is on", `Every Pro feature is unlocked for everyone. The paywall is ${paywall ? "on, but nothing is locked behind it" : "off"}.`, "warn"]
      : paywall
        ? ["The paywall is on", "Pro features need Pro or Lifetime. Free users can buy them in the app.", "info"]
        : ["Pro is locked and the paywall is off", "Pro features are locked, and nobody can buy them yet. Turn testing back on or turn the paywall on.", ""];
    const draftBody = cfg.draft?.body;
    banner.replaceChildren(
      h("div", { class: `banner ${tone}` }, h("div", {}, h("b", {}, title), h("div", { class: "small" }, sub))),
      ...SWITCHES.map(([path, label, help]) => {
        const pending = draftBody && get(draftBody, path) !== get(body, path);
        return h("div", { class: "cfg-row", style: { alignItems: "center" } },
          h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } },
            h("span", { class: "strong" }, label),
            h("span", { class: "small muted" }, `${help} · ${path.split(".")[1]}`),
            pending ? h("span", { class: "small", style: { color: "var(--warn)" } }, `Draft v${cfg.draft.version} in Remote config sets this ${get(draftBody, path) ? "on" : "off"}`) : null),
          toggleSwitch(label, get(body, path), (on) => flip(path, label, on), { disabled: !owner }));
      }),
      owner
        ? h("span", { class: "small muted" }, "Switching publishes a new Remote config version right away. Phones pick it up on next launch or within 6 h.")
        : h("span", { class: "small muted" }, "Only the Owner can change these. You can see them here and on Remote config."));
  }

  async function flip(path, label, on) {
    // A switch builds on the open draft, so nothing in it is lost; its other changes go out too.
    const start = cfg.draft?.body ?? live();
    const next = setKey(start, path, on);
    const others = cfg.draft ? countChanges(live(), start) : 0;
    const ok = await confirmDialog({
      title: `Turn ${label.toLowerCase()} ${on ? "on" : "off"}?`,
      body: h("div", { class: "stack" }, diffView(live(), next),
        others ? h("span", { class: "small", style: { color: "var(--warn)" } }, `Draft v${cfg.draft.version} in Remote config has ${others} other change${others === 1 ? "" : "s"}; ${others === 1 ? "it goes" : "they go"} out with this.`) : null,
        h("span", { class: "small muted" }, "This publishes a new Remote config version. Rollback is on the Remote config page.")),
      confirm: "Publish",
    });
    if (!ok) return drawBanner();
    try {
      await call("config.save_draft", { body: next, note: `${label} ${on ? "on" : "off"}` });
      const fresh = await call("config.get");
      await call("config.publish", { version: fresh.draft.version });
      toast(`${label} ${on ? "on" : "off"} · v${fresh.draft.version} published`);
    } catch (e) {
      toast(e instanceof ApiError && e.code === "owner_keys" ? "Only the Owner can change this" : "Couldn’t publish the change", "bad");
    }
    await loadConfig();
  }

  function planCard(p) {
    const scans = get(live(), "limits.ai_scans_per_day") ?? 10;
    const store = (name, id) => h("div", { class: "store-id" }, h("span", { class: "small muted" }, name), h("span", { class: "mono" }, id));
    return h("div", { class: `card plan-card plan-${p.id}` },
      h("div", { class: "row", style: { gap: "10px", alignItems: "center" } }, h("span", { class: "plan-dot", "aria-hidden": "true" }), h("h2", {}, p.name)),
      p.price
        ? h("div", { class: "plan-price" }, p.price)
        : h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, "Price set in the stores"), h("span", { class: "small muted" }, "Set in App Store Connect and Play Console")),
      p.ios ? [store("App Store", p.ios), store("Google Play", p.android)] : h("span", { class: "small muted" }, "No store product"),
      h("span", { class: "small muted" }, p.note(scans)));
  }

  function behindPro() {
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "What sits behind Pro"), chip("Read only", "flat")),
      h("div", { class: "stack", style: { gap: "0" } }, BEHIND_PRO.map(([name, tier]) =>
        h("div", { class: "cfg-row", style: { alignItems: "center" } }, h("span", {}, name), chip(tier, tier === "Pro" ? "brand" : "flat")))),
      h("span", { class: "small muted" }, "While testing mode is on, all of these are open to everyone. This list becomes editable when the paywall ships."));
  }

  function regions() {
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "Prices by region"), h("span", { class: "small muted" }, "Mirrored from the stores · read only")),
      empty("Arrives with the store connection", "Prices are set in App Store Connect and Play Console. Once the paywall ships, they show here per region."));
  }

  function promos() {
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "Promo codes"), h("span", { class: "small muted" }, "Offer codes from the stores")),
      empty("No promo codes yet", "Codes arrive with the paywall and the store connection. To give someone Pro now, grant it from their account."));
  }

  async function loadGrants() {
    const head = h("div", { class: "card-head" }, h("h2", {}, "Manual grants"), h("a", { href: "#/accounts", class: "small", style: { fontWeight: "600" } }, "Grant or revoke in Accounts"));
    try {
      const r = await call("plans.grants");
      const rows = Array.isArray(r) ? r : r?.grants ?? [];
      grants.replaceChildren(head,
        table([
          { label: "Account", cell: (g) => h("a", { href: `#/accounts?email=${encodeURIComponent(g.email)}`, style: { fontWeight: "600" } }, g.email) },
          { label: "Plan", cell: (g) => chip(g.plan === "lifetime" ? "Lifetime" : "Pro", "brand") },
          { label: "Ends", cell: (g) => (g.expires_at ? dayLabel(g.expires_at) : "No end") },
          { label: "Granted", cell: (g) => `${relTime(g.granted_at)}${g.granted_by ? ` · ${g.granted_by}` : ""}` },
        ], rows, { empty: empty("No manual grants", "Testers, refunds and press get Pro or Lifetime from their account in Accounts.") }),
        h("span", { class: "small muted" }, "Each grant was logged with a reason. Open an account to change or remove its grant."));
    } catch (e) {
      if (!(e instanceof ApiError) || e.status === 401) throw e;
      grants.replaceChildren(head, h("span", { class: "small muted" }, e.code === "forbidden" || e.status === 403 ? "Your role can’t see manual grants. Support, Editor and Owner can." : "Couldn’t load the grants. Try again in a moment."));
    }
  }

  await Promise.all([loadConfig(), loadGrants()]);
}
