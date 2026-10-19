// 07 Content library: eight packs phones download on top of the built-in
// content. Each is edited as a draft, checked against the pack contract,
// previewed in EN / AR / ES and published as a new version with rollback.
// One field description per kind (lib/packs_form.js) drives every editor.

import { ApiError } from "../lib/api.js";
import { clear, h, icon } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import {
  AWARD_RULE, blankItem, checkBody, checkLines, COPY_KEYS, countItemChanges, FIELDS, getList, itemIndex, itemSub, itemTitle,
  keyedBody, KINDS, kindOf, LANG_NAME, matchUnits, mergeChecks, METRIC_LABEL, setList, weeklySets,
} from "../lib/packs_form.js";
import { chip, confirmDialog, diffView, empty, LANGS, langField, pageHead, phonePreview, sheet, statusChip, table } from "../lib/ui.js";

// A few words of the phone's own UI, so the preview reads as the app would.
const UI = {
  en: { kcal: "kcal", per100: "per 100 g", p: "Protein", c: "Carbs", f: "Fat", start: "Start", rest: "Rest", sets: "sets", s: "s", g: "g", main: "Main", side: "Side", times: "workouts", missing: "Missing English" },
  ar: { kcal: "سعرة", per100: "لكل 100 غ", p: "بروتين", c: "كربوهيدرات", f: "دهون", start: "ابدأ", rest: "الراحة", sets: "مجموعات", s: "ث", g: "غ", main: "طبق رئيسي", side: "طبق جانبي", times: "تمارين", missing: "ينقص النص العربي" },
  es: { kcal: "kcal", per100: "por 100 g", p: "Proteína", c: "Carbohidratos", f: "Grasa", start: "Empezar", rest: "Descanso", sets: "series", s: "s", g: "g", main: "Principal", side: "Acompañamiento", times: "entrenos", missing: "Falta el español" },
};
const MUSCLE = {
  ar: { chest: "الصدر", shoulders: "الأكتاف", triceps: "الترايسبس", biceps: "البايسبس", forearms: "الساعد", lats: "الظهر العريض", "middle back": "منتصف الظهر", "lower back": "أسفل الظهر", traps: "الترابيس", abdominals: "البطن", quadriceps: "الفخذ الأمامي", hamstrings: "الفخذ الخلفي", glutes: "الأرداف", calves: "السمانة", adductors: "الفخذ الداخلي", abductors: "الفخذ الخارجي", neck: "الرقبة" },
  es: { chest: "Pecho", shoulders: "Hombros", triceps: "Tríceps", biceps: "Bíceps", forearms: "Antebrazos", lats: "Dorsales", "middle back": "Espalda media", "lower back": "Espalda baja", traps: "Trapecios", abdominals: "Abdominales", quadriceps: "Cuádriceps", hamstrings: "Isquiotibiales", glutes: "Glúteos", calves: "Gemelos", adductors: "Aductores", abductors: "Abductores", neck: "Cuello" },
};
// replaceChildren would print a null as "null"; this skips them.
const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const muscleName = (m, l) => MUSCLE[l]?.[m] ?? (m ? m[0].toUpperCase() + m.slice(1) : "");

