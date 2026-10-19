// 06 Remote config: every switch and limit phones read, edited as one draft,
// reviewed as a diff and published as a new version with one-click rollback.
// Forms are built from the server's schema, so the bounds shown are the
// bounds enforced.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { fmtEur, relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import { checkField, countChanges, ruleSummary, setKey, targetLabel } from "../lib/config_form.js";
import { chip, confirmDialog, diffView, langField, pageHead, sheet, statusChip, table, toggleSwitch } from "../lib/ui.js";

const AI_KEYS = ["limits.ai_scans_per_day", "ai.daily_budget_eur"];
// What an older server that doesn't send `untargetable` refuses in rules.
const UNTARGETABLE = ["limits.ai_scans_per_day"];

export async function render(el, { call, toast, me }) {
  const owner = can(me.role, "owner_keys");
  const publisher = can(me.role, "publish");
  let data;
  let work;
  let spend = null;
  const errs = new Map();
  const serverErrs = new Map();

  async function load() {
    const [d, s] = await Promise.all([call("config.get"), call("stats", { range: 7 }).catch(() => null)]);
    data = d;
    spend = s?.cost_today ?? null;
    work = structuredClone(d.draft?.body ?? d.published?.body ?? d.base);
    serverErrs.clear();
    draw();
  }

  const live = () => data.published?.body ?? data.base;
  const get = (path) => path.split(".").reduce((o, k) => o?.[k], work);
  const specOf = (path) => {
    const [g, k] = path.split(".");
    return data.schema[g]?.[k];
  };
  const locked = (spec) => spec.owner && !owner;
  const errorCount = () => [...errs.values()].filter(Boolean).length + serverErrs.size;

  const head = h("div", { class: "card config-head" });
  const body = h("div", { class: "stack", style: { gap: "16px" } });
  el.append(pageHead("App", "config", "Remote", null, { emFirst: true }), head, body);

  function drawHead() {
    const draft = data.draft;
    const pubV = data.published?.version ?? 0;
    const changes = countChanges(live(), work);
    const n = errorCount();
    const review = draft?.status === "in_review";
    const title = draft ? `Draft v${draft.version}` : changes ? "Unsaved draft" : pubV ? `Published v${pubV}` : "Built-in defaults";
    const sub = `${changes} change${changes === 1 ? "" : "s"} from ${pubV ? `published v${pubV}` : "the built-in defaults"} · apps fetch on launch and every 6 h`;
    head.replaceChildren(
      h("div", { class: "stack", style: { gap: "4px", flex: "1 1 280px" } },
        h("div", { class: "row", style: { gap: "10px", alignItems: "center" } }, h("h2", {}, title), draft ? statusChip(draft.status) : null),
        h("span", { class: "small muted" }, sub),
        review ? h("span", { class: "small" }, `Sent by ${draft.submitted_by ?? draft.created_by}${publisher ? " · approve to publish, or send it back with a note." : ". You can keep editing; a new edit replaces this request."}`) : null),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small", disabled: !changes, on: { click: showDiff } }, "View diff"),
        draft ? h("button", { type: "button", class: "btn small", on: { click: discard } }, "Discard draft") : null,
        review && publisher ? h("button", { type: "button", class: "btn small", on: { click: sendBack } }, "Send back") : null,
        h("button", { type: "button", class: "btn small", disabled: !changes || n > 0, on: { click: () => saveAndReload("Draft saved") } }, "Save draft"),
        publisher
          ? h("button", { type: "button", class: "btn small publish", disabled: !changes || n > 0, on: { click: publish } }, n ? `Publish · fix ${n} error${n === 1 ? "" : "s"} first` : review ? "Approve & publish" : "Publish")
          : h("button", { type: "button", class: "btn small primary", disabled: (!changes && !draft) || n > 0 || review, on: { click: submit } }, review ? "Sent to the Owner" : "Send for review")));
  }

  function errLine(path) {
    const e = h("span", { class: "field-err", role: "alert" });
    const show = () => {
      const msg = errs.get(path) || serverErrs.get(path) || "";
      e.textContent = msg;
      e.hidden = !msg;
    };
    show();
    e.refresh = show;
    return e;
  }

  function onSet(path, value, errEl) {
    work = setKey(work, path, value);
    serverErrs.delete(path);
    errs.set(path, checkField(specOf(path), value, path));
    errEl?.refresh();
    drawHead();
  }

  /** One setting: a switch row, a number, a choice or a three-language text. */
  function field(path, extra) {
    const spec = specOf(path);
    const disabled = locked(spec);
    const value = get(path);
    const err = errLine(path);
    const label = h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } },
      h("span", { class: "strong" }, spec.label),
      h("span", { class: "small muted mono" }, path.split(".")[1]),
      spec.help ? h("span", { class: "small muted" }, spec.help) : null, extra ?? null);
    if (spec.kind === "bool") {
      return h("div", { class: "cfg-row" }, label, toggleSwitch(spec.label, value, (v) => toggled(path, v), { disabled }));
    }
    if (spec.kind === "text3") {
      return h("div", { class: "stack" }, langField(spec.label, value, { multiline: true, max: 240, onChange: (v) => onSet(path, v, err) }), err);
    }
    const input = spec.kind === "enum"
      ? h("select", { class: "input", disabled, "aria-label": spec.label }, spec.options.map((o) => h("option", { value: o, selected: o === value }, o)))
      : h("input", { class: "input num", type: "number", inputmode: "decimal", value: String(value), min: spec.min, max: spec.max, step: spec.kind === "int" ? "1" : "0.1", disabled, "aria-label": spec.label });
    input.addEventListener("input", () => onSet(path, spec.kind === "enum" ? input.value : input.value === "" ? NaN : Number(input.value), err));
    return h("div", { class: "cfg-row" }, label,
      h("div", { class: "stack", style: { gap: "4px", width: "190px", flex: "none" } }, input,
        spec.min != null ? h("span", { class: "small muted num" }, `${spec.min}–${spec.max}`) : null, err));
  }

  async function toggled(path, on) {
    if (path === "app_gate.maintenance_mode" && on) {
      const yes = await confirmDialog({
        title: "Show the resting screen to everyone?",
        body: "The diary keeps working offline on phones. Sync, backup, AI and sign-in stop until you turn this off. It takes effect when you publish.",
        confirm: "Turn on", danger: true,
      });
      if (!yes) return draw();
    }
    onSet(path, on);
    if (path === "app_gate.maintenance_mode") draw();
  }

  const card = (title, note, ...kids) => h("section", { class: "card" },
    h("div", { class: "card-head" }, h("h2", {}, title), note ? h("span", { class: "small muted" }, note) : null), ...kids);
  const keysOf = (g, skip = []) => Object.keys(data.schema[g]).map((k) => `${g}.${k}`).filter((p) => !skip.includes(p));

  function aiCard() {
    const budget = get("ai.daily_budget_eur");
    const pct = spend != null && budget > 0 ? Math.min(100, Math.round((spend / budget) * 100)) : spend != null ? 100 : null;
    const reached = pct != null && pct >= 100;
    const tone = pct == null ? "" : pct >= 100 ? "bad" : pct >= 80 ? "warn" : "";
    const ai = work.ai;
    return card("AI operations", "Photos and text are never stored",
      reached ? h("div", { class: "banner", role: "status" },
        h("div", {}, h("b", {}, "Photo logging is paused until 00:00 UTC"),
          h("div", { class: "small" }, `Spent ${fmtEur(spend)} of ${fmtEur(budget)} · Write and search still work`))) : null,
      ...AI_KEYS.map((p) => field(p)),
      pct != null ? h("div", { class: "stack", style: { gap: "6px" } },
        h("div", { class: "card-head" }, h("span", { class: "small muted" }, `Today’s spend · ${fmtEur(spend)}`), h("span", { class: "small num strong" }, `${pct}%`)),
        h("div", { class: `track ${tone}`, role: "img", "aria-label": `${pct}% of today's budget spent` }, h("i", { style: { width: `${pct}%` } }))) : null,
      h("div", { class: "rule" }),
      h("div", { class: "lock-note" }, icon("shield", 16),
        h("span", {}, `food-photo · ${ai.model} · prompt v${ai.prompt_version}`,
          ai.rollout_percent ? ` · ${ai.rollout_percent}% of installs on ${ai.next_model} prompt v${ai.next_prompt_version}` : "")),
      ...keysOf("ai", ["ai.daily_budget_eur"]).map((p) => field(p)),
      h("span", { class: "small muted" }, "App-wide kill switches photo_log, eating_out and dictate are in Features."));
  }

  function rulesCard() {
    const rules = work.rules ?? [];
    const skip = data.untargetable ?? UNTARGETABLE;
    const targetable = Object.entries(data.schema).flatMap(([g, ks]) => Object.entries(ks).filter(([, s]) => s.kind !== "text3" && (!s.owner || owner)).map(([k]) => `${g}.${k}`)).filter((p) => !skip.includes(p));
    const key = h("select", { class: "input", "aria-label": "Setting" }, targetable.map((p) => h("option", { value: p }, p)));
    const valueSlot = h("div", { class: "field" });
    let valueInput;
    const drawValue = () => {
      const spec = specOf(key.value);
      valueInput = spec.kind === "bool"
        ? h("select", { class: "input", "aria-label": "Value" }, h("option", { value: "true" }, "On"), h("option", { value: "false" }, "Off"))
        : spec.kind === "enum"
          ? h("select", { class: "input", "aria-label": "Value" }, spec.options.map((o) => h("option", { value: o }, o)))
          : h("input", { class: "input num", type: "number", value: String(get(key.value)), min: spec.min, max: spec.max, "aria-label": "Value" });
      valueSlot.replaceChildren(h("span", {}, "Value"), valueInput);
    };
    key.addEventListener("change", drawValue);
    drawValue();
    const sel = (label, opts) => h("select", { class: "input", "aria-label": label }, opts.map(([v, t]) => h("option", { value: v }, t)));
    const platform = sel("Platform", [["", "Any platform"], ["ios", "iOS"], ["android", "Android"]]);
    const locale = sel("Language", [["", "Any language"], ["en", "English"], ["ar", "Arabic"], ["es", "Spanish"]]);
    const num = (label, max) => h("input", { class: "input num", type: "number", min: 0, max, placeholder: "Any", "aria-label": label });
    const minB = num("From build", 100000);
    const maxB = num("To build", 100000);
    const pct = num("Percent of installs", 100);
    const opt = (i) => (i.value === "" ? undefined : Number(i.value));
    const add = () => {
      const spec = specOf(key.value);
      const value = spec.kind === "bool" ? valueInput.value === "true" : spec.kind === "enum" ? valueInput.value : Number(valueInput.value);
      const msg = checkField(spec, value, key.value);
      if (msg) return toast(msg, "bad");
      const target = Object.fromEntries(Object.entries({ platform: platform.value || undefined, locale: locale.value || undefined, min_build: opt(minB), max_build: opt(maxB), percent: opt(pct) }).filter(([, v]) => v !== undefined));
      if (!Object.keys(target).length) return toast("Pick who it applies to; for everyone, change the setting itself", "bad");
      work = { ...work, rules: [...rules, { key: key.value, value, target }] };
      draw();
    };
    const remove = (i) => {
      work = { ...work, rules: rules.filter((_, j) => j !== i) };
      draw();
    };
    return card("Targeting", "Rules apply in order; a later rule wins",
      table([
        { label: "Setting", class: "mono", cell: (r) => r.key },
        { label: "Value", cell: (r) => (typeof r.value === "boolean" ? (r.value ? chip("On", "good") : chip("Off")) : String(r.value)) },
        { label: "Who", cell: (r) => targetLabel(r.target) },
        { label: "", end: true, cell: (r) => (locked(specOf(r.key) ?? {}) ? "" : h("button", { type: "button", class: "btn small", on: { click: () => remove(rules.indexOf(r)) } }, "Remove")) },
      ], rules, { empty: h("p", { class: "muted small" }, "Every device gets the same values. Add a rule to change one setting for a platform, language, build range or share of installs.") }),
      h("div", { class: "form" },
        h("label", { class: "field" }, h("span", {}, "Setting"), key), valueSlot,
        h("label", { class: "field" }, h("span", {}, "Platform"), platform),
        h("label", { class: "field" }, h("span", {}, "Language"), locale),
        h("label", { class: "field" }, h("span", {}, "From build"), minB),
        h("label", { class: "field" }, h("span", {}, "To build"), maxB),
        h("label", { class: "field" }, h("span", {}, "Percent"), pct),
        h("button", { type: "button", class: "btn", on: { click: add } }, icon("plus"), "Add rule")),
      h("span", { class: "small muted" }, "Percent uses a random install ID that never leaves the device."));
  }

  function historyCard() {
    return card("Versions", "Rollback publishes a copy as a new version",
      table([
        { label: "Version", class: "strong", cell: (r) => `v${r.version}` },
        { label: "Status", cell: (r) => statusChip(r.status) },
        { label: "By", cell: (r) => r.published_by ?? r.created_by },
        { label: "When", cell: (r) => relTime(r.published_at ?? r.created_at) },
        { label: "Note", cell: (r) => r.note ?? "" },
        { label: "", end: true, cell: (r) => (publisher && r.status === "archived" ? h("button", { type: "button", class: "btn small", on: { click: () => rollback(r) } }, "Roll back") : "") },
      ], data.history ?? [], { empty: h("p", { class: "muted small" }, "Nothing published yet. Phones use the built-in defaults shown here.") }));
  }

  function draw() {
    errs.clear();
    for (const [g, ks] of Object.entries(data.schema)) for (const k of Object.keys(ks)) errs.set(`${g}.${k}`, checkField(ks[k], work[g]?.[k], `${g}.${k}`));
    const ownerNote = owner ? "Owner only · hard bounds in schema" : "Owner only · you can see these but not change them";
    body.replaceChildren(
      h("div", { class: "grid two" },
        card("Features", "Off hides it in the app", ...keysOf("features").map((p) => field(p, chip(ruleSummary(work.rules, p), ruleSummary(work.rules, p) === "All" ? "flat" : "brand")))),
        card("Safety", ownerNote, ...keysOf("safety").map((p) => field(p)))),
      h("div", { class: "grid two" },
        aiCard(),
        card("Limits, water & streak", null, ...keysOf("limits", AI_KEYS).map((p) => field(p)), h("div", { class: "rule" }), ...keysOf("water").map((p) => field(p)), h("div", { class: "rule" }), ...keysOf("streak").map((p) => field(p)))),
      h("div", { class: "grid two" },
        card("App gate", ownerNote, ...keysOf("app_gate", ["app_gate.maintenance_message"]).map((p) => field(p)),
          field("app_gate.maintenance_message")),
        card("Plans", ownerNote, ...keysOf("plans").map((p) => field(p)))),
      rulesCard(),
      historyCard());
    drawHead();
  }

  function showDiff() {
    sheet("Changes from what phones have", h("div", { class: "stack" }, diffView(live(), work)));
  }

  async function save(note) {
    try {
      await call("config.save_draft", { body: work, note: note ?? null });
      return true;
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        serverErrs.clear();
        for (const x of e.body?.errors ?? []) serverErrs.set(x.key.replace(/\.(en|ar|es)$/, ""), x.message);
        draw();
        toast("Fix the highlighted values first", "bad");
      } else if (e instanceof ApiError && e.code === "owner_keys") {
        toast(`Only the Owner can change ${e.body.keys.join(", ")}`, "bad");
      } else toast("Couldn’t save the draft", "bad");
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

  async function sendBack() {
    const note = h("textarea", { class: "input", "aria-label": "Note to the editor" });
    const ok = await confirmDialog({ title: "Send this back?", body: "The editor sees your note and the draft stays theirs to change.", confirm: "Send back", field: h("label", { class: "field" }, h("span", {}, "Note to editor (needed)"), note) });
    if (!ok) return;
    if (!note.value.trim()) return toast("Add a note so they know what to change", "bad");
    if (await save(`Sent back: ${note.value.trim()}`)) {
      toast("Sent back to the editor");
      await load();
    }
  }

  async function discard() {
    if (!(await confirmDialog({ title: "Discard this draft?", body: "Phones keep what is published. The draft is archived and logged.", confirm: "Discard", danger: true }))) return;
    try {
      await call("config.discard");
    } catch (e) {
      return toast(errorText(e, "Couldn’t discard the draft"), "bad");
    }
    toast("Draft discarded");
    await load();
  }

  async function publish() {
    const next = (data.history?.[0]?.version ?? 0) + (data.draft ? 0 : 1);
    const ok = await confirmDialog({
      title: `Publish v${next} to Production?`,
      body: h("div", { class: "stack" }, diffView(live(), work),
        h("span", { class: "small muted" }, `Phones pick this up on next launch or within 6 h.${data.published ? ` v${data.published.version} stays available for rollback.` : ""}`)),
      confirm: "Publish",
    });
    if (!ok) return;
    const unsaved = countChanges(data.draft?.body ?? live(), work) > 0 || !data.draft;
    if (unsaved && !(await save())) return;
    try {
      const fresh = await call("config.get");
      await call("config.publish", { version: fresh.draft.version });
      toast(`v${fresh.draft.version} published`);
    } catch (e) {
      toast(e instanceof ApiError && e.code === "invalid" ? "The draft has errors" : errorText(e, "Couldn’t publish"), "bad");
    }
    await load();
  }

  async function rollback(r) {
    const ok = await confirmDialog({
      title: `Roll back to v${r.version}?`,
      body: `v${data.published?.version ?? "?"} becomes archived and v${r.version}'s values go out as a new version.${data.draft ? ` Your open draft v${data.draft.version} is archived first.` : ""} This is logged and can be undone by rolling forward.`,
      confirm: "Roll back", danger: true,
    });
    if (!ok) return;
    try {
      await call("config.rollback", { to_version: r.version });
    } catch (e) {
      return toast(errorText(e, "Couldn’t roll back"), "bad");
    }
    toast(`Rolled back to v${r.version}`);
    await load();
  }

  await load();
}
