// The Control Center's shared components (the spec's list): KPI tile with
// sparkline, table, chips, side sheet, confirm-by-email dialog, alert strip,
// three-language field, diff viewer, phone preview, charts, loading, empty
// and error states, toast.

import { clear, h, icon, s } from "./dom.js";
import { barPath, dayLabel, fmtInt, linePath, sparkPath } from "./format.js";

export const chip = (text, tone = "flat") => h("span", { class: `chip ${tone}` }, text);

export const STATUS_TONE = { draft: "flat", in_review: "warn", published: "good", archived: "flat", scheduled: "warn", sent: "good", cancelled: "flat", new: "bad", waiting: "warn", solved: "good" };
export const STATUS_LABEL = { draft: "Draft", in_review: "In review", published: "Published", archived: "Archived", scheduled: "Scheduled", sent: "Sent", cancelled: "Cancelled", new: "New", waiting: "Waiting", solved: "Solved" };
export const statusChip = (status) => chip(STATUS_LABEL[status] ?? status, STATUS_TONE[status] ?? "flat");

export function pageHead(eyebrow, title, em, right, { emFirst = false } = {}) {
  const t = emFirst ? [h("span", { class: "em" }, em), " ", title] : [title, " ", h("span", { class: "em" }, em)];
  return h("div", { class: "head" }, h("div", {}, h("div", { class: "eyebrow" }, eyebrow), h("h1", {}, t)), right ?? null);
}

export function kpi({ label, value, delta, tone = "flat", spark, sparkTone = "chart-1" }) {
  return h("div", { class: "card tight kpi" },
    h("div", { class: "top-line" }, h("span", { class: "label" }, label), delta ? chip(delta, tone) : null),
    h("div", { class: "value num" }, value),
    spark?.length > 1
      ? s("svg", { viewBox: "0 0 120 32", preserveAspectRatio: "none", "aria-hidden": "true" },
          s("path", { d: sparkPath(spark), fill: "none", stroke: `var(--${sparkTone})`, "stroke-width": 2, "stroke-linejoin": "round", "vector-effect": "non-scaling-stroke" }))
      : null);
}

/** columns: [{label, cell(row) → node|string, class?, end?}] */
export function table(columns, rows, { onRow, empty, selected } = {}) {
  if (!rows.length && empty) return empty;
  return h("div", { class: "table-wrap" },
    h("table", {},
      h("thead", {}, h("tr", {}, columns.map((c) => h("th", { scope: "col", class: c.end ? "end" : null }, c.label)))),
      h("tbody", {}, rows.map((r) =>
        h("tr", {
          class: onRow ? "clickable" : null,
          tabindex: onRow ? "0" : null,
          "aria-selected": selected ? String(selected(r)) : null,
          on: onRow ? { click: () => onRow(r), keydown: (e) => (e.key === "Enter" || e.key === " ") && (e.preventDefault(), onRow(r)) } : null,
        }, columns.map((c) => h("td", { class: [c.class, c.end ? "end num" : null].filter(Boolean).join(" ") || null }, c.cell(r))))))));
}

export function alertStrip(alerts) {
  if (!alerts.length) return null;
  return h("div", { class: "alerts", role: "status" }, alerts.map((a) =>
    h("div", { class: "alert" },
      h("span", { class: `dot ${a.tone}`, "aria-hidden": "true" }),
      h("div", { style: { flex: "1", minWidth: "0" } }, h("b", {}, a.title), h("div", { class: "small muted" }, a.sub)),
      a.link ? h("a", { href: a.link, class: "small", style: { fontWeight: "600" } }, a.action ?? "Open") : null)));
}

export const empty = (title, sub, action) => h("div", { class: "empty" }, h("b", {}, title), h("div", { class: "muted" }, sub), action ?? null);

export const errorBanner = (title, sub, retry) =>
  h("div", { class: "banner", role: "alert" }, h("div", {}, h("b", {}, title), h("div", { class: "small muted" }, sub)),
    retry ? h("button", { type: "button", class: "btn small", on: { click: retry } }, "Try again") : null);

export function skeleton(blocks = 4) {
  return h("div", { "aria-busy": "true", class: "stack" },
    h("div", { class: "skel", style: { height: "44px", width: "40%" } }),
    h("div", { class: "grid kpis" }, Array.from({ length: blocks }, () => h("div", { class: "skel", style: { height: "148px", borderRadius: "24px" } }))),
    h("div", { class: "skel", style: { height: "260px", borderRadius: "24px" } }));
}

