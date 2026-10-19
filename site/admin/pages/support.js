// 02 Support inbox: tickets from support@gymcoapp.com and the in-app form.
// New / Waiting / Solved tabs plus deletion requests with their 30-day
// countdown; replies use saved templates in EN / AR / ES and go out by
// email when the server can send, or through the admin's mail client.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { dayLabel, relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import { ageLabel, ageLate, daysLeft, deadlineLine, fillTemplate, LANG_NAME, TABS, tabLabel, TEMPLATE_LABEL, ticketMeta } from "../lib/support.js";
import { chip, confirmDialog, empty, LANGS, pageHead, sheet, statusChip, table } from "../lib/ui.js";

const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const EMPTY = {
  new: ["Inbox zero", "No new tickets. Waiting and Solved are one tab away."],
  waiting: ["Nothing waiting", "No ticket is waiting on a customer right now."],
  solved: ["Nothing solved yet", "Solved tickets stay here for reference."],
  deletion: ["No deletion requests", "Deletion tickets land here with their 30-day countdown, overdue first."],
};

export async function render(el, { call, toast, me, params, isCurrent }) {
  let tab = TABS.some(([k]) => k === params.tab) ? params.tab : "new";
  let q = params.q ?? "";
  let openId = params.id ?? null;
  let counts = {};
  let items = [];
  let templates = null;
  let lang = "en";

  const tabs = h("div", { class: "pills", role: "tablist", "aria-label": "Tickets" });
  const search = h("input", { class: "input", type: "search", placeholder: "Search subject, email or tag", value: q, "aria-label": "Search tickets", style: { maxWidth: "280px" } });
  search.addEventListener("change", () => { q = search.value.trim(); load(); });
  const listCard = h("section", { class: "card" });
  const detail = h("section", { class: "card support-detail" });
  el.append(
    pageHead("People", "Support", "inbox", h("button", { type: "button", class: "btn", on: { click: addTicket } }, icon("plus"), "Add ticket")),
    h("div", { class: "row", style: { alignItems: "center" } }, tabs, search),
    h("div", { class: "row support-row" }, h("div", { class: "grow stack", style: { gap: "16px" } }, listCard), h("div", { class: "side-col support-side" }, detail)));

  function setHash() {
    history.replaceState(null, "", `#/support?tab=${tab}${q ? `&q=${encodeURIComponent(q)}` : ""}${openId ? `&id=${encodeURIComponent(openId)}` : ""}`);
  }

  function drawTabs() {
    put(tabs, TABS.map(([k]) => h("button", { type: "button", role: "tab", class: "pill pack-pill", "aria-selected": String(k === tab), "aria-pressed": String(k === tab), on: { click: () => { tab = k; load(); } } },
      tabLabel(k, counts), k === "deletion" && counts.overdue ? h("span", { class: "pill-n", style: { color: "var(--critical)" } }, `${counts.overdue} overdue`) : null)));
  }

  async function load() {
    setHash();
    put(listCard, h("div", { class: "skel", style: { height: "240px" } }));
    const r = await call("tickets.list", { tab, q: q || undefined });
    if (!isCurrent()) return;
    items = r.items ?? [];
    counts = r.counts ?? {};
    drawTabs();
    drawList();
    if (openId) open(openId);
    else drawDetail(null);
  }

  function drawList() {
    const now = new Date();
    const [title, sub] = EMPTY[tab];
    put(listCard,
      h("div", { class: "card-head" }, h("h2", {}, tabLabel(tab, counts)), h("span", { class: "small muted" }, tab === "deletion" ? "Overdue first · 30 days from the request" : tab === "new" ? "Oldest first · red after 24 h" : null)),
      table([
        { label: "Subject", class: "strong", cell: (t) => h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } }, h("span", {}, t.subject),
          h("span", { class: "small muted" }, [t.email, ...(t.tags ?? [])].join(" · "))) },
        { label: "Lang", cell: (t) => LANG_NAME[t.locale] ?? t.locale ?? "—" },
        { label: "Version", cell: (t) => (t.app_version ? h("span", { class: "num" }, `v${t.app_version}`) : "—") },
        { label: "Status", cell: (t) => statusChip(t.status) },
        tab === "deletion"
          ? { label: "Deadline", end: true, cell: (t) => { const d = deadlineLine(daysLeft(t.deadline_at, now), t.deadline_at); return d ? chip(`${d.number} ${d.label.split(" ")[0]} ${d.tone === "bad" ? "overdue" : "left"}`, d.tone || "flat") : "—"; } }
          : { label: "Age", end: true, cell: (t) => h("span", { class: "num", style: ageLate(t, now) ? { color: "var(--critical)", fontWeight: "700" } : null }, ageLabel(t.created_at, now)) },
      ], items, { onRow: (t) => open(t.id), selected: (t) => t.id === openId, empty: q ? empty(`Nothing matches “${q}”`, "Search covers subject, email and tags.", h("button", { type: "button", class: "btn small", on: { click: () => { q = ""; search.value = ""; load(); } } }, "Clear search")) : empty(title, sub) }));
  }

  async function open(id) {
    openId = id;
    setHash();
    drawList();
    put(detail, h("div", { class: "skel", style: { height: "320px" } }));
    try {
      const [r, t] = await Promise.all([call("tickets.get", { id }), templates ? null : call("tickets.templates").catch(() => null)]);
      if (!isCurrent()) return;
      if (t) templates = t.templates ?? null;
      drawDetail(r);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) throw e;
      put(detail, h("div", { class: "banner", role: "alert" }, h("div", {}, h("b", {}, "Couldn’t open this ticket"), h("div", { class: "small muted" }, "Try again in a moment.")),
        h("button", { type: "button", class: "btn small", on: { click: () => open(id) } }, "Try again")));
    }
  }

  function drawDetail(r) {
    if (!r) return put(detail, h("h2", {}, "Ticket"), empty("Pick a ticket", "Its message, thread and reply box show here."));
    const t = r.ticket;
    const dl = t.kind === "deletion" ? deadlineLine(r.days_left ?? daysLeft(t.deadline_at), t.deadline_at) : null;
    const reply = h("textarea", { class: "input", rows: "7", "aria-label": "Reply", dir: "auto" });
    const tplRow = h("div", { class: "pills" });
    const drawTpl = () => put(tplRow,
      h("div", { class: "seg", role: "group", "aria-label": "Template language" }, LANGS.map(([k, l]) => h("button", { type: "button", "aria-pressed": String(k === lang), on: { click: () => { lang = k; drawTpl(); } } }, l))),
      templates ? Object.keys(TEMPLATE_LABEL).filter((k) => templates[k]).map((k) =>
        h("button", { type: "button", class: "pill small", on: { click: () => { reply.value = fillTemplate(templates[k]?.[lang], t.email); reply.dir = lang === "ar" ? "rtl" : "ltr"; reply.focus(); } } }, TEMPLATE_LABEL[k])) : h("span", { class: "small muted" }, "Templates didn’t load"));
    drawTpl();
    const act = async (action, body, done) => {
      try {
        const res = await call(action, { id: t.id, ...body });
        if (res?.sent === false && res.mailto) {
          location.href = res.mailto;
          toast("Your mail client was opened with the reply · it’s saved here too");
        } else toast(done);
        await load();
      } catch (e) {
        toast(e instanceof ApiError && e.code === "invalid" ? "The reply can’t be empty" : "Couldn’t do that", "bad");
      }
    };
    const send = (status) => {
      const body = reply.value.trim();
      if (!body) return status ? act("tickets.set_status", { status }, `Marked ${status}`) : toast("Write a reply first", "bad");
      return act("tickets.reply", { body, status: status ?? undefined }, status ? `Sent and marked ${status}` : "Sent");
    };
    put(detail,
      h("div", { class: "stack", style: { gap: "4px" } },
        h("div", { class: "card-head" }, h("h2", {}, t.subject), statusChip(t.status)),
        h("span", { class: "small muted" }, ticketMeta(t)),
        h("div", { class: "pills", style: { alignItems: "center" } },
          t.has_account
            ? h("a", { class: "btn small", href: `#/accounts?email=${encodeURIComponent(t.email)}` }, "Open account")
            : h("span", { class: "small muted" }, "Sender email has no account · reply with the “Nothing stored” template"),
          chip(`${t.platform ?? "?"} · ${relTime(t.created_at)}`, "flat"))),
      dl ? h("div", { class: `deadline ${dl.tone}` },
        h("span", { class: "bignum num" }, dl.number),
        h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, dl.label), h("span", { class: "small muted" }, dl.legal))) : null,
      h("div", { class: "well stack", style: { gap: "4px" } }, h("span", { class: "small muted" }, `${t.email} · ${dayLabel(t.created_at)}`), h("p", { dir: "auto", lang: t.locale, style: { margin: "0", whiteSpace: "pre-wrap" } }, t.body ?? "")),
      (r.messages ?? []).map((m) => h("div", { class: `well stack${m.from_admin ? " from-admin" : ""}`, style: { gap: "4px" } },
        h("span", { class: "small muted" }, `${m.from_admin ? `${m.author?.split("@")[0] ?? "Admin"} (Gymco)` : m.author ?? t.email} · ${dayLabel(m.at)}`), h("p", { dir: "auto", style: { margin: "0", whiteSpace: "pre-wrap" } }, m.body))),
      h("div", { class: "pills", style: { alignItems: "center" } }, (t.tags ?? []).map((g) => chip(g, g === "deletion" ? "bad" : "flat")),
        h("button", { type: "button", class: "btn small link", on: { click: () => addTag(t) } }, "+ Tag")),
      h("div", { class: "rule" }),
      h("div", { class: "stack", style: { gap: "8px" } }, h("span", { class: "small muted strong" }, "Reply template"), tplRow, reply),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small primary", on: { click: () => send("solved") } }, "Send and mark Solved"),
        h("button", { type: "button", class: "btn small", on: { click: () => send("waiting") } }, "Set Waiting"),
        t.status === "solved" ? h("button", { type: "button", class: "btn small", on: { click: () => act("tickets.set_status", { status: "new" }, "Reopened") } }, "Reopen") : null),
      h("span", { class: "small muted" }, "Sent from support@gymcoapp.com when email sending is set up; otherwise your mail client opens with the reply."));
  }

  async function addTag(t) {
    const input = h("input", { class: "input", placeholder: "bug, billing, deletion, feature idea", maxlength: "20", "aria-label": "Tag" });
    const ok = await confirmDialog({ title: "Add a tag", body: "Up to five tags of 20 characters.", confirm: "Add", field: h("label", { class: "field" }, h("span", {}, "Tag"), input) });
    const tag = input.value.trim().toLowerCase();
    if (!ok || !tag) return;
    const tags = [...new Set([...(t.tags ?? []), tag])].slice(0, 5);
    try {
      await call("tickets.tag", { id: t.id, tags });
      toast(`Tagged ${tag}`);
      load();
    } catch {
      toast("Couldn’t add the tag", "bad");
    }
  }

  function addTicket() {
    const email = h("input", { class: "input", type: "email", required: true, "aria-label": "Email" });
    const subject = h("input", { class: "input", maxlength: "120", "aria-label": "Subject" });
    const bodyF = h("textarea", { class: "input", rows: "5", "aria-label": "Message", dir: "auto" });
    const locale = h("select", { class: "input", "aria-label": "Language" }, Object.entries(LANG_NAME).map(([v, t]) => h("option", { value: v }, t)));
    const kind = h("input", { type: "checkbox", "aria-label": "Deletion request" });
    const s = sheet("Add a ticket", h("div", { class: "stack", style: { gap: "12px" } },
      h("span", { class: "small muted" }, "For a request that arrived by phone or in person. It gets the same thread and templates."),
      h("label", { class: "field" }, h("span", {}, "Sender email"), email),
      h("label", { class: "field" }, h("span", {}, "Subject"), subject),
      h("label", { class: "field" }, h("span", {}, "Message"), bodyF),
      h("label", { class: "field" }, h("span", {}, "Language"), locale),
      h("label", { class: "cfg-row", style: { alignItems: "center", cursor: "pointer" } }, h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, "Deletion request"), h("span", { class: "small muted" }, "Starts the 30-day countdown")), kind)),
    [h("button", { type: "button", class: "btn small", on: { click: () => s.close() } }, "Cancel"),
      h("button", { type: "button", class: "btn small primary", on: { click: async () => {
        if (!email.value.includes("@") || !subject.value.trim() || !bodyF.value.trim()) return toast("Email, subject and message are needed", "bad");
        try {
          const r = await call("tickets.add", { email: email.value.trim(), subject: subject.value.trim(), body: bodyF.value.trim(), locale: locale.value, kind: kind.checked ? "deletion" : "general" });
          s.close();
          toast("Ticket added");
          tab = kind.checked ? "deletion" : "new";
          openId = r.id;
          load();
        } catch {
          toast("Couldn’t add the ticket", "bad");
        }
      } } }, "Add ticket")]);
  }

  if (!can(me.role, "support")) return;
  await load();
}
