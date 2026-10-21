// 11 Website · Landing page: gymcoapp.com/ itself. One versioned document
// (sections, beta, copy, prices, store links, FAQ, sign-up) drafted,
// reviewed and published like Remote config. The page applies it on load;
// anything missing keeps the page's built-in value.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { fmtInt, relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import {
  accentParts, builtInScreen, checkLanding, cleanBody, comparable, coverCrop, errorsFor, fieldChanges, groupKeys, maxFor, moveItem, PRICE_MAX, PRICES, resetCopy, SCREEN_H, SCREEN_W, SCREENS, SECTIONS, setCopy, startBody, STORES,
} from "../lib/landing_form.js";
import { chip, confirmDialog, diffView, empty, langField, sheet, statusChip, table, toggleSwitch } from "../lib/ui.js";

const SITE = "https://gymcoapp.com/";
const GROUP = { hero: "Hero", food: "Food", train: "Train", coaching: "Coaching", streak: "Streaks", privacy: "Privacy", plans: "Plans", faq: "FAQ", join: "Join", footer: "Footer" };
const PART = { tag: "Tag", title: "Title", lede: "Lede", cta: "Main button", cta2: "Second button", eyebrow: "Eyebrow", sub: "Subtitle", banner: "Banner", consent: "Consent line", tagline: "Tagline" };
const MULTI = /\.(lede|sub|banner|consent|tagline)$/;
const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));