let toastTimer;
export function toast(text, tone = "") {
  document.querySelector(".toast")?.remove();
  const t = h("div", { class: `toast ${tone}`, role: "status" }, text);
  document.body.append(t);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.remove(), 3200);
}

/** A side panel with a title, a body and footer buttons; returns {close}. */
export function sheet(title, body, footer = []) {
  const prev = document.activeElement;
  const scrim = h("div", { class: "scrim" });
  const panel = h("aside", { class: "sheet", role: "dialog", "aria-modal": "true", "aria-label": title },
    h("div", { class: "sheet-head" }, h("h2", {}, title),
      h("button", { type: "button", class: "icon-btn", "aria-label": "Close", on: { click: () => close() } }, icon("close"))),
    body,
    footer.length ? h("div", { class: "sheet-foot" }, footer) : null);
  const onKey = (e) => e.key === "Escape" && close();
  function close() {
    scrim.remove();
    panel.remove();
    document.removeEventListener("keydown", onKey);
    prev?.focus?.();
  }
  scrim.addEventListener("click", close);
  document.addEventListener("keydown", onKey);
  document.body.append(scrim, panel);
  panel.querySelector("input, select, textarea, button")?.focus();
  return { close, panel };
}

/** A confirm dialog. With [typeToConfirm], the button only enables once that text is typed. */
export function confirmDialog({ title, body, confirm = "Confirm", danger = false, typeToConfirm = null, field = null }) {
  return new Promise((resolve) => {
    const scrim = h("div", { class: "scrim" });
    const typed = typeToConfirm ? h("input", { class: "input", "aria-label": `Type ${typeToConfirm} to confirm`, autocomplete: "off" }) : null;
    const go = h("button", { type: "button", class: `btn ${danger ? "danger solid" : "primary"}`, disabled: !!typeToConfirm }, confirm);
    const box = h("div", { class: "dialog", role: "alertdialog", "aria-modal": "true", "aria-label": title },
      h("div", { class: `title ${danger ? "bad" : ""}` }, title),
      h("div", { class: "muted" }, body),
      field,
      typed ? h("label", { class: "field" }, h("span", {}, `Type ${typeToConfirm} to confirm`), typed) : null,
      h("div", { class: "actions" }, h("button", { type: "button", class: "btn", on: { click: () => done(false) } }, "Cancel"), go));
    typed?.addEventListener("input", () => (go.disabled = typed.value.trim().toLowerCase() !== typeToConfirm.toLowerCase()));
    go.addEventListener("click", () => done(typed ? typed.value.trim() : true));
    const onKey = (e) => e.key === "Escape" && done(false);
    function done(v) {
      scrim.remove();
      box.remove();
      document.removeEventListener("keydown", onKey);
      resolve(v);
    }
    document.addEventListener("keydown", onKey);
    document.body.append(scrim, box);
    (typed ?? field?.querySelector?.("input, select, textarea") ?? go).focus();
  });
}

export const LANGS = [["en", "EN"], ["ar", "AR"], ["es", "ES"]];

/** EN / AR / ES tabs over one input; Arabic is typed and shown right-to-left. */
export function langField(label, value = {}, { multiline = false, onChange, max } = {}) {
  const val = { en: "", ar: "", es: "", ...value };
  let cur = "en";
  const input = h(multiline ? "textarea" : "input", { class: "input", maxlength: max ?? null });
  const tabs = h("div", { class: "langtabs", role: "tablist", "aria-label": `${label} language` });
  function draw() {
    input.value = val[cur];
    input.dir = cur === "ar" ? "rtl" : "ltr";
    input.lang = cur;
    clear(tabs).append(...LANGS.map(([k, t]) =>
      h("button", { type: "button", role: "tab", "aria-selected": String(k === cur), class: val[k].trim() ? null : "missing", title: val[k].trim() ? null : "Missing", on: { click: () => { cur = k; draw(); } } }, t)));
  }
  input.addEventListener("input", () => {
    val[cur] = input.value;
    onChange?.({ ...val });
    tabs.querySelectorAll("button").forEach((b, i) => b.classList.toggle("missing", !val[LANGS[i][0]].trim()));
  });
  draw();
  const el = h("div", { class: "field" }, h("div", { class: "card-head" }, h("span", { class: "small muted", style: { fontWeight: "600" } }, label), tabs), input);
  el.value = () => ({ ...val });
  return el;
}