export async function render(el, { call, toast, me, params, isCurrent }) {
  const publisher = can(me.role, "publish");
  const kind = kindOf(params.kind).id;
  const K = kindOf(kind);
  let data;
  let work;
  let client = { errors: [], warnings: [] };
  let server = { errors: [], warnings: [] };
  let saveErrs = [];
  let checkState = "idle";
  let selected = 0;
  let copyKey = COPY_KEYS[0].key;
  let lang = "en";
  let filter = params.q ?? "";
  let timer;
  const errLines = new Set();
  const previews = new Set();

  const live = () => data.published?.body ?? data.base;
  const list = () => getList(kind, work);
  const errors = () => mergeChecks(client.errors, [...server.errors, ...saveErrs]);
  const warnings = () => mergeChecks(client.warnings, server.warnings);
  const changes = () => countItemChanges(kind, live(), work);
  const unsaved = () => countItemChanges(kind, data.draft?.body ?? live(), work) > 0;
  const summaryOf = (k) => (Array.isArray(data.summary) ? data.summary.find((s) => s.kind === k) : data.summary?.[k]) ?? null;

  const pills = h("div", { class: "pills", role: "group", "aria-label": "Library" });
  const head = h("div", { class: "card config-head" });
  const main = h("div", { class: "stack", style: { gap: "16px" } });
  const checksCard = h("section", { class: "card" });
  const previewCard = h("section", { class: "card" });
  const toolCard = h("section", { class: "card" });
  const historyCard = h("section", { class: "card" });
  el.append(pageHead("App", "Content", "library"), pills, head,
    h("div", { class: "row" }, h("div", { class: "grow stack", style: { gap: "16px" } }, main),
      h("div", { class: "side-col" }, checksCard, previewCard, toolCard)),
    historyCard);

  async function load() {
    data = await call("packs.get", { kind });
    if (!isCurrent()) return;
    work = structuredClone(data.draft?.body ?? data.published?.body ?? data.base ?? {});
    if (kind === "copy") work.overrides ??= {};
    else work[K.list] ??= [];
    saveErrs = [];
    server = { errors: [], warnings: data.warnings ?? [] };
    selected = Math.min(selected, Math.max(0, list().length - 1));
    client = checkBody(kind, work);
    drawAll();
    runCheck();
  }

  // ---- server check, debounced after edits
  function scheduleCheck() {
    clearTimeout(timer);
    timer = setTimeout(runCheck, 600);
  }
  async function runCheck() {
    checkState = "checking";
    drawChecks();
    try {
      const r = await call("packs.check", { kind, body: work });
      if (!isCurrent()) return;
      server = { errors: r.errors ?? [], warnings: r.warnings ?? [] };
      checkState = "done";
    } catch {
      checkState = "failed";
    }
    if (!isCurrent()) return;
    refresh();
  }

  /** After any edit at [path]: recheck locally, drop stale server findings there, redraw. */
  function changed(path) {
    client = checkBody(kind, work);
    const stale = (e) => path && (e.key === path || e.key.startsWith(`${path}.`));
    server = { errors: server.errors.filter((e) => !stale(e)), warnings: server.warnings.filter((e) => !stale(e)) };
    saveErrs = saveErrs.filter((e) => !stale(e));
    refresh();
    scheduleCheck();
  }

  function refresh() {
    for (const e of errLines) e.isConnected ? e.refresh() : errLines.delete(e);
    for (const p of previews) p.isConnected ? p.refresh() : previews.delete(p);
    drawHead();
    drawPills();
    drawChecks();
    drawMain(true);
    drawTool();
  }

  function drawAll() {
    drawPills();
    drawHead();
    drawMain();
    drawChecks();
    drawPreview();
    drawTool();
    drawHistory();
  }

  // ---- library pills, with each kind's summary
  function drawPills() {
    clear(pills).append(...KINDS.map((k) => {
      const s = summaryOf(k.id);
      const tip = s ? `${s.published_version ? `Published v${s.published_version}` : "Nothing published"}${s.draft_status ? ` · ${s.draft_status === "in_review" ? "in review" : "draft"}` : ""} · ${s.items} item${s.items === 1 ? "" : "s"}` : null;
      return h("button", { type: "button", class: "pill pack-pill", "aria-pressed": String(k.id === kind), title: tip, on: { click: () => go(k.id) } },
        k.label,
        s ? h("span", { class: "pill-n num" }, String(k.id === kind ? (kind === "copy" ? Object.keys(work.overrides).length : list().length) : s.items)) : null,
        s?.draft_status ? h("span", { class: `pill-dot ${s.draft_status === "in_review" ? "warn" : ""}`, "aria-label": s.draft_status === "in_review" ? "In review" : "Draft" }) : null);
    }));
  }

  async function go(id) {
    if (id === kind) return;
    if (unsaved() && !(await confirmDialog({ title: "Leave without saving?", body: `Your changes to the ${K.label} pack aren’t saved as a draft yet.`, confirm: "Leave", danger: true }))) return;
    location.hash = `#/content?kind=${id}`;
  }

  // ---- head: version, status and the draft → review → publish buttons
  function drawHead() {
    const draft = data.draft;
    const pubV = data.published?.version ?? 0;
    const n = changes();
    const blockers = errors().length;
    const review = draft?.status === "in_review";
    const count = kind === "copy" ? Object.keys(work.overrides).length : list().length;
    const title = `${K.label} pack · ${draft ? `draft v${draft.version}` : unsaved() ? "unsaved draft" : pubV ? `published v${pubV}` : "built-in only"}`;
    const sub = `${n} change${n === 1 ? "" : "s"} from ${pubV ? `published v${pubV}` : "the built-in content"} · ${count} ${kind === "copy" ? `override${count === 1 ? "" : "s"}` : `item${count === 1 ? "" : "s"}`} · phones fetch a pack when its version changes`;
    put(head, 
      h("div", { class: "stack", style: { gap: "4px", flex: "1 1 280px" } },
        h("div", { class: "row", style: { gap: "10px", alignItems: "center" } }, h("h2", {}, title), draft ? statusChip(draft.status) : null),
        h("span", { class: "small muted" }, sub),
        review ? h("span", { class: "small" }, `Sent by ${draft.submitted_by ?? draft.created_by}${publisher ? " · approve to publish, or send it back with a note." : ". You can keep editing; saving again takes it back to draft."}`) : null),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small", disabled: !n, on: { click: showDiff } }, "View diff"),
        draft ? h("button", { type: "button", class: "btn small", on: { click: discard } }, "Discard draft") : null,
        review && publisher ? h("button", { type: "button", class: "btn small", on: { click: sendBack } }, "Send back") : null,
        h("button", { type: "button", class: "btn small", disabled: !unsaved(), on: { click: () => saveAndReload("Draft saved") } }, "Save draft"),
        publisher
          ? publishButton(blockers)
          : h("button", { type: "button", class: "btn small primary", disabled: (!unsaved() && !draft) || blockers > 0 || (review && !unsaved()), on: { click: submit } }, review && !unsaved() ? "Sent to the Owner" : blockers ? `Send for review · ${blockers} to fix` : "Send for review")));
  }

  const publishButton = (blockers) => h("button", {
    type: "button", class: "btn small publish", disabled: (!changes() && !data.draft) || blockers > 0, on: { click: publish },
  }, blockers ? `Publish pack · ${blockers} blocker${blockers === 1 ? "" : "s"}` : data.draft?.status === "in_review" ? "Approve & publish" : "Publish pack");

  // ---- the item list (or, for copy, every text the app lets a pack change)
  const t3Fields = (FIELDS[kind] ?? []).filter((f) => f.type === "t3");
  const missingLangs = (it) => ["en", "ar", "es"].filter((l) => t3Fields.some((f) => !it?.[f.key]?.[l]?.trim()));
  const itemErrs = (i) => errors().filter((e) => itemIndex(e.key) === i);
  const itemWarns = (i) => warnings().filter((e) => itemIndex(e.key) === i);

  function drawMain(soft = false) {
    if (kind === "copy") {
      // Copy fields are typed into in place; only the first draw builds them.
      if (!soft) put(main, copyCard());
      return;
    }
    const all = list();
    const shown = all.map((it, i) => ({ it, i })).filter(({ it }) => !filter || `${itemTitle(kind, it)} ${it.id ?? ""} ${it.word ?? ""}`.toLowerCase().includes(filter.toLowerCase()));
    const search = h("input", { class: "input", type: "search", placeholder: `Filter ${K.label.toLowerCase()}`, value: filter, "aria-label": "Filter items", style: { maxWidth: "240px" } });
    search.addEventListener("input", () => {
      filter = search.value;
      const pos = search.selectionStart;
      drawMain();
      const again = main.querySelector("input[type=search]");
      again?.focus();
      again?.setSelectionRange(pos, pos);
    });
    const add = h("button", { type: "button", class: "btn small primary", disabled: all.length >= 500, on: { click: addItem } }, icon("plus"), `Add ${K.noun}`);
    const cols = [
      { label: K.noun[0].toUpperCase() + K.noun.slice(1), cell: ({ it }) => h("div", { class: "stack", style: { gap: "2px" } },
        h("span", { class: "strong", dir: kind === "vocabulary" && it.lang === "ar" ? "rtl" : null, style: { alignSelf: "flex-start" } }, itemTitle(kind, it)),
        it.id && itemTitle(kind, it) !== it.id ? h("span", { class: "small muted mono" }, it.id) : null) },
      { label: "Details", cell: ({ it }) => itemSub(kind, it) },
      t3Fields.length ? { label: "Languages", cell: ({ it }) => {
        const miss = missingLangs(it);
        return miss.length ? chip(`${miss.map((l) => l.toUpperCase()).join(", ")} missing`, "bad") : chip("EN · AR · ES", "good");
      } } : null,
      { label: "Checks", cell: ({ i }) => {
        const e = itemErrs(i).length;
        const w = itemWarns(i).length;
        return e ? chip(`${e} to fix`, "bad") : w ? chip(`${w} warning${w === 1 ? "" : "s"}`, "warn") : chip("OK", "flat");
      } },
    ].filter(Boolean);
    const card = h("section", { class: "card" },
      h("div", { class: "card-head", style: { alignItems: "center" } }, h("h2", {}, K.label), h("div", { class: "pills" }, search, add)),
      all.length
        ? table(cols, shown, { onRow: ({ i }) => openEditor(i), selected: ({ i }) => i === selected, empty: h("p", { class: "muted small" }, `Nothing matches “${filter}”.`) })
        : empty(`No ${K.noun}s in this pack yet`, `The app’s built-in ${K.label.toLowerCase()} stay. A pack adds to them or replaces one by its ID.`, add),
      h("span", { class: "small muted" }, NOTE[kind]));
    put(main, card, kind === "exercises" ? removedCard() : null);
  }

  const NOTE = {
    foods: "Values are per 100 g. Phones show pack foods next to the built-in staples; Open Food Facts items aren’t edited here.",
    vocabulary: "Extra unit words for the Write parser. Built-in words win when both define the same word.",
    eating_out: "Values are per portion. A dish joins the built-in ones of its group; the same ID replaces a built-in dish.",
    exercises: "The app bundles 870+ exercises from free-exercise-db. A pack item with the same ID replaces the bundled one.",
    templates: "Listed after the three built-in templates on Train. Starting one creates its routines.",
    awards: "Shown with the built-in awards and earned when the metric reaches the threshold.",
    challenges: "One per month. The month’s challenge uses this title and target (12 when there is none).",
  };

  function copyCard() {
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "Onboarding & copy"), h("span", { class: "small muted" }, "Leave all three empty to keep the built-in text")),
      ...COPY_KEYS.map(({ key, en }) => {
        const path = `overrides.${key}`;
        const field = langField(key, work.overrides[key] ?? {}, {
          multiline: key.endsWith("Body"), max: 240,
          onChange: (v) => {
            if (!v.en.trim() && !v.ar.trim() && !v.es.trim()) delete work.overrides[key];
            else work.overrides[key] = v;
            copyKey = key;
            changed(path);
          },
        });
        field.addEventListener("focusin", () => {
          if (copyKey === key) return;
          copyKey = key;
          for (const p of previews) p.refresh();
        });
        return h("div", { class: "stack copy-row", style: { gap: "6px" } }, field,
          h("span", { class: "small muted" }, `Built-in English: ${en}`), errLine(path));
      }));
  }

  function removedCard() {
    work.removed ??= [];
    const input = h("input", { class: "input mono", placeholder: "Barbell_Hip_Thrust", "aria-label": "Exercise ID to remove" });
    const add = () => {
      const id = input.value.trim();
      if (!id) return;
      if (work.removed.includes(id)) return toast("Already removed", "bad");
      work.removed.push(id);
      changed("removed");
    };
    return h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, "Removed from the library"), h("span", { class: "small muted" }, "Past workouts still show them")),
      work.removed.length
        ? h("div", { class: "pills" }, work.removed.map((id, i) => h("span", { class: `chip ${errors().some((e) => e.key === `removed.${i}` || e.key === "removed") ? "bad" : "flat"} chip-x mono` }, id,
            h("button", { type: "button", "aria-label": `Keep ${id}`, on: { click: () => { work.removed.splice(i, 1); changed("removed"); } } }, icon("close", 14)))))
        : h("span", { class: "small muted" }, "Nothing removed. Removing an exercise hides it from search and pickers."),
      h("form", { class: "form", on: { submit: (e) => { e.preventDefault(); add(); } } },
        h("label", { class: "field wide" }, h("span", {}, "Remove an exercise"), input),
        h("button", { type: "submit", class: "btn" }, "Remove from library")),
      errLine("removed", true));
  }

  // ---- one editor for every kind, built from FIELDS
  function errLine(path, deep = false) {
    const e = h("span", { class: "field-err", role: "alert" });
    e.refresh = () => {
      const msgs = errors().filter((x) => x.key === path || (deep ? x.key.startsWith(`${path}.`) : /^\.(en|ar|es)$/.test(x.key.slice(path.length)) && x.key.startsWith(path))).map((x) => x.message);
      e.textContent = [...new Set(msgs)].join(" · ");
      e.hidden = !msgs.length;
    };
    e.refresh();
    errLines.add(e);
    return e;
  }

  function fieldNode(spec, obj, path, redraw) {
    const set = (v) => {
      if (v === undefined) delete obj[spec.key];
      else obj[spec.key] = v;
      changed(path);
    };
    const v = obj[spec.key];
    const wrap = (input, full = false, hint = null) => h("div", { class: `field${full ? " full" : ""}` },
      h("label", { class: "field", style: { gap: "6px" } }, h("span", {}, spec.label), input), hint ? h("span", { class: "small muted num" }, hint) : null, errLine(path));
    switch (spec.type) {
      case "t3":
        return h("div", { class: "full stack", style: { gap: "4px" } }, langField(spec.label, v ?? {}, { multiline: !!spec.multiline, max: spec.max, onChange: set }), errLine(path));
      case "num":
      case "int": {
        const input = h("input", { class: "input num", type: "number", inputmode: spec.type === "int" ? "numeric" : "decimal", value: v == null ? "" : String(v), min: spec.min, max: spec.max, step: spec.type === "int" ? "1" : "any" });
        input.addEventListener("input", () => set(input.value === "" ? (spec.optional ? undefined : NaN) : Number(input.value)));
        return wrap(input, false, `${spec.min}–${spec.max}${spec.optional ? " · optional" : ""}`);
      }
      case "enum": {
        const label = (o) => (Array.isArray(spec.labels) ? spec.labels[o] : spec.labels?.[o]) ?? o;
        const input = h("select", { class: "input" },
          spec.optional ? h("option", { value: "" }, "Not set") : null,
          spec.options.map((o) => h("option", { value: String(o), selected: o === v }, label(o))));
        input.addEventListener("change", () => {
          set(input.value === "" ? undefined : spec.number ? Number(input.value) : input.value);
          if (spec.key === "lang") redraw();
        });
        return wrap(input);
      }
      case "id":
      case "text":
      case "month": {
        const listId = spec.suggest ? `dl-${spec.key}` : null;
        const input = h("input", {
          class: `input${spec.mono || spec.type === "id" ? " mono" : ""}`, type: spec.type === "month" ? "month" : "text", value: v ?? "",
          maxlength: spec.max ?? (spec.type === "id" ? 40 : null), list: listId, autocomplete: "off", spellcheck: "false",
          dir: spec.dirFrom && obj[spec.dirFrom] === "ar" ? "rtl" : null,
        });
        input.addEventListener("input", () => set(input.value === "" && spec.optional ? undefined : input.value));
        return wrap(h("div", { class: "stack", style: { gap: "0" } }, input,
          listId ? h("datalist", { id: listId }, spec.suggest.map((o) => h("option", { value: o }))) : null), (spec.max ?? 0) > 40);
      }
      case "multi": {
        const cur = new Set(v ?? []);
        return h("div", { class: "field full" }, h("span", {}, spec.label),
          h("div", { class: "pills", role: "group", "aria-label": spec.label }, spec.options.map((o) => {
            const b = h("button", { type: "button", class: "pill small", "aria-pressed": String(cur.has(o)) }, o);
            b.addEventListener("click", () => {
              if (cur.has(o)) cur.delete(o);
              else cur.add(o);
              b.setAttribute("aria-pressed", String(cur.has(o)));
              set(spec.options.filter((x) => cur.has(x)));
            });
            return b;
          })), errLine(path));
      }
      case "lines": {
        const input = h("textarea", { class: `input${spec.mono ? " mono" : ""}`, rows: "3" });
        input.value = (v ?? []).join("\n");
        input.addEventListener("input", () => {
          const lines = input.value.split("\n").map((s) => s.trim()).filter(Boolean);
          set(lines.length ? lines : undefined);
        });
        return wrap(input, true);
      }
      case "rows": {
        obj[spec.key] ??= [];
        const rows = obj[spec.key];
        const tooFew = rows.length <= spec.min;
        return h("div", { class: "field full stack", style: { gap: "10px" } },
          h("div", { class: "card-head", style: { alignItems: "center" } }, h("span", { class: "small muted", style: { fontWeight: "600" } }, `${spec.label} · ${rows.length} of ${spec.max}`),
            h("button", { type: "button", class: "btn small", disabled: rows.length >= spec.max, on: { click: () => { rows.push(spec.blank()); changed(path); redraw(); } } }, icon("plus"), `Add ${spec.noun}`)),
          rows.map((row, i) => h("div", { class: `well pack-rows${spec.compact ? " compact" : ""}` },
            h("div", { class: "card-head", style: { alignItems: "center" } },
              h("span", { class: "small strong" }, spec.compact ? `${i + 1}.` : `${spec.noun[0].toUpperCase() + spec.noun.slice(1)} ${i + 1}`),
              h("button", { type: "button", class: "btn small link", disabled: tooFew, on: { click: () => { rows.splice(i, 1); changed(path); redraw(); } } }, "Remove")),
            h("div", { class: "pack-form" }, spec.fields.map((f) => fieldNode(f, row, `${path}.${i}.${f.key}`, redraw))))),
          errLine(path));
      }
    }
    return null;
  }

  function openEditor(i) {
    selected = i;
    drawPreview();
    drawTool();
    drawMain(true);
    const it = list()[i];
    const path = `${K.list}.${i}`;
    const bodyEl = h("div", { class: "stack", style: { gap: "16px" } });
    const draw = () => {
      put(bodyEl, 
        itemNotes(i),
        h("div", { class: "pack-form" }, FIELDS[kind].map((f) => fieldNode(f, it, `${path}.${f.key}`, draw))),
        previewBlock(() => list()[i]));
    };
    draw();
    const remove = h("button", { type: "button", class: "btn small danger", on: { click: () => {
      work[K.list].splice(i, 1);
      selected = Math.max(0, Math.min(selected, list().length - 1));
      s.close();
      changed(K.list);
      drawPreview();
      toast(`${itemTitle(kind, it)} removed from the draft`);
    } } }, "Remove");
    const s = sheet(`Edit ${K.noun}`, bodyEl, [remove, h("button", { type: "button", class: "btn small primary", on: { click: () => s.close() } }, "Done")]);
  }

  /** Item-level findings at the top of the editor: macro totals, the award rule. */
  function itemNotes(i) {
    const box = h("div", { class: "stack", style: { gap: "8px" } });
    box.refresh = () => {
      const rule = errors().some((e) => itemIndex(e.key) === i && e.message === AWARD_RULE);
      const own = errors().filter((e) => e.key === `${K.list}.${i}` && e.message !== AWARD_RULE);
      put(box, 
        ...(rule ? [h("div", { class: "banner", role: "alert" }, h("div", {}, h("b", {}, "Awards can’t reward weight loss or eating less."), h("div", { class: "small" }, "Try showing up instead: “Logged 30 days” or “Trained 12 times this month”.")))] : []),
        ...own.map((e) => h("div", { class: "banner", role: "alert" }, h("span", { class: "small" }, e.message))),
        ...itemWarns(i).map((w) => h("div", { class: "banner warn" }, h("span", { class: "small" }, w.message))));
    };
    box.refresh();
    previews.add(box);
    return box;
  }

  function addItem() {
    const it = blankItem(kind, list());
    work[K.list].push(it);
    filter = "";
    changed(null);
    openEditor(list().length - 1);
  }

  // ---- checks card (EdgeContent A)
  function drawChecks() {
    const errs = errors();
    const lines = checkLines(errs, warnings());
    const state = { idle: "", checking: "Checking…", done: "Checked by the server", failed: "Server check didn’t run · showing the dashboard’s own checks" }[checkState];
    put(checksCard, 
      h("div", { class: "card-head" }, h("h2", {}, "Checks"), h("span", { class: "small muted" }, `${K.label} pack · ${lines.length} check${lines.length === 1 ? "" : "s"}`)),
      h("div", { class: "stack checks", style: { gap: "12px" } }, lines.map((l) => {
        const i = l.key != null ? itemIndex(l.key) : null;
        return h("div", { class: "check" },
          h("span", { class: `mark ${l.tone}`, "aria-hidden": "true" }, l.tone === "good" ? "✓" : "!"),
          h("div", { class: "stack", style: { gap: "2px", minWidth: "0", flex: "1" } },
            h("span", { class: "strong" }, h("span", { class: "sr" }, l.tone === "bad" ? "Error: " : l.tone === "warn" ? "Warning: " : ""), l.title),
            l.note ? h("span", { class: `small muted${l.note === l.key ? " mono" : ""}` }, l.note) : null),
          i != null && list()[i] ? h("button", { type: "button", class: "btn small link", on: { click: () => openEditor(i) } }, "Open") : null);
      })),
      state ? h("span", { class: "small muted" }, state) : null,
      publisher ? publishButton(errs.length) : null);
  }

  // ---- phone preview in EN / AR / ES
  function previewBlock(getItem) {
    const seg = h("div", { class: "seg", role: "group", "aria-label": "Preview language" });
    const slot = h("div", { class: "stack", style: { alignItems: "center" } });
    const box = h("div", { class: "stack" }, seg, slot);
    box.refresh = () => {
      clear(seg).append(...LANGS.map(([k, t]) => h("button", { type: "button", "aria-pressed": String(k === lang), on: { click: () => { lang = k; for (const p of previews) p.refresh(); } } }, t)));
      const it = getItem();
      put(slot, it ? h("div", { lang, class: lang === "ar" ? "ar" : null }, phonePreview(phoneCard(it), { rtl: lang === "ar" })) : h("span", { class: "small muted" }, `Add a ${K.noun} to preview it.`));
    };
    box.refresh();
    previews.add(box);
    return box;
  }

  function drawPreview() {
    put(previewCard, 
      h("div", { class: "card-head" }, h("h2", {}, "Preview"), h("span", { class: "small muted" }, lang === "ar" ? "Arabic reads right to left" : "As the phone shows it")),
      previewBlock(() => (kind === "copy" ? { key: copyKey } : list()[selected])));
  }

  function phoneCard(it) {
    const u = UI[lang];
    const tx = (t) => t?.[lang]?.trim() || h("span", { class: "pmiss" }, u.missing);
    const pc = (...kids) => h("div", { class: "pcard stack", style: { gap: "6px" } }, ...kids);
    const line = (text) => h("span", { class: "pline" }, text);
    switch (kind) {
      case "foods":
        return pc(h("span", { class: "ptitle" }, tx(it.name)), line(`${it.kcal} ${u.kcal} · ${u.per100}`),
          line(`${u.p} ${it.protein} ${u.g} · ${u.c} ${it.carbs} ${u.g} · ${u.f} ${it.fat} ${u.g}`), it.serving_g ? line(`1 × ${it.serving_g} ${u.g}`) : null);
      case "vocabulary":
        return pc(h("span", { class: "ptitle", dir: it.lang === "ar" ? "rtl" : "ltr" }, `2 ${it.word || "…"}`), line(`= 2 × ${it.unit}`));
      case "eating_out":
        return pc(h("span", { class: "pline" }, it.group === "side" ? u.side : u.main), h("span", { class: "ptitle" }, tx(it.name)),
          line(`${it.g} ${u.g} · ${it.kcal} ${u.kcal}`), line(`${u.p} ${it.p} · ${u.c} ${it.c} · ${u.f} ${it.f}`));
      case "exercises":
        return pc(h("div", { class: "pphoto" }, it.images?.length ? `${it.images.length} photo${it.images.length === 1 ? "" : "s"}` : "No photo"),
          h("span", { class: "ptitle" }, tx(it.name)),
          line([...(it.primary ?? []).map((m) => muscleName(m, lang)), it.level].filter(Boolean).join(" · ")),
          h("span", { class: "pbtn" }, u.start));
      case "templates":
        return pc(h("span", { class: "ptitle" }, tx(it.name)),
          ...(it.routines ?? []).map((r) => h("div", { class: "prow" },
            h("span", {}, new Intl.DateTimeFormat(lang, { weekday: "short" }).format(new Date(Date.UTC(2024, 0, 1 + (r.weekday ?? 0))))),
            h("span", { class: "pgrow" }, tx(r.name)),
            h("span", {}, `${(r.items ?? []).reduce((a, x) => a + (Number(x.sets) || 0), 0)} ${u.sets}`))));
      case "awards":
        return pc(h("div", { class: "pmedal", "aria-hidden": "true" }, String(it.threshold ?? "")), h("span", { class: "ptitle" }, tx(it.name)), line(tx(it.description)));
      case "challenges": {
        const d = /^\d{4}-\d{2}$/.test(it.month ?? "") ? new Intl.DateTimeFormat(lang, { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${it.month}-01T00:00:00Z`)) : it.month;
        return pc(line(d), h("span", { class: "ptitle" }, tx(it.title)), h("div", { class: "ptrack" }, h("i", { style: { width: "33%" } })), line(`4 / ${it.target} ${u.times}`));
      }
      case "copy": {
        const o = work.overrides[it.key];
        const builtIn = COPY_KEYS.find((c) => c.key === it.key)?.en;
        return pc(h("span", { class: "pline mono", dir: "ltr" }, it.key), h("span", {}, o ? tx(o) : lang === "en" ? builtIn : h("span", { class: "pmiss" }, "Built-in text in this language")));
      }
    }
    return null;
  }

  // ---- per-kind tools: Test box, weekly sets, the award rule
  let testResults;
  function drawTool() {
    if (kind === "vocabulary") return testBox();
    if (kind === "templates") return setsCard();
    if (kind === "awards") return ruleCard();
    toolCard.hidden = true;
  }

  function testBox() {
    toolCard.hidden = false;
    // Built once, so typing here never loses focus to a redraw.
    if (testResults) return testResults.refresh();
    const testInput = h("input", { class: "input", value: "2 scoops whey and a handful of almonds", "aria-label": "Type a meal", dir: "auto" });
    const results = (testResults = h("div", { class: "stack", style: { gap: "8px" } }));
    testInput.addEventListener("input", () => results.refresh());
    results.refresh = () => {
      const { found, other } = matchUnits(testInput.value, list());
      put(results, 
        ...found.map((f) => h("div", { class: "cfg-row", style: { alignItems: "center" } },
          h("span", { dir: "auto" }, h("b", {}, f.token), ` → ${f.unit} · ${LANG_NAME[f.lang] ?? f.lang}`), chip("Matched", "good"))),
        found.length ? null : h("span", { class: "small muted" }, "No unit words from this pack in that meal."),
        other.length ? h("span", { class: "small muted", dir: "auto" }, `Not unit words in this pack: ${other.join(", ")}`) : null);
    };
    results.refresh();
    put(toolCard, 
      h("div", { class: "card-head" }, h("h2", {}, "Test box"), h("span", { class: "small muted" }, "Uses this draft’s words")),
      h("label", { class: "field" }, h("span", {}, "Type a meal"), testInput), results,
      h("span", { class: "small muted" }, "This checks the pack’s unit words only. The app’s Write parser also knows its built-in words, numbers and foods."));
  }

  function setsCard() {
    toolCard.hidden = false;
    const tpl = list()[selected];
    if (!tpl) return put(toolCard, h("h2", {}, "Weekly sets"), h("span", { class: "small muted" }, "Add a template to see its weekly sets."));
    const w = weeklySets(tpl);
    put(toolCard, 
      h("div", { class: "card-head" }, h("h2", {}, "Weekly sets"), h("span", { class: "small muted" }, `${itemTitle(kind, tpl)} · ${w.total} sets a week`)),
      table([
        { label: "Day", cell: (r) => (r.weekday != null ? new Intl.DateTimeFormat("en", { weekday: "short" }).format(new Date(Date.UTC(2024, 0, 1 + r.weekday))) : "—") },
        { label: "Routine", class: "strong", cell: (r) => r.name },
        { label: "Exercises", end: true, cell: (r) => String(r.exercises) },
        { label: "Sets", end: true, cell: (r) => String(r.sets) },
      ], w.routines),
      table([
        { label: "Exercise", class: "mono", cell: (r) => r.exercise || "—" },
        { label: "Sets / week", end: true, cell: (r) => String(r.sets) },
      ], w.exercises),
      h("span", { class: "small muted" }, "The app checks weekly volume per muscle against 10–20 sets when someone starts the template."));
  }

  function ruleCard() {
    toolCard.hidden = false;
    const blocked = errors().filter((e) => e.message === AWARD_RULE).length;
    put(toolCard, 
      h("div", { class: "card-head" }, h("h2", {}, "The award rule"), blocked ? chip(`${blocked} blocked`, "bad") : chip("All clear", "good")),
      h("span", { class: "small" }, AWARD_RULE),
      h("span", { class: "small muted" }, `Metrics: ${Object.values(METRIC_LABEL).join(", ")}.`));
  }

  // ---- versions
  function drawHistory() {
    put(historyCard, 
      h("div", { class: "card-head" }, h("h2", {}, "Versions"), h("span", { class: "small muted" }, "Rollback publishes a copy as a new version")),
      table([
        { label: "Version", class: "strong", cell: (r) => `v${r.version}` },
        { label: "Status", cell: (r) => statusChip(r.status) },
        { label: "By", cell: (r) => r.published_by ?? r.created_by },
        { label: "When", cell: (r) => relTime(r.published_at ?? r.created_at) },
        { label: "Note", cell: (r) => r.note ?? "" },
        { label: "", end: true, cell: (r) => (publisher && r.status === "archived" ? h("button", { type: "button", class: "btn small", on: { click: () => rollback(r) } }, "Roll back") : "") },
      ], data.history ?? [], { empty: h("p", { class: "muted small" }, `Nothing published yet. Phones use the built-in ${K.label.toLowerCase()} only.`) }));
  }

  // ---- draft → review → publish, as on Remote config, every call naming the kind
  const diffOf = () => diffView(keyedBody(kind, live()), keyedBody(kind, work));

  function showDiff() {
    sheet("Changes from what phones have", h("div", { class: "stack" }, diffOf()));
  }

  async function save(note) {
    try {
      await call("packs.save_draft", { kind, body: work, note: note ?? null });
      return true;
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        saveErrs = e.body?.errors ?? [];
        refresh();
        toast("Fix the highlighted values first", "bad");
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
    if ((unsaved() || !data.draft) && !(await save())) return;
    try {
      await call("packs.submit", { kind });
      toast("Sent to the Owner for review");
    } catch {
      toast("Couldn’t send it for review", "bad");
    }
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
    if (!(await confirmDialog({ title: "Discard this draft?", body: `Phones keep the published ${K.label} pack. The draft is archived and logged.`, confirm: "Discard", danger: true }))) return;
    try {
      await call("packs.discard", { kind });
    } catch (e) {
      return toast(errorText(e, "Couldn’t discard the draft"), "bad");
    }
    toast("Draft discarded");
    await load();
  }

  async function publish() {
    const next = (data.history?.[0]?.version ?? 0) + (data.draft ? 0 : 1);
    const ok = await confirmDialog({
      title: `Publish ${K.label} v${next} to Production?`,
      body: h("div", { class: "stack" }, diffOf(),
        h("span", { class: "small muted" }, `Phones download it on next launch and check its checksum.${data.published ? ` v${data.published.version} stays available for rollback.` : ""}`)),
      confirm: "Publish",
    });
    if (!ok) return;
    if ((unsaved() || !data.draft) && !(await save())) return;
    const fresh = await call("packs.get", { kind });
    try {
      await call("packs.publish", { kind, version: fresh.draft.version });
      toast(`${K.label} v${fresh.draft.version} published`);
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        saveErrs = e.body?.errors ?? [];
        toast("The draft has errors", "bad");
      } else toast("Couldn’t publish", "bad");
    }
    await load();
  }

  async function rollback(r) {
    const ok = await confirmDialog({
      title: `Roll back ${K.label} to v${r.version}?`,
      body: `v${data.published?.version ?? "?"} becomes archived and v${r.version}'s content goes out as a new version. Any open draft is archived first. This is logged.`,
      confirm: "Roll back", danger: true,
    });
    if (!ok) return;
    try {
      await call("packs.rollback", { kind, to_version: r.version });
      toast(`Rolled back to v${r.version}`);
    } catch (e) {
      toast(e instanceof ApiError && e.code === "invalid" ? `v${r.version} no longer passes the checks` : "Couldn’t roll back", "bad");
    }
    await load();
  }

  await load();
}
