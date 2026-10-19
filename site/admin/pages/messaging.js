// 09 Messaging: in-app announcements (a card on Today), one-off push
// campaigns (device tokens only, one a week, quiet hours) and a note on
// where the email templates live. The voice checklist sits beside every
// editor; the server's warnings are the ones that count.

import { ApiError } from "../lib/api.js";
import { clear, h, icon } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { dayLabel, fmtInt } from "../lib/format.js";
import { targetLabel } from "../lib/config_form.js";
import { onDate, quietNote, weekTakenBy } from "../lib/push_rules.js";
import { can } from "../lib/roles.js";
import { LANG_NAME, TEMPLATE_LABEL } from "../lib/support.js";
import { voiceIssuesT3, voiceLine } from "../lib/voice.js";
import { chip, confirmDialog, empty, LANGS, langField, pageHead, phonePreview, statusChip, table } from "../lib/ui.js";

const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const TABS = [["announcements", "Announcements"], ["push", "Push campaigns"], ["email", "Email templates"]];
const T3 = () => ({ en: "", ar: "", es: "" });
const pad = (n) => String(n).padStart(2, "0");
const toLocal = (iso) => {
  if (!iso) return "";
  const d = new Date(iso);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};
const fromLocal = (v) => (v ? new Date(v).toISOString() : null);
const localLabel = (local) => (local ? `${dayLabel(local.slice(0, 10))} · ${local.slice(11, 16)}` : "—");
const windowLabel = (a) => `${a.starts_at ? dayLabel(a.starts_at) : "—"} → ${a.ends_at ? dayLabel(a.ends_at) : "—"}`;
const warnText = (w) => (typeof w === "string" ? w : w?.message ?? (w?.phrase ? voiceLine(w) : String(w)));

// A few words of the app's Today screen for the preview.
const UI = { en: { today: "Today", missing: "Missing English" }, ar: { today: "اليوم", missing: "ينقص النص العربي" }, es: { today: "Hoy", missing: "Falta el español" } };