/** Changed keys between two flat-ish objects, as − old / + new lines. */
export function diffView(before, after) {
  const flat = (o, p = "", out = {}) => {
    for (const [k, v] of Object.entries(o ?? {})) {
      if (v && typeof v === "object" && !Array.isArray(v)) flat(v, p + k + ".", out);
      else out[p + k] = JSON.stringify(v);
    }
    return out;
  };
  const a = flat(before);
  const b = flat(after);
  const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])].filter((k) => a[k] !== b[k]).sort();
  if (!keys.length) return h("div", { class: "diff" }, h("span", { class: "muted" }, "No changes"));
  return h("div", { class: "diff", "aria-label": "Changes" }, keys.map((k) => [
    h("div", { class: "key" }, k),
    a[k] !== undefined ? h("div", { class: "del" }, `− ${a[k]}`) : null,
    b[k] !== undefined ? h("div", { class: "add" }, `+ ${b[k]}`) : null,
  ]));
}

export function phonePreview(children, { rtl = false } = {}) {
  return h("div", { class: "phone", dir: rtl ? "rtl" : "ltr" }, h("span", { class: "small", style: { color: "#8D948A" } }, "What users see"), children);
}

/** Daily line (area) or bars, with an optional second line, a hover readout and a table for screen readers. */
export function dailyChart({ series, label, kind = "line", second, secondLabel, fmt = fmtInt, fmt2 }) {
  const W = 600;
  const H = 190;
  const vals = series.map((d) => d.n);
  const svgEl = s("svg", { viewBox: `0 0 ${W} 200`, preserveAspectRatio: "none", role: "img", "aria-label": label },
    s("path", { class: "grid-l", d: "M0 40H600M0 90H600M0 140H600M0 190H600", "vector-effect": "non-scaling-stroke" }));
  if (kind === "line") {
    const line = linePath(vals, W, H);
    svgEl.append(s("path", { class: "a1", d: `${line} L${W} ${H} L0 ${H} Z` }), s("path", { class: "s1", d: line, "vector-effect": "non-scaling-stroke" }));
  } else {
    svgEl.append(s("path", { class: "b1", d: barPath(vals, W, H) }));
  }
  if (second) svgEl.append(s("path", { class: "s2", d: linePath(second, W, H), "vector-effect": "non-scaling-stroke" }));
  const tip = h("div", { class: "tip", hidden: true });
  const slot = W / series.length;
  series.forEach((d, i) => {
    const hit = s("rect", { class: "hit", x: i * slot, y: 0, width: slot, height: 200 });
    hit.addEventListener("mousemove", (e) => {
      tip.textContent = `${dayLabel(d.day)} · ${fmt(d.n)}${second ? ` · ${(fmt2 ?? fmt)(second[i])}` : ""}`;
      Object.assign(tip.style, { left: `${e.clientX}px`, top: `${e.clientY}px` });
      tip.hidden = false;
    });
    hit.addEventListener("mouseleave", () => (tip.hidden = true));
    svgEl.append(hit);
  });
  const ticks = [0, Math.floor(series.length / 3), Math.floor((2 * series.length) / 3), series.length - 1].map((i) => dayLabel(series[i].day));
  return h("div", { class: "chart" }, svgEl, tip,
    h("div", { class: "axis num", "aria-hidden": "true" }, ticks.map((t) => h("span", {}, t))),
    h("div", { class: "sr" }, h("table", {}, h("caption", {}, label),
      h("tr", {}, h("th", {}, "Day"), h("th", {}, "Value"), second ? h("th", {}, secondLabel ?? "Second") : null),
      series.map((d, i) => h("tr", {}, h("td", {}, d.day), h("td", {}, fmt(d.n)), second ? h("td", {}, (fmt2 ?? fmt)(second[i])) : null)))));
}

export function mixList(title, rows, alt = false) {
  return h("div", { class: "stack" }, h("span", { class: "small muted", style: { fontWeight: "600" } }, title),
    rows.length
      ? rows.map((r) => h("div", { class: "mixrow" }, h("span", {}, r.label),
          h("div", { class: `track ${alt ? "alt" : ""}` }, h("i", { style: { width: `${r.pct}%` } })),
          h("span", { class: "num", style: { width: "44px", textAlign: "end", fontWeight: "600" } }, `${r.pct}%`)))
      : h("span", { class: "muted small" }, "No backups have reported this yet."));
}

export function toggleSwitch(label, on, onChange, { disabled = false } = {}) {
  const b = h("button", { type: "button", role: "switch", class: "toggle", "aria-checked": String(!!on), "aria-label": label, disabled }, h("span", {}));
  b.addEventListener("click", () => {
    const next = b.getAttribute("aria-checked") !== "true";
    b.setAttribute("aria-checked", String(next));
    onChange(next);
  });
  return b;
}