/** Renders the editor into [el]; returns {unsaved} for the Website page's leave guard. */
export async function renderLanding(el, { call, toast, me, isCurrent = () => true, onMeta }) {
  const publisher = can(me.role, "publish");
  const exporter = can(me.role, "audit_export");
  let data;
  let work;
  let serverErrs = [];
  const lines = new Set();

  const head = h("div", { class: "card config-head" });
  const body = h("div", { class: "stack", style: { gap: "16px" } });
  el.append(head, body);

  const defaults = () => data.defaults ?? {};
  const keys = () => data.keys ?? Object.keys(defaults().copy ?? {});
  // Missing fields keep the built-in values, so "nothing published" compares as {} filled with the defaults.
  const live = () => data.published?.body ?? {};
  const cmp = (b) => comparable(cleanBody(startBody({ defaults: defaults(), published: { body: b } })), defaults());
  const changes = () => fieldChanges(cmp(live()), cmp(work));
  const unsaved = () => !!work && fieldChanges(cmp(data.draft?.body ?? live()), cmp(work)) > 0;
  const allErrs = () => [...checkLanding(work, keys()), ...serverErrs];
  const errorCount = () => new Set(allErrs().map((e) => e.key)).size;

  async function load() {
    data = await call("landing.get");
    if (!isCurrent()) return;
    work = startBody(data);
    serverErrs = [];
    onMeta?.({ published_version: data.published?.version ?? null, draft_status: data.draft?.status ?? null });
    draw();
  }

  // ---- errors next to their fields
  function errLine(base) {
    const e = h("span", { class: "field-err", role: "alert" });
    e.refresh = () => {
      const msgs = errorsFor(allErrs(), base);
      e.textContent = msgs.join(" · ");
      e.hidden = !msgs.length;
    };
    e.refresh();
    lines.add(e);
    return e;
  }
  /** After an edit: the field's server errors go, the client checks rerun. */
  function changed(base) {
    if (base) serverErrs = serverErrs.filter((x) => x.key !== base && !x.key.startsWith(`${base}.`));
    for (const l of lines) l.isConnected ? l.refresh() : lines.delete(l);
    drawHead();
  }

  // ---- head
  function drawHead() {
    const draft = data.draft;
    const pubV = data.published?.version ?? 0;
    const n = changes();
    const bad = errorCount();
    const review = draft?.status === "in_review";
    const title = `Landing page · ${draft ? `v${draft.version} ${review ? "in review" : "draft"}` : unsaved() ? "unsaved draft" : pubV ? `published v${pubV}` : "built-in page"}`;
    const sub = pubV
      ? `${n} change${n === 1 ? "" : "s"} from published v${pubV} · the page fetches settings on load, cached a minute`
      : `${n} change${n === 1 ? "" : "s"} from the built-in page · nothing published yet, so gymcoapp.com shows its own copy`;
    put(head,
      h("div", { class: "stack", style: { gap: "4px", flex: "1 1 280px" } },
        h("div", { class: "row", style: { gap: "10px", alignItems: "center" } }, h("h2", {}, title), draft ? statusChip(draft.status) : null, unsaved() ? chip("Unsaved", "warn") : null),
        h("span", { class: "small muted" }, sub),
        review ? h("span", { class: "small" }, `Sent by ${draft.submitted_by ?? draft.created_by}${publisher ? " · approve to publish, or send it back with a note." : ". You can keep editing; saving again takes it back to draft."}`) : null,
        h("a", { href: SITE, target: "_blank", rel: "noopener", class: "small", style: { fontWeight: "600", display: "inline-flex", gap: "4px", alignItems: "center" } }, "Open gymcoapp.com ↗")),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small", disabled: !n, on: { click: showDiff } }, "View diff"),
        draft ? h("button", { type: "button", class: "btn small", on: { click: discard } }, "Discard draft") : null,
        review && publisher ? h("button", { type: "button", class: "btn small", on: { click: sendBack } }, "Send back") : null,
        h("button", { type: "button", class: "btn small", disabled: (!n && !unsaved()) || bad > 0, on: { click: () => saveAndReload("Draft saved") } }, "Save draft"),
        publisher
          ? h("button", { type: "button", class: "btn small publish", disabled: (!n && !draft) || bad > 0, on: { click: publish } }, bad ? `Publish · fix ${bad} error${bad === 1 ? "" : "s"} first` : review ? "Approve & publish" : "Publish")
          : h("button", { type: "button", class: "btn small primary", disabled: (!n && !draft) || bad > 0 || (review && !unsaved()), on: { click: submit } }, review && !unsaved() ? "Sent to the Owner" : bad ? `Fix ${bad} error${bad === 1 ? "" : "s"} first` : "Send for review")));
  }

  const card = (title, note, ...kids) => h("section", { class: "card" },
    h("div", { class: "card-head" }, h("h2", {}, title), note ? h("span", { class: "small muted" }, note) : null), ...kids);
  const label = (title, help, extra) => h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } },
    h("span", { class: "strong" }, title), help ? h("span", { class: "small muted" }, help) : null, extra ?? null);
  const switchRow = (title, help, on, set, extra) => h("div", { class: "cfg-row" }, label(title, help, extra), toggleSwitch(title, on, (v) => { set(v); changed(); }));
  const accent = (text) => accentParts(text).map((p) => (p.em ? h("em", { class: "accent" }, p.text) : p.text));

  // ---- cards
  function sectionsCard() {
    return card("Sections", "Off hides it on the page and in the menu",
      SECTIONS.map(([k, name, help]) => switchRow(name, help, work.sections[k] !== false, (v) => (work.sections[k] = v),
        work.sections[k] === false ? chip("Hidden", "warn") : null)));
  }

  function betaCard() {
    const w = data.waitlist ?? { count: 0, last_7d: 0 };
    return card("Beta and sign-up", null,
      switchRow("Beta", "Off hides the “Beta · free while in testing” tag, the testing banner over Plans and the “Unlocked in beta” badge; the Join buttons read “Download”.", work.beta !== false, (v) => (work.beta = v)),
      switchRow("Email sign-up", "The “Notify me” box and its consent line in Join. Off hides both; nobody new joins the list.", work.notify !== false, (v) => (work.notify = v)),
      h("div", { class: "rule" }),
      h("div", { class: "cfg-row waitlist-row" },
        h("div", { class: "stack", style: { gap: "2px", minWidth: "0" } },
          h("span", { class: "small muted strong" }, "Waitlist"),
          h("div", { class: "row", style: { gap: "10px", alignItems: "baseline" } }, h("span", { class: "plan-price num" }, fmtInt(w.count ?? 0)), h("span", { class: "small muted" }, `${fmtInt(w.last_7d ?? 0)} in the last 7 days`)),
          h("span", { class: "small muted" }, "Email and language only · one email at launch")),
        exporter
          ? h("button", { type: "button", class: "btn small", disabled: !w.count, on: { click: exportCsv } }, icon("download"), "Export CSV")
          : h("span", { class: "small muted" }, "Export needs the Owner")));
  }

  function textInput(base, value, { placeholder, hint, type = "text", onInput, aria }) {
    const input = h("input", { class: "input", type, value: value ?? "", placeholder, "aria-label": aria, spellcheck: "false", autocomplete: "off" });
    const err = errLine(base);
    input.addEventListener("input", () => { onInput(input.value); changed(base); });
    return [input, hint ? h("div", { class: "small muted" }, hint) : null, err];
  }

  function pricesCard() {
    const d = defaults().prices ?? {};
    return card("Prices", `Free text, ${PRICE_MAX} characters at most`,
      h("div", { class: "pack-form landing-prices" }, PRICES.map(([k, name]) =>
        h("label", { class: "field" }, h("span", {}, name),
          textInput(`prices.${k}`, work.prices[k], {
            placeholder: d[k], aria: name, hint: d[k] ? `Built-in ${d[k]}` : null,
            onInput: (v) => { if (v === "") delete work.prices[k]; else work.prices[k] = v; },
          })))),
      h("span", { class: "small muted" }, "Shown on Plans and in the FAQ answer about price. Store prices themselves are set in App Store Connect and Play Console; keep these in step."));
  }

  function storesCard() {
    return card("Store links", "The badges in the hero and Join",
      STORES.map(([k, name, prefix]) =>
        h("label", { class: "field" }, h("span", {}, name),
          textInput(`stores.${k}`, work.stores[k], { type: "url", placeholder: `${prefix}…`, aria: name, hint: `Starts with ${prefix} · empty links the badge to the sign-up (#join)`, onInput: (v) => (work.stores[k] = v) }))));
  }

  /** A picked file as the page draws it: 660 × 1434, trimmed from the middle if its shape differs, as JPEG. */
  async function toScreen(file) {
    const bmp = await createImageBitmap(file);
    const c = coverCrop(bmp.width, bmp.height);
    const canvas = h("canvas", { width: SCREEN_W, height: SCREEN_H });
    const g = canvas.getContext("2d");
    g.imageSmoothingQuality = "high";
    g.drawImage(bmp, c.x, c.y, c.w, c.h, 0, 0, SCREEN_W, SCREEN_H);
    bmp.close?.();
    const blob = await new Promise((done) => canvas.toBlob(done, "image/jpeg", 0.86));
    if (!blob) throw new Error("encode");
    const url = await new Promise((done, failed) => {
      const r = new FileReader();
      r.onload = () => done(String(r.result));
      r.onerror = failed;
      r.readAsDataURL(blob);
    });
    return { data: url.slice(url.indexOf(",") + 1), type: "image/jpeg", preview: URL.createObjectURL(blob) };
  }

  function screensCard() {
    const slot = (key, name, where) => {
      const has = () => !!work.screens[key];
      const img = h("img", { class: "screen-thumb", alt: `${name} phone`, width: SCREEN_W, height: SCREEN_H, src: work.screens[key] ?? builtInScreen(key), decoding: "async" });
      const state = h("span", {});
      const file = h("input", { type: "file", accept: "image/png,image/jpeg,image/webp", hidden: true });
      const pick = h("button", { type: "button", class: "btn small", on: { click: () => file.click() } }, icon("upload", 14), "Replace");
      const reset = h("button", { type: "button", class: "btn small link", on: { click: () => {
        delete work.screens[key];
        img.src = builtInScreen(key);
        mark();
        changed(`screens.${key}`);
      } } }, icon("undo", 14), "Use built-in");
      const mark = () => {
        put(state, has() ? chip("Changed", "brand") : chip("Built-in", "flat"));
        reset.disabled = !has();
      };
      file.addEventListener("change", async () => {
        const f = file.files?.[0];
        file.value = "";
        if (!f) return;
        if (!/^image\/(png|jpeg|webp)$/.test(f.type)) return toast("Pick a PNG, JPEG or WebP picture", "bad");
        pick.disabled = true;
        pick.classList.add("is-busy");
        put(pick, "Uploading…");
        try {
          const shot = await toScreen(f);
          const { url } = await call("landing.upload_screen", { slot: key, data: shot.data, type: shot.type });
          work.screens[key] = url;
          img.src = shot.preview;
          mark();
          changed(`screens.${key}`);
          toast(`${name} picture ready · save the draft and publish to put it live`);
        } catch (e) {
          if (e instanceof ApiError && e.code === "invalid") toast(e.body?.errors?.[0]?.message ?? "That picture can’t be used", "bad");
          else toast(errorText(e, "Couldn’t upload the picture"), "bad");
        } finally {
          pick.disabled = false;
          pick.classList.remove("is-busy");
          put(pick, icon("upload", 14), "Replace");
        }
      });
      mark();
      return h("div", { class: "screen-slot stack", style: { gap: "8px" } },
        img,
        h("div", { class: "stack", style: { gap: "2px" } }, h("span", { class: "strong" }, name), h("span", { class: "small muted" }, where)),
        state,
        h("div", { class: "row", style: { gap: "6px", flexWrap: "wrap" } }, pick, reset),
        file,
        errLine(`screens.${key}`));
    };
    return card("Screenshots", `The five phones in the hero · drawn at ${SCREEN_W} × ${SCREEN_H}`,
      h("span", { class: "small muted" }, "Phone screenshots fit as they are; other shapes are trimmed from the middle. A new picture goes live when the draft is published, in both light and dark."),
      h("div", { class: "screen-grid" }, SCREENS.map(([k, name, where]) => slot(k, name, where))));
  }

  function copyRow(key) {
    const hint = defaults().copy?.[key]?.en ?? "";
    const has = () => !!work.copy[key];
    const part = key.split(".").slice(1).join(".");
    const err = errLine(`copy.${key}`);
    const state = h("span", {});
    const reset = h("button", { type: "button", class: "btn small link", on: { click: () => {
      work = resetCopy(work, key);
      const fresh = copyRow(key);
      row.replaceWith(fresh);
      changed(`copy.${key}`);
      fresh.querySelector("input, textarea")?.focus();
    } } }, icon("undo", 14), "Reset to built-in");
    const mark = () => {
      put(state, has() ? chip("Changed", "brand") : chip("Built-in", "flat"));
      row.classList.toggle("builtin", !has());
      reset.disabled = !has();
    };
    const field = langField(`${PART[part] ?? part} · ${key}`, work.copy[key] ?? {}, {
      multiline: MULTI.test(key), max: null,
      onChange: (v) => { work = setCopy(work, key, v); mark(); changed(`copy.${key}`); },
    });
    const row = h("div", { class: `stack copy-row${has() ? "" : " builtin"}`, style: { gap: "6px" } }, field,
      hint ? h("span", { class: "small muted" }, "Built-in English: ", accent(hint)) : null,
      h("div", { class: "row", style: { gap: "8px", alignItems: "center", justifyContent: "space-between" } },
        h("div", { class: "row", style: { gap: "8px", alignItems: "center" } }, state, h("span", { class: "small muted num" }, `≤ ${maxFor(key)} characters`)), reset),
      err);
    mark();
    return row;
  }

  function copyCard() {
    const all = allErrs();
    return card("Copy", "Empty keeps the page’s own text in all three languages",
      h("span", { class: "small muted" }, "A change needs English, Arabic and Spanish. In titles, wrap a word in asterisks for the italic accent: “Start your *streak*” shows as “Start your ", h("em", { class: "accent" }, "streak"), "”. Nothing else is markup."),
      groupKeys(keys()).map(({ prefix, keys: ks }) => {
        const n = ks.filter((k) => work.copy[k]).length;
        const bad = ks.some((k) => errorsFor(all, `copy.${k}`).length);
        return h("details", { class: "copy-group", open: n > 0 || bad },
          h("summary", {}, h("span", { class: "strong" }, GROUP[prefix] ?? prefix),
            h("span", { class: "small muted" }, `${ks.length} text${ks.length === 1 ? "" : "s"}${n ? ` · ${n} changed` : ""}`), bad ? chip("Error", "bad") : null),
          h("div", { class: "grid two copy-grid" }, ks.map(copyRow)));
      }));
  }

  function faqCard() {
    const slot = h("div", { class: "stack", style: { gap: "12px" } });
    const draw = () => {
      const items = work.faq;
      const set = (next, base) => {
        work.faq = next;
        // Moving or removing shifts every index after it: their server errors no longer line up.
        serverErrs = serverErrs.filter((x) => !x.key.startsWith("faq."));
        draw();
        changed(base);
      };
      const add = h("button", { type: "button", class: "btn small", on: { click: () => set([...items, { q: { en: "", ar: "", es: "" }, a: { en: "", ar: "", es: "" } }]) } }, icon("plus"), items.length ? "Add question" : "Write your own questions");
      put(slot,
        items.length
          ? items.map((it, i) => h("div", { class: "well stack faq-item", style: { gap: "10px" } },
              h("div", { class: "card-head" }, h("span", { class: "strong" }, `Question ${i + 1}`),
                h("div", { class: "pills" },
                  h("button", { type: "button", class: "btn small", disabled: i === 0, "aria-label": `Move question ${i + 1} up`, on: { click: () => set(moveItem(items, i, -1)) } }, "↑ Up"),
                  h("button", { type: "button", class: "btn small", disabled: i === items.length - 1, "aria-label": `Move question ${i + 1} down`, on: { click: () => set(moveItem(items, i, 1)) } }, "↓ Down"),
                  h("button", { type: "button", class: "btn small link", on: { click: () => set(items.filter((_, j) => j !== i)) } }, "Remove"))),
              langField("Question", it.q, { onChange: (v) => { it.q = v; changed(`faq.${i}.q`); } }), errLine(`faq.${i}.q`),
              langField("Answer", it.a, { multiline: true, onChange: (v) => { it.a = v; changed(`faq.${i}.a`); } }), errLine(`faq.${i}.a`)))
          : empty("The page’s seven built-in questions", "Account, offline use, what the AI sees, Health, Arabic, Pro’s price and deleting data. Writing your own replaces all seven."),
        h("div", { class: "row", style: { gap: "12px", alignItems: "center", flexWrap: "wrap" } }, add,
          items.length ? h("span", { class: "small muted" }, "Your list replaces the built-in seven. Remove every question to bring them back.") : null));
    };
    draw();
    return card("FAQ", "Each question and answer in all three languages · 300 characters", slot);
  }

  function historyCard() {
    return card("Version history", "Rollback publishes a copy as a new version",
      table([
        { label: "Version", class: "strong", cell: (r) => `v${r.version}` },
        { label: "Status", cell: (r) => statusChip(r.status) },
        { label: "By", cell: (r) => r.published_by ?? r.created_by },
        { label: "When", cell: (r) => relTime(r.published_at ?? r.created_at) },
        { label: "Note", cell: (r) => r.note ?? "" },
        { label: "", end: true, cell: (r) => (publisher && r.status === "archived" ? h("button", { type: "button", class: "btn small", on: { click: () => rollback(r) } }, "Roll back") : "") },
      ], data.history ?? [], { empty: empty("Nothing published yet", "gymcoapp.com shows its built-in page until a version is published.") }));
  }

  function draw() {
    lines.clear();
    put(body,
      h("div", { class: "grid two" }, sectionsCard(), betaCard()),
      h("div", { class: "grid two" }, pricesCard(), storesCard()),
      screensCard(),
      copyCard(),
      faqCard(),
      historyCard());
    drawHead();
  }

  // ---- actions
  function showDiff() {
    sheet("Changes from the live landing page", h("div", { class: "stack" }, diffView(cmp(live()), cmp(work))));
  }

  async function save(note) {
    try {
      await call("landing.save_draft", { body: cleanBody(work), note: note ?? null });
      return true;
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        serverErrs = e.body?.errors ?? [];
        draw();
        toast("Fix the highlighted values first", "bad");
      } else toast(errorText(e, "Couldn’t save the draft"), "bad");
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
      await call("landing.submit");
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
    if (!(await confirmDialog({ title: "Discard this draft?", body: "gymcoapp.com keeps what is published. The draft is archived and logged.", confirm: "Discard", danger: true }))) return;
    try {
      await call("landing.discard");
    } catch (e) {
      return toast(errorText(e, "Couldn’t discard the draft"), "bad");
    }
    toast("Draft discarded");
    await load();
  }

  async function publish() {
    const next = (data.history?.[0]?.version ?? 0) + (data.draft ? 0 : 1);
    const ok = await confirmDialog({
      title: `Publish landing page v${next}?`,
      body: h("div", { class: "stack" }, diffView(cmp(live()), cmp(work)),
        h("span", { class: "small muted" }, `gymcoapp.com applies it on the next visit, within a minute.${data.published ? ` v${data.published.version} stays available for rollback.` : ""}`)),
      confirm: "Publish",
    });
    if (!ok) return;
    if ((unsaved() || !data.draft) && !(await save())) return;
    try {
      const fresh = await call("landing.get");
      await call("landing.publish", { version: fresh.draft.version });
      toast(`Landing page v${fresh.draft.version} published`);
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        serverErrs = e.body?.errors ?? [];
        toast("The draft has errors", "bad");
        return draw();
      }
      toast(errorText(e, "Couldn’t publish"), "bad");
    }
    await load();
  }

  async function rollback(r) {
    const ok = await confirmDialog({
      title: `Roll back the landing page to v${r.version}?`,
      body: `v${data.published?.version ?? "?"} becomes archived and v${r.version}'s settings go out as a new version.${data.draft ? ` Your open draft v${data.draft.version} is archived first.` : ""} This is logged.`,
      confirm: "Roll back", danger: true,
    });
    if (!ok) return;
    try {
      await call("landing.rollback", { to_version: r.version });
    } catch (e) {
      return toast(errorText(e, "Couldn’t roll back"), "bad");
    }
    toast(`Rolled back to v${r.version}`);
    await load();
  }

  async function exportCsv() {
    try {
      const { csv } = await call("waitlist.export");
      const a = h("a", { href: URL.createObjectURL(new Blob([csv], { type: "text/csv" })), download: `gymco-waitlist-${new Date().toISOString().slice(0, 10)}.csv` });
      document.body.append(a);
      a.click();
      a.remove();
    } catch (e) {
      toast(errorText(e, "Export needs the Owner role"), "bad");
    }
  }

  await load();
  return { unsaved };
}