export async function render(el, { call, toast, me, params, isCurrent }) {
  const publisher = can(me.role, "publish");
  let tab = TABS.some(([k]) => k === params.tab) ? params.tab : "announcements";
  let lang = "en";

  const tabs = h("div", { class: "pills", role: "tablist", "aria-label": "Channel" });
  const body = h("div", { class: "stack", style: { gap: "16px" } });
  el.append(pageHead("App", "Messaging", "& push"), tabs, body);

  function drawTabs() {
    put(tabs, TABS.map(([k, label]) => h("button", { type: "button", role: "tab", class: "pill", "aria-selected": String(k === tab), "aria-pressed": String(k === tab), on: { click: () => { tab = k; history.replaceState(null, "", `#/messaging?tab=${k}`); drawTabs(); drawTab(); } } }, label)));
  }

  async function drawTab() {
    put(body, h("div", { class: "skel", style: { height: "320px", borderRadius: "24px" } }));
    try {
      if (tab === "announcements") await announcements();
      else if (tab === "push") await push();
      else await emails();
    } catch (e) {
      if (!isCurrent()) return;
      if (e instanceof ApiError && e.status === 401) throw e;
      put(body, h("div", { class: "banner", role: "alert" }, h("div", {}, h("b", {}, "Couldn’t load this tab"), h("div", { class: "small muted" }, "Try again in a moment.")),
        h("button", { type: "button", class: "btn small", on: { click: drawTab } }, "Try again")));
    }
  }

  /** The EN / AR / ES switch that every preview shares. */
  function langSeg(onPick) {
    return h("div", { class: "seg", role: "group", "aria-label": "Preview language" }, LANGS.map(([k, t]) =>
      h("button", { type: "button", "aria-pressed": String(k === lang), on: { click: () => { lang = k; onPick(); } } }, t)));
  }

  /** The three lines of the voice checklist, with a mark that turns when a hit is found. */
  function voiceCard(getHits) {
    const box = h("section", { class: "card" });
    box.refresh = () => {
      const hits = getHits();
      const lines = [["Plain words, no jargon", false], ["Calm, no urgency tricks", false], ["No shaming about food or weight", hits.length > 0]];
      put(box, h("div", { class: "card-head" }, h("h2", {}, "Voice checklist"), hits.length ? chip(`${hits.length} to look at`, "warn") : chip("All clear", "good")),
        h("div", { class: "stack checks" }, lines.map(([t, bad]) => h("div", { class: "check" }, h("span", { class: `mark ${bad ? "warn" : "good"}`, "aria-hidden": "true" }, bad ? "!" : "✓"), h("span", { class: "strong" }, t)))),
        hits.length ? h("div", { class: "stack", style: { gap: "4px" } }, hits.map((x) => h("span", { class: "small", style: { color: "var(--warn)" } }, `${x.lang ? `${x.lang.toUpperCase()} · ` : ""}${voiceLine(x)}`))) : null,
        h("span", { class: "small muted" }, "The server runs the same check when you save; its warnings show next to the body."));
    };
    box.refresh();
    return box;
  }

  // ---- Announcements
  async function announcements() {
    const { items } = await call("announce.list");
    if (!isCurrent()) return;
    let ann = blankAnn();
    let serverWarns = [];
    let errs = [];
    const errLines = new Map();
    const errLine = (key) => {
      const e = h("span", { class: "field-err", role: "alert" });
      errLines.set(key, e);
      return e;
    };
    const showErrs = () => {
      for (const [key, e] of errLines) {
        const msgs = errs.filter((x) => x.key === key || x.key?.startsWith(`${key}.`)).map((x) => x.message);
        e.textContent = [...new Set(msgs)].join(" · ");
        e.hidden = !msgs.length;
      }
    };

    const editor = h("section", { class: "card" });
    const previewCard = h("section", { class: "card" });
    const voice = voiceCard(() => voiceIssuesT3(ann.body).concat(voiceIssuesT3(ann.title)));
    const listCard = h("section", { class: "card" });
    put(body, h("div", { class: "row" }, h("div", { class: "grow stack", style: { gap: "16px" } }, editor), h("div", { class: "side-col" }, previewCard, voice)), listCard);

    function blankAnn() {
      const start = new Date();
      const end = new Date(Date.now() + 14 * 86400000);
      return { id: null, title: T3(), body: T3(), cta: null, starts_at: start.toISOString(), ends_at: end.toISOString(), targeting: {}, status: "draft" };
    }

    function drawEditor() {
      errLines.clear();
      const warnBox = h("div", { class: "stack", style: { gap: "4px" } });
      const refreshWarns = () => {
        const local = voiceIssuesT3(ann.body).map(voiceLine);
        const all = [...new Set([...serverWarns.map(warnText), ...local])];
        put(warnBox, all.map((w) => h("span", { class: "small", role: "status", style: { color: "var(--warn)", fontWeight: "600" } }, w)));
        voice.refresh();
        drawPreview();
      };
      const title = langField("Title", ann.title, { max: 80, onChange: (v) => { ann.title = v; refreshWarns(); } });
      const bodyF = langField("Body", ann.body, { multiline: true, max: 500, onChange: (v) => { ann.body = v; refreshWarns(); } });
      const ctaOn = h("input", { type: "checkbox", checked: !!ann.cta, "aria-label": "Add a button" });
      const ctaBox = h("div", { class: "stack", hidden: !ann.cta });
      const ctaLabel = langField("Button label", ann.cta?.label ?? {}, { max: 40, onChange: (v) => { ann.cta = { ...(ann.cta ?? { url: "" }), label: v }; drawPreview(); } });
      const ctaUrl = h("input", { class: "input", type: "url", placeholder: "https://", value: ann.cta?.url ?? "", "aria-label": "Button link", on: { input: () => { ann.cta = { ...(ann.cta ?? { label: T3() }), url: ctaUrl.value.trim() }; } } });
      put(ctaBox, ctaLabel, h("label", { class: "field" }, h("span", {}, "Link (https)"), ctaUrl, errLine("cta.url")), errLine("cta.label"));
      ctaOn.addEventListener("change", () => {
        ann.cta = ctaOn.checked ? { label: ctaLabel.value(), url: ctaUrl.value.trim() } : null;
        ctaBox.hidden = !ctaOn.checked;
        drawPreview();
      });
      const starts = h("input", { class: "input", type: "datetime-local", value: toLocal(ann.starts_at), "aria-label": "Starts", on: { input: () => { ann.starts_at = fromLocal(starts.value); } } });
      const ends = h("input", { class: "input", type: "datetime-local", value: toLocal(ann.ends_at), "aria-label": "Ends", on: { input: () => { ann.ends_at = fromLocal(ends.value); } } });
      const sel = (label, key, opts) => {
        const s = h("select", { class: "input", "aria-label": label }, opts.map(([v, t]) => h("option", { value: v, selected: (ann.targeting[key] ?? "") === v }, t)));
        s.addEventListener("change", () => { if (s.value) ann.targeting[key] = s.value; else delete ann.targeting[key]; });
        return h("label", { class: "field" }, h("span", {}, label), s);
      };
      const num = (label, key) => {
        const i = h("input", { class: "input num", type: "number", min: "0", max: "100000", placeholder: "Any", value: ann.targeting[key] ?? "", "aria-label": label });
        i.addEventListener("input", () => { if (i.value === "") delete ann.targeting[key]; else ann.targeting[key] = Number(i.value); });
        return h("label", { class: "field" }, h("span", {}, label), i);
      };
      const draft = can(me.role, "draft");
      put(editor,
        h("div", { class: "card-head" }, h("h2", {}, ann.id ? "Edit announcement" : "New announcement · card on Today"), ann.id ? statusChip(ann.status) : chip("Not saved", "flat")),
        title, errLine("title"),
        bodyF, errLine("body"), warnBox,
        h("label", { class: "cfg-row", style: { alignItems: "center", cursor: "pointer" } }, h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, "Button"), h("span", { class: "small muted" }, "Optional. Opens a link from the card.")), ctaOn),
        ctaBox,
        h("div", { class: "form" },
          h("label", { class: "field" }, h("span", {}, "Starts"), starts, errLine("starts_at")),
          h("label", { class: "field" }, h("span", {}, "Ends"), ends, errLine("ends_at"))),
        h("div", { class: "stack", style: { gap: "6px" } }, h("span", { class: "small muted strong" }, "Targeting"),
          h("div", { class: "form" },
            sel("Platform", "platform", [["", "All platforms"], ["ios", "iOS"], ["android", "Android"]]),
            sel("Language", "locale", [["", "All languages"], ["en", "English"], ["ar", "Arabic"], ["es", "Spanish"]]),
            num("From build", "min_build"), num("To build", "max_build"))),
        h("div", { class: "pills", style: { justifyContent: "flex-end" } },
          ann.id ? h("button", { type: "button", class: "btn small", on: { click: () => { ann = blankAnn(); serverWarns = []; errs = []; drawEditor(); } } }, "New announcement") : null,
          h("button", { type: "button", class: "btn small primary", disabled: !draft, on: { click: () => save() } }, "Save draft"),
          publisher ? h("button", { type: "button", class: "btn small publish", on: { click: () => save(true) } }, "Publish") : h("span", { class: "small muted" }, "Publishing needs the Owner")));
      refreshWarns();
      showErrs();
    }

    function drawPreview() {
      const u = UI[lang];
      const tx = (t) => t?.[lang]?.trim() || h("span", { class: "pmiss" }, u.missing);
      const card = h("div", { class: "pcard stack", style: { gap: "6px" } },
        h("span", { class: "pline" }, u.today), h("span", { class: "ptitle" }, tx(ann.title)), h("span", {}, tx(ann.body)),
        ann.cta ? h("span", { class: "pbtn" }, tx(ann.cta.label)) : null);
      put(previewCard, h("div", { class: "card-head" }, h("h2", {}, "Preview on Today"), h("span", { class: "small muted" }, lang === "ar" ? "Arabic reads right to left" : "Under the catch-up card")),
        langSeg(drawPreview), h("div", { lang, class: lang === "ar" ? "ar" : null, style: { display: "flex", justifyContent: "center" } }, phonePreview(card, { rtl: lang === "ar" })));
    }

    async function save(publish = false) {
      const payload = { id: ann.id ?? undefined, title: ann.title, body: ann.body, cta: ann.cta ?? undefined, starts_at: ann.starts_at, ends_at: ann.ends_at, targeting: ann.targeting };
      try {
        const r = await call("announce.save", payload);
        ann.id = r.id;
        serverWarns = r.warnings ?? [];
        errs = [];
        if (publish) {
          if (serverWarns.length && !(await confirmDialog({ title: "Publish with warnings?", body: h("div", { class: "stack" }, serverWarns.map((w) => h("span", { class: "small" }, warnText(w)))), confirm: "Publish" }))) return refresh("Draft saved");
          await call("announce.publish", { id: r.id });
          toast("Announcement published · phones pick it up with the config");
        } else toast(serverWarns.length ? "Draft saved with warnings" : "Draft saved");
        refresh();
      } catch (e) {
        if (e instanceof ApiError && e.code === "invalid") {
          errs = e.body?.errors ?? [];
          showErrs();
          toast("Fix the highlighted values first", "bad");
        } else toast(publish ? "Couldn’t publish" : "Couldn’t save the draft", "bad");
      }
    }

    async function refresh(msg) {
      if (msg) toast(msg);
      const keep = ann.id;
      const { items: fresh } = await call("announce.list");
      if (!isCurrent()) return;
      items.splice(0, items.length, ...fresh);
      const cur = fresh.find((a) => a.id === keep);
      if (cur) ann = structuredClone(cur);
      drawEditor();
      drawList();
    }

    function drawList() {
      const draft = can(me.role, "draft");
      put(listCard, h("div", { class: "card-head" }, h("h2", {}, "Announcements"), h("span", { class: "small muted" }, "Only the newest live one shows on Today")),
        table([
          { label: "Announcement", class: "strong", cell: (a) => h("div", { class: "stack", style: { gap: "2px" } }, h("span", {}, a.title?.en || a.title?.ar || a.title?.es || "Untitled"), h("span", { class: "small muted" }, a.body?.en?.slice(0, 80) ?? "")) },
          { label: "Window", cell: (a) => windowLabel(a) },
          { label: "Who", cell: (a) => targetLabel(a.targeting) },
          { label: "Status", cell: (a) => statusChip(a.status) },
          { label: "", end: true, cell: (a) => h("div", { class: "pills", style: { justifyContent: "flex-end" } },
            h("button", { type: "button", class: "btn small", on: { click: (e) => { e.stopPropagation(); ann = structuredClone(a); serverWarns = []; errs = []; drawEditor(); editor.scrollIntoView({ behavior: "smooth", block: "start" }); } } }, "Edit"),
            publisher && a.status !== "published" && a.status !== "archived" ? h("button", { type: "button", class: "btn small publish", on: { click: (e) => { e.stopPropagation(); act("announce.publish", a, "published"); } } }, "Publish") : null,
            draft && a.status !== "archived" ? h("button", { type: "button", class: "btn small", on: { click: (e) => { e.stopPropagation(); act("announce.archive", a, "archived"); } } }, "Archive") : null) },
        ], items, { empty: empty("No announcements yet", "The card on Today stays hidden until one is published.") }));
    }

    async function act(action, a, done) {
      if (done === "published" && !(await confirmDialog({ title: "Publish this announcement?", body: `“${a.title?.en || "Untitled"}” shows on Today from ${windowLabel(a)} for ${targetLabel(a.targeting).toLowerCase()}.`, confirm: "Publish" }))) return;
      try {
        await call(action, { id: a.id });
        toast(`Announcement ${done}`);
        refresh();
      } catch {
        toast(`Couldn’t mark it ${done}`, "bad");
      }
    }

    drawEditor();
    drawList();
  }

  // ---- Push campaigns
  async function push() {
    const data = await call("push.list");
    if (!isCurrent()) return;
    const draft = can(me.role, "draft");
    let c = blank();
    let note = null;
    let clash = null;
    const editor = h("section", { class: "card" });
    const previewCard = h("section", { class: "card" });
    const voice = voiceCard(() => voiceIssuesT3(c.body).concat(voiceIssuesT3(c.title)));
    const listCard = h("section", { class: "card" });
    put(body,
      data.configured ? null : h("div", { class: "banner warn", role: "status" }, h("div", {}, h("b", {}, "Push isn’t set up yet"), h("div", { class: "small" }, "Connect Firebase Cloud Messaging and APNs to send campaigns. In-app announcements still work."))),
      listCard,
      h("div", { class: "row" }, h("div", { class: "grow stack", style: { gap: "16px" } }, editor), h("div", { class: "side-col" }, previewCard, voice)));

    function blank() {
      const d = new Date(Date.now() + 2 * 86400000);
      return { id: null, title: T3(), body: T3(), send_at_local: `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T09:30`, targeting: {}, status: "draft" };
    }

    function drawList() {
      put(listCard,
        h("div", { class: "card-head" }, h("h2", {}, "Push campaigns"), h("span", { class: "small muted" }, `One a week · quiet hours 22:00–08:00 local · device tokens only · ${fmtInt(data.tokens)} token${data.tokens === 1 ? "" : "s"}`)),
        table([
          { label: "Message", class: "strong", cell: (p) => h("div", { class: "stack", style: { gap: "2px" } }, h("span", {}, p.title?.en || "Untitled"), h("span", { class: "small muted" }, p.body?.en ?? "")) },
          { label: "Send (local)", cell: (p) => localLabel(p.send_at_local) },
          { label: "Who", cell: (p) => targetLabel(p.targeting) },
          { label: "Status", cell: (p) => statusChip(p.status) },
          { label: "Sent", end: true, cell: (p) => (p.status === "sent" ? fmtInt(p.sent_count) : "—") },
        ], data.items, { onRow: (p) => { c = structuredClone(p); note = null; clash = null; drawEditor(); }, selected: (p) => p.id === c.id, empty: empty("No push campaigns", "Meal, water and workout reminders stay on the phone and aren’t listed here.") }));
    }

    function drawEditor() {
      const locked = c.status === "sent" || c.status === "cancelled";
      const title = langField("Title", c.title, { max: 80, onChange: (v) => { c.title = v; voice.refresh(); drawPreview(); } });
      const bodyF = langField("Body", c.body, { multiline: true, max: 500, onChange: (v) => { c.body = v; voice.refresh(); drawPreview(); } });
      const hint = h("span", { class: "small muted" });
      const when = h("input", { class: "input", type: "datetime-local", value: c.send_at_local ?? "", "aria-label": "Send at (local time)", disabled: locked });
      const showHint = () => { hint.textContent = quietNote(when.value) ?? "Sent at this time in each phone’s own time zone."; };
      when.addEventListener("input", () => { c.send_at_local = when.value; note = null; showHint(); });
      showHint();
      const sel = (label, key, opts) => {
        const s = h("select", { class: "input", "aria-label": label, disabled: locked }, opts.map(([v, t]) => h("option", { value: v, selected: (c.targeting?.[key] ?? "") === v }, t)));
        s.addEventListener("change", () => { c.targeting ??= {}; if (s.value) c.targeting[key] = s.value; else delete c.targeting[key]; });
        return h("label", { class: "field" }, h("span", {}, label), s);
      };
      const taken = weekTakenBy(data.items, c.send_at_local, c.id);
      put(editor,
        h("div", { class: "card-head" }, h("h2", {}, c.id ? (locked ? "Campaign" : "Edit campaign") : "New campaign"), c.id ? statusChip(c.status) : chip("Not saved", "flat")),
        clash ? clashCard() : null,
        note ? h("div", { class: "banner info", role: "status" }, h("div", {}, h("b", {}, `Moved to 08:00 · ${localLabel(c.send_at_local)}`), h("div", { class: "small" }, note))) : null,
        title, bodyF,
        h("div", { class: "form" },
          h("label", { class: "field" }, h("span", {}, "Send (local time)"), when, hint),
          sel("Platform", "platform", [["", "All platforms"], ["ios", "iOS"], ["android", "Android"]]),
          sel("Language", "locale", [["", "All languages"], ["en", "English"], ["ar", "Arabic"], ["es", "Spanish"]])),
        taken && !clash ? h("span", { class: "small", style: { color: "var(--warn)" } }, `“${taken.title?.en}” already holds that week (${localLabel(taken.send_at_local)}). Scheduling will offer the next free week.`) : null,
        h("div", { class: "pills", style: { justifyContent: "flex-end", alignItems: "center" } },
          c.id ? h("button", { type: "button", class: "btn small", on: { click: () => { c = blank(); note = null; clash = null; drawEditor(); drawList(); } } }, "New campaign") : null,
          c.status === "scheduled" && draft ? h("button", { type: "button", class: "btn small danger", on: { click: cancel } }, "Cancel send") : null,
          locked ? null : h("button", { type: "button", class: "btn small primary", disabled: !draft, on: { click: () => save() } }, "Save draft"),
          locked || c.status === "scheduled" ? null : publisher
            ? h("button", { type: "button", class: "btn small publish", disabled: !data.configured, title: data.configured ? null : "Push isn’t set up yet", on: { click: () => save(true) } }, "Schedule")
            : h("span", { class: "small muted" }, "Scheduling needs the Owner")));
      drawPreview();
    }

    /** EdgeMessaging A: the week is taken; offer the next free one. */
    function clashCard() {
      const t = clash.taken_by;
      return h("div", { class: "banner warn", role: "alert", style: { flexWrap: "wrap" } },
        h("div", {}, h("b", {}, "One campaign a week is already scheduled"),
          h("div", { class: "small" }, `“${t?.title?.en ?? "Another campaign"}” goes out ${t ? localLabel(t.send_at_local) : "that week"}. The next free slot is ${dayLabel(clash.next_free)}.`)),
        h("div", { class: "pills" },
          h("button", { type: "button", class: "btn small primary", on: { click: () => { c.send_at_local = onDate(clash.next_free, c.send_at_local); clash = null; save(true); } } }, `Schedule for ${dayLabel(clash.next_free)}`),
          h("button", { type: "button", class: "btn small", on: { click: () => { clash = null; drawEditor(); } } }, "Save as draft")));
    }

    function drawPreview() {
      const tx = (t) => t?.[lang]?.trim() || h("span", { class: "pmiss" }, UI[lang].missing);
      const card = h("div", { class: "pcard stack ppush", style: { gap: "4px" } },
        h("span", { class: "pline" }, `Gymco · ${localLabel(c.send_at_local)}`), h("span", { class: "ptitle" }, tx(c.title)), h("span", {}, tx(c.body)));
      put(previewCard, h("div", { class: "card-head" }, h("h2", {}, "Preview"), h("span", { class: "small muted" }, "On the lock screen")),
        langSeg(drawPreview), h("div", { lang, class: lang === "ar" ? "ar" : null, style: { display: "flex", justifyContent: "center" } }, phonePreview(card, { rtl: lang === "ar" })));
    }

    async function save(schedule = false) {
      try {
        const r = await call("push.save", { id: c.id ?? undefined, title: c.title, body: c.body, send_at_local: c.send_at_local, targeting: c.targeting ?? {} });
        c.id = r.id;
        if (r.moved) {
          c.send_at_local = r.send_at_local;
          note = "That time is inside quiet hours. Phones in each time zone get it at 08:00 their time instead.";
        }
        if (!schedule) {
          toast(r.moved ? "Draft saved · moved to 08:00" : "Draft saved");
          return reload();
        }
      } catch (e) {
        errsToast(e, "Couldn’t save the draft");
        return;
      }
      try {
        await call("push.schedule", { id: c.id });
        toast(`Scheduled for ${localLabel(c.send_at_local)}`);
        c.status = "scheduled";
        reload();
      } catch (e) {
        if (e instanceof ApiError && e.code === "week_taken") {
          clash = e.body;
          drawEditor();
        } else if (e instanceof ApiError && e.code === "not_configured") {
          data.configured = false;
          toast("Push isn’t set up yet · saved as a draft", "bad");
          reload();
        } else errsToast(e, "Couldn’t schedule it");
      }
    }

    const errsToast = (e, fallback) => toast(e instanceof ApiError && e.code === "invalid" ? (e.body?.errors?.[0]?.message ?? "Check the fields") : fallback, "bad");

    async function cancel() {
      if (!(await confirmDialog({ title: "Cancel this send?", body: "The campaign stays as cancelled; copy it into a new one to send later.", confirm: "Cancel send", danger: true }))) return;
      try {
        await call("push.cancel", { id: c.id });
      } catch (e) {
        return toast(errorText(e, "Couldn’t cancel the send. It's still scheduled."), "bad");
      }
      toast("Send cancelled");
      c.status = "cancelled";
      reload();
    }

    async function reload() {
      let fresh;
      try {
        fresh = await call("push.list");
      } catch (e) {
        if (isCurrent()) toast(errorText(e, "Saved, but the list didn’t refresh. Reload the page."), "bad");
        return;
      }
      if (!isCurrent()) return;
      Object.assign(data, fresh);
      const cur = data.items.find((p) => p.id === c.id);
      if (cur) c = { ...structuredClone(cur), send_at_local: c.send_at_local ?? cur.send_at_local };
      drawList();
      drawEditor();
    }

    drawList();
    drawEditor();
  }

  // ---- Email templates
  async function emails() {
    let tpl = null;
    try {
      tpl = (await call("tickets.templates")).templates ?? null;
    } catch {
      tpl = null;
    }
    if (!isCurrent()) return;
    const authUrl = "https://supabase.com/dashboard/project/vncadogzpeoawikgafaj/auth/templates";
    const list = h("div", { class: "stack", style: { gap: "12px" } });
    const drawTpl = () => put(list, tpl
      ? Object.entries(tpl).map(([k, t]) => h("div", { class: "well stack", style: { gap: "6px" } },
          h("div", { class: "card-head" }, h("span", { class: "strong" }, TEMPLATE_LABEL[k] ?? k), h("span", { class: "small muted mono" }, k)),
          h("p", { class: "small", dir: lang === "ar" ? "rtl" : "ltr", lang, style: { margin: "0", whiteSpace: "pre-wrap" } }, t?.[lang]?.trim() || `Not written in ${LANG_NAME[lang]} yet`)))
      : h("span", { class: "small muted" }, "Reply templates need the Support role to view."));
    const draw = () => {
      put(body,
        h("div", { class: "grid two" },
          h("section", { class: "card" },
            h("div", { class: "card-head" }, h("h2", {}, "Sign-in and account emails"), chip("Supabase Auth", "flat")),
            h("p", { class: "muted", style: { margin: "0" } }, "The sign-in code and the deletion confirmation are sent by Supabase Auth. Their wording per language is edited in the Auth email templates, not here."),
            h("div", { class: "pills" }, h("a", { class: "btn small", href: authUrl, target: "_blank", rel: "noopener" }, "Open Auth templates", icon("ext", 16)))),
          h("section", { class: "card" },
            h("div", { class: "card-head" }, h("h2", {}, "Support replies"), chip("Read only", "flat")),
            h("p", { class: "muted", style: { margin: "0" } }, "The reply templates the Support inbox offers. {email} is filled with the sender’s address. They live in code (supabase/functions/_shared/support_templates.ts) so changes are reviewed like any other."),
            langSeg(draw), list)));
      drawTpl();
    };
    draw();
  }

  drawTabs();
  await drawTab();
}
