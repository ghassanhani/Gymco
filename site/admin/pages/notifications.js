// Notifications: every reminder the app schedules on the phone, switched
// on or off for everyone, the daily cap and quiet hours, and the words in
// each language. Saved into the remote config (draft, review, publish),
// so phones pick changes up on next launch or within 6 h.

import { ApiError } from "../lib/api.js";
import { h } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { countChanges } from "../lib/config_form.js";
import { NOTE_VARS, noteErrors, noteGroups, notePreview, setNoteText } from "../lib/notes_form.js";
import { NOTES } from "../lib/notes_catalog.js";
import { can } from "../lib/roles.js";
import { chip, confirmDialog, diffView, pageHead, sheet, statusChip, toggleSwitch } from "../lib/ui.js";

const LANG_TABS = [["en", "English"], ["ar", "عربي"], ["ar_f", "عربي · للنساء"], ["es", "Español"]];

export async function render(el, { call, toast, me }) {
  const publisher = can(me.role, "publish");
  let data;
  let work;

  async function load() {
    data = await call("config.get");
    work = structuredClone(data.draft?.body ?? data.published?.body ?? data.base);
    work.notifications = { ...(data.base?.notifications ?? {}), ...(work.notifications ?? {}) };
    draw();
  }

  const live = () => data.published?.body ?? data.base;
  const notes = () => work.notifications;
  const text = () => notes().text ?? {};

  const head = h("div", { class: "card config-head" });
  const body = h("div", { class: "stack", style: { gap: "16px" } });
  el.append(pageHead("App", "Notifications", null), head, body);

  function drawHead() {
    const draft = data.draft;
    const pubV = data.published?.version ?? 0;
    const changes = countChanges(live(), work);
    const bad = noteErrors(work.notifications).length;
    const review = draft?.status === "in_review";
    head.replaceChildren(
      h("div", { class: "stack", style: { gap: "4px", flex: "1 1 280px" } },
        h("div", { class: "row", style: { gap: "10px", alignItems: "center" } },
          h("h2", {}, draft ? `Draft v${draft.version}` : changes ? "Unsaved changes" : pubV ? `Published v${pubV}` : "Built-in defaults"),
          draft ? statusChip(draft.status) : null),
        h("span", { class: "small muted" }, `${changes} change${changes === 1 ? "" : "s"} · saved with the remote config · phones pick it up on launch or within 6 h · scheduled on each phone, nothing is sent from the server`)),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small", disabled: !changes, on: { click: () => sheet("Changes from what phones have", h("div", { class: "stack" }, diffView(live(), work))) } }, "View diff"),
        h("button", { type: "button", class: "btn small", disabled: !changes || bad > 0, on: { click: () => saveAndReload("Draft saved") } }, "Save draft"),
        publisher
          ? h("button", { type: "button", class: "btn small publish", disabled: !changes || bad > 0, on: { click: publish } }, bad ? `Fix ${bad} first` : review ? "Approve & publish" : "Publish")
          : h("button", { type: "button", class: "btn small primary", disabled: (!changes && !draft) || bad > 0 || review, on: { click: submit } }, review ? "Sent to the Owner" : "Send for review")));
  }

  function set(key, value) {
    work = { ...work, notifications: { ...notes(), [key]: value } };
    drawHead();
  }

  function hourInput(key, label) {
    const spec = data.schema.notifications?.[key] ?? { min: 0, max: 23 };
    const input = h("input", { class: "input num", type: "number", min: spec.min, max: spec.max, step: "1", value: String(notes()[key]), "aria-label": label });
    input.addEventListener("input", () => {
      const v = Number(input.value);
      if (Number.isInteger(v) && v >= spec.min && v <= spec.max) set(key, v);
    });
    return h("div", { class: "cfg-row" },
      h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, label), spec.help ? h("span", { class: "small muted" }, spec.help) : null),
      h("div", { style: { width: "120px", flex: "none" } }, input));
  }

  function rulesCard() {
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "Rules"), h("span", { class: "small muted" }, "The same on every phone")),
      hourInput("daily_cap", "Most in a day"),
      hourInput("quiet_from", "Quiet hours start (hour)"),
      hourInput("quiet_to", "Quiet hours end (hour)"),
      h("ul", { class: "small muted", style: { margin: "0", paddingInlineStart: "18px" } },
        h("li", {}, "When more are due, the most valuable win: streak, workout, meals, then water."),
        h("li", {}, "Nothing for something already done; a reminder ignored 5 days running goes every other day."),
        h("li", {}, "In the Gulf, nothing during Friday prayer (11:30–13:30): it goes at 13:30."),
        h("li", {}, "People can change their own quiet hours and turn any reminder off under Me → Reminders.")));
  }

  function row(n) {
    const on = notes()[n.kind] !== false;
    const edited = Object.values(text()[n.kind] ?? {}).some((p) => Object.values(p ?? {}).some((s) => String(s).trim()));
    const preview = notePreview(n, text()[n.kind], "en");
    return h("div", { class: "cfg-row note-row" },
      h("button", { type: "button", class: "note-open", on: { click: () => edit(n) }, "aria-label": `Edit ${n.label}` },
        h("div", { class: "stack", style: { gap: "2px", minWidth: "0", textAlign: "start" } },
          h("div", { class: "row", style: { gap: "8px", alignItems: "center" } }, h("span", { class: "strong" }, n.label), edited ? chip("Edited", "brand") : null),
          h("span", { class: "small muted" }, n.when),
          h("span", { class: "small" }, `${preview.title} · ${preview.body}`))),
      toggleSwitch(n.label, on, (v) => { set(n.kind, v); draw(); }));
  }

  function edit(n) {
    let cur = "en";
    let draftText = structuredClone(text()[n.kind] ?? {});
    const tabs = h("div", { class: "langtabs", role: "tablist", "aria-label": "Language" });
    const title = h("input", { class: "input", maxlength: 60, "aria-label": "Title" });
    const bodyIn = h("textarea", { class: "input", maxlength: 160, rows: 3, "aria-label": "Body" });
    const prev = h("div", { class: "note-preview" });
    const err = h("span", { class: "field-err", role: "alert" });
    const vars = h("div", { class: "pills" });

    function draw1() {
      tabs.replaceChildren(...LANG_TABS.map(([k, t]) =>
        h("button", { type: "button", role: "tab", "aria-selected": String(k === cur), on: { click: () => { cur = k; draw1(); } } }, t)));
      for (const [input, part] of [[title, "title"], [bodyIn, "body"]]) {
        input.value = draftText[part]?.[cur] ?? "";
        input.placeholder = n[part][cur];
        input.dir = cur.startsWith("ar") ? "rtl" : "ltr";
      }
      const p = notePreview(n, draftText, cur);
      prev.dir = cur.startsWith("ar") ? "rtl" : "ltr";
      prev.replaceChildren(h("span", { class: "note-app small muted" }, "GYMCO · now"), h("strong", {}, p.title), h("span", {}, p.body));
      const e = noteErrors({ text: { [n.kind]: draftText } }, n.kind);
      err.textContent = e[0] ?? "";
      err.hidden = !e.length;
    }
    for (const [input, part] of [[title, "title"], [bodyIn, "body"]]) {
      input.addEventListener("input", () => {
        draftText = setNoteText(draftText, part, cur, input.value);
        draw1();
      });
    }
    const varList = (NOTE_VARS[n.kind] ?? []);
    vars.replaceChildren(...(varList.length ? varList.map((v) => chip(`{${v}}`, "flat")) : [h("span", { class: "small muted" }, "No placeholders")]));
    draw1();

    const { close } = sheet(n.label,
      h("div", { class: "stack" },
        h("span", { class: "small muted" }, n.when),
        tabs,
        h("label", { class: "field" }, h("span", {}, "Title"), title),
        h("label", { class: "field" }, h("span", {}, "Body"), bodyIn),
        err,
        h("div", { class: "stack", style: { gap: "6px" } }, h("span", { class: "small muted" }, "Placeholders filled in on the phone"), vars),
        h("span", { class: "small muted" }, "Empty fields keep the app’s own words (shown faintly). The feminine Arabic falls back to the Arabic."),
        prev),
      [
        h("button", { type: "button", class: "btn", on: { click: () => { draftText = {}; draw1(); } } }, "Use the app’s words"),
        h("button", { type: "button", class: "btn primary", on: { click: () => {
          if (noteErrors({ text: { [n.kind]: draftText } }, n.kind).length) return toast("Fix the text first", "bad");
          set("text", { ...text(), [n.kind]: draftText });
          if (!Object.keys(draftText).length) {
            const t = { ...text() };
            delete t[n.kind];
            set("text", t);
          }
          close();
          draw();
        } } }, "Done"),
      ]);
  }

  function draw() {
    body.replaceChildren(
      rulesCard(),
      ...noteGroups(NOTES).map(([group, list]) =>
        h("section", { class: "card" },
          h("div", { class: "card-head" }, h("h2", {}, group), h("span", { class: "small muted" }, `${list.filter((n) => notes()[n.kind] !== false).length} of ${list.length} on`)),
          ...list.map(row))),
      h("section", { class: "card tight" },
        h("span", { class: "small muted" }, "Not here yet: Ramadan reminders (suhoor, iftar, water window) and the ‘What’s new’ push from the server, which needs Firebase Messaging in the app.")));
    drawHead();
  }

  async function save() {
    try {
      await call("config.save_draft", { body: work, note: "Notifications" });
      return true;
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") toast(e.body?.errors?.[0]?.message ?? "Fix the highlighted values first", "bad");
      else toast(errorText(e, "Couldn’t save the draft"), "bad");
      return false;
    }
  }

  async function saveAndReload(msg) {
    if (await save()) {
      toast(msg);
      await load();
    }
  }

  async function submit() {
    if (countChanges(data.draft?.body ?? live(), work) && !(await save())) return;
    try {
      await call("config.submit");
    } catch (e) {
      return toast(errorText(e, "Couldn’t send it for review"), "bad");
    }
    toast("Sent to the Owner for review");
    await load();
  }

  async function publish() {
    const ok = await confirmDialog({
      title: "Publish to every phone?",
      body: h("div", { class: "stack" }, diffView(live(), work), h("span", { class: "small muted" }, "Phones pick this up on next launch or within 6 h.")),
      confirm: "Publish",
    });
    if (!ok) return;
    if ((countChanges(data.draft?.body ?? live(), work) > 0 || !data.draft) && !(await save())) return;
    try {
      const fresh = await call("config.get");
      await call("config.publish", { version: fresh.draft.version });
      toast(`v${fresh.draft.version} published`);
    } catch (e) {
      toast(errorText(e, "Couldn’t publish"), "bad");
    }
    await load();
  }

  await load();
}
