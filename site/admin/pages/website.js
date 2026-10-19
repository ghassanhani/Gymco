// 11 Website: gymcoapp.com pages as Markdown per language, drafted,
// reviewed and published like Remote config. Publishing commits to site/
// when the server has a GitHub token; otherwise the version is published
// here and the note says so.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { relTime } from "../lib/format.js";
import { countChanges } from "../lib/config_form.js";
import { renderMarkdown } from "../lib/markdown.js";
import { can } from "../lib/roles.js";
import { chip, confirmDialog, diffView, empty, LANGS, langField, pageHead, sheet, statusChip, table } from "../lib/ui.js";

const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const PAGES = [["home", "Home"], ["support", "Support"], ["privacy", "Privacy policy"], ["terms", "Terms"], ["delete-account", "Account deletion"]];
const pageName = (id) => PAGES.find(([k]) => k === id)?.[1] ?? id;
const ext = (href, label) => h("a", { href, target: "_blank", rel: "noopener", class: "small", style: { fontWeight: "600", display: "inline-flex", gap: "4px", alignItems: "center" } }, label, icon("ext", 14));

export async function render(el, { call, toast, me, params, isCurrent }) {
  const publisher = can(me.role, "publish");
  const page = PAGES.some(([k]) => k === params.page) ? params.page : "home";
  let data;
  let work;
  let lang = params.lang && ["en", "ar", "es"].includes(params.lang) ? params.lang : "en";
  let errs = [];
  let committedNote = null;

  const pills = h("div", { class: "pills", role: "group", "aria-label": "Pages" });
  const head = h("div", { class: "card config-head" });
  const editor = h("section", { class: "card" });
  const historyCard = h("section", { class: "card" });
  el.append(pageHead("Ship · gymcoapp.com via GitHub Pages", "Website", "pages"), pills, head, editor, historyCard);

  const live = () => data.published?.body ?? data.base;
  const unsaved = () => countChanges(data.draft?.body ?? live(), work) > 0;
  const changes = () => countChanges(live(), work);
  const summaryOf = (k) => (Array.isArray(data.summary) ? data.summary.find((s) => s.page === k) : data.summary?.[k]) ?? null;

  // The leave guard: the browser asks before a reload or close while edits are unsaved.
  const guard = (e) => {
    if (work && unsaved()) {
      e.preventDefault();
      e.returnValue = "";
    }
  };
  addEventListener("beforeunload", guard);
  const observer = new MutationObserver(() => { if (!el.isConnected) { removeEventListener("beforeunload", guard); observer.disconnect(); } });
  observer.observe(document.body, { childList: true, subtree: true });

  async function load() {
    data = await call("website.get", { page });
    if (!isCurrent()) return;
    work = structuredClone(data.draft?.body ?? data.published?.body ?? data.base);
    work.title = { en: "", ar: "", es: "", ...work.title };
    work.markdown = { en: "", ar: "", es: "", ...work.markdown };
    errs = [];
    drawPills();
    drawHead();
    drawEditor();
    drawHistory();
  }

  function drawPills() {
    put(pills, PAGES.map(([k, label]) => {
      const s = summaryOf(k);
      const meta = s ? `${s.published_version ? `v${s.published_version}` : "not published"}${s.draft_status ? ` · ${s.draft_status === "in_review" ? "in review" : "draft"}` : ""}` : null;
      return h("button", { type: "button", class: "pill pack-pill", "aria-pressed": String(k === page), title: meta, on: { click: () => go(k) } },
        label, meta ? h("span", { class: "pill-n" }, meta) : null, s?.draft_status ? h("span", { class: `pill-dot ${s.draft_status === "in_review" ? "warn" : ""}`, "aria-label": s.draft_status === "in_review" ? "In review" : "Draft" }) : null);
    }));
  }

  async function go(k) {
    if (k === page) return;
    if (unsaved() && !(await confirmDialog({ title: "Leave this page?", body: `Your Markdown edits to ${pageName(page)} aren’t saved as a draft yet.`, confirm: "Leave", danger: true }))) return;
    location.hash = `#/website?page=${k}`;
  }

  function drawHead() {
    const draft = data.draft;
    const pubV = data.published?.version ?? 0;
    const n = changes();
    const review = draft?.status === "in_review";
    const title = `${pageName(page)} · ${draft ? `v${draft.version} ${review ? "in review" : "draft"}` : unsaved() ? "unsaved draft" : pubV ? `published v${pubV}` : "nothing drafted yet"}`;
    const sub = pubV ? `${n} change${n === 1 ? "" : "s"} from published v${pubV} · updated ${work.updated ?? "—"}` : "Nothing drafted yet: the live page stays as it is until a version is published.";
    put(head,
      h("div", { class: "stack", style: { gap: "4px", flex: "1 1 280px" } },
        h("div", { class: "row", style: { gap: "10px", alignItems: "center" } }, h("h2", {}, title), draft ? statusChip(draft.status) : null, unsaved() ? chip("Unsaved", "warn") : null),
        h("span", { class: "small muted" }, sub),
        review ? h("span", { class: "small" }, `Sent by ${draft.submitted_by ?? draft.created_by}${publisher ? " · approve to publish, or send it back with a note." : ". You can keep editing; saving again takes it back to draft."}`) : null,
        data.live ? h("div", { class: "pills" }, [["en_url", "Live EN"], ["ar_url", "Live AR"], ["es_url", "Live ES"]].map(([k, l]) => (data.live[k] ? ext(data.live[k], l) : null))) : null),
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small", disabled: !n, on: { click: showDiff } }, "View diff"),
        draft ? h("button", { type: "button", class: "btn small", on: { click: discard } }, "Discard draft") : null,
        review && publisher ? h("button", { type: "button", class: "btn small", on: { click: sendBack } }, "Send back") : null,
        h("button", { type: "button", class: "btn small", disabled: !unsaved(), on: { click: () => saveAndReload("Draft saved") } }, "Save draft"),
        publisher
          ? h("button", { type: "button", class: "btn small publish", disabled: !n && !draft, on: { click: publish } }, review ? "Approve & publish" : "Publish to site/")
          : h("button", { type: "button", class: "btn small primary", disabled: (!unsaved() && !draft) || (review && !unsaved()), on: { click: submit } }, review && !unsaved() ? "Sent to the Owner" : "Send for review")));
  }

  function errLine(key) {
    const msgs = errs.filter((x) => x.key === key || x.key?.startsWith(`${key}.`)).map((x) => x.message);
    return msgs.length ? h("span", { class: "field-err", role: "alert" }, [...new Set(msgs)].join(" · ")) : null;
  }

  function drawEditor() {
    const title = langField("Title", work.title, { max: 80, onChange: (v) => { work.title = v; drawHead(); preview.refresh(); } });
    const tabs = h("div", { class: "langtabs", role: "tablist", "aria-label": "Markdown language" });
    const md = h("textarea", { class: "input mono md-input", rows: "18", "aria-label": `Markdown (${lang.toUpperCase()})`, spellcheck: "false" });
    const preview = h("div", { class: "well md-preview" });
    preview.refresh = () => {
      preview.dir = lang === "ar" ? "rtl" : "ltr";
      preview.lang = lang;
      const text = work.markdown[lang];
      put(preview, h("span", { class: "small muted", dir: "ltr" }, `${pageName(page)} · ${lang.toUpperCase()}`),
        h("h1", { class: "md-title" }, work.title[lang]?.trim() || h("span", { class: "muted" }, `No ${lang.toUpperCase()} title`)),
        text.trim() ? renderMarkdown(text) : h("p", { class: "muted" }, "Nothing written in this language yet. The live page keeps what it has."));
    };
    const drawTabs = () => {
      md.value = work.markdown[lang];
      md.dir = lang === "ar" ? "rtl" : "ltr";
      md.lang = lang;
      put(tabs, LANGS.map(([k, t]) => h("button", { type: "button", role: "tab", "aria-selected": String(k === lang), class: work.markdown[k].trim() ? null : "missing", title: work.markdown[k].trim() ? null : "Missing", on: { click: () => { lang = k; drawTabs(); preview.refresh(); } } }, t)));
      preview.refresh();
    };
    md.addEventListener("input", () => {
      work.markdown[lang] = md.value;
      tabs.querySelectorAll("button").forEach((b, i) => b.classList.toggle("missing", !work.markdown[LANGS[i][0]].trim()));
      preview.refresh();
      drawHead();
    });
    drawTabs();
    put(editor,
      committedNote ? h("div", { class: "banner info", role: "status" }, h("div", {}, h("b", {}, committedNote)), h("button", { type: "button", class: "btn small", on: { click: () => { committedNote = null; drawEditor(); } } }, "OK")) : null,
      title, errLine("title"),
      h("div", { class: "grid two md-grid" },
        h("div", { class: "stack", style: { gap: "6px" } }, h("div", { class: "card-head" }, h("span", { class: "small muted strong" }, "Markdown"), tabs), md, errLine("markdown"),
          h("span", { class: "small muted" }, "Headings with #, lists with -, **bold**, *italic*, [links](https://…). Raw HTML stays as text.")),
        h("div", { class: "stack", style: { gap: "6px" } }, h("span", { class: "small muted strong" }, "Preview"), preview)),
      h("span", { class: "small muted" }, "Published versions commit to site/ and GitHub Pages deploys them. Privacy and Terms keep their dated history; the app links to the current one."));
  }

  function drawHistory() {
    put(historyCard,
      h("div", { class: "card-head" }, h("h2", {}, "Version history"), h("span", { class: "small muted" }, "The app links to the current version · rollback publishes a copy")),
      table([
        { label: "Version", class: "strong", cell: (r) => `v${r.version}` },
        { label: "Status", cell: (r) => statusChip(r.status) },
        { label: "By", cell: (r) => r.published_by ?? r.created_by },
        { label: "When", cell: (r) => relTime(r.published_at ?? r.created_at) },
        { label: "Note", cell: (r) => r.note ?? "" },
        { label: "", end: true, cell: (r) => (publisher && r.status === "archived" ? h("button", { type: "button", class: "btn small", on: { click: () => rollback(r) } }, "Rollback") : "") },
      ], data.history ?? [], { empty: empty("Nothing published from here yet", "The live page stays as it is until a version is published.") }));
  }

  function showDiff() {
    sheet("Changes from the published page", h("div", { class: "stack" }, diffView(live(), work)));
  }

  async function save(note) {
    try {
      await call("website.save_draft", { page, body: work, note: note ?? null });
      return true;
    } catch (e) {
      if (e instanceof ApiError && e.code === "invalid") {
        errs = e.body?.errors ?? [];
        drawEditor();
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
      await call("website.submit", { page });
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
    if (!(await confirmDialog({ title: "Discard this draft?", body: "The live page keeps what is published. The draft is archived and logged.", confirm: "Discard", danger: true }))) return;
    await call("website.discard", { page });
    toast("Draft discarded");
    await load();
  }

  async function publish() {
    const next = (data.history?.[0]?.version ?? 0) + (data.draft ? 0 : 1);
    const ok = await confirmDialog({
      title: `Publish ${pageName(page)} v${next}?`,
      body: h("div", { class: "stack" }, diffView(live(), work),
        page === "privacy" || page === "terms" ? h("span", { class: "small", style: { color: "var(--warn)" } }, "If this changes what you collect, update the store privacy labels too.") : null,
        h("span", { class: "small muted" }, "Commits to site/ and GitHub Pages deploys it within a few minutes.")),
      confirm: "Publish",
    });
    if (!ok) return;
    if ((unsaved() || !data.draft) && !(await save())) return;
    const fresh = await call("website.get", { page });
    try {
      const r = await call("website.publish", { page, version: fresh.draft.version });
      committedNote = r?.committed === false ? "Published in the Control Center; add a GITHUB_TOKEN secret to push it to gymcoapp.com." : null;
      toast(`${pageName(page)} v${fresh.draft.version} published`);
    } catch (e) {
      toast(e instanceof ApiError && e.code === "invalid" ? "The draft has errors" : "Couldn’t publish", "bad");
    }
    await load();
  }

  async function rollback(r) {
    const ok = await confirmDialog({
      title: `Roll back ${pageName(page)} to v${r.version}?`,
      body: `v${data.published?.version ?? "?"} becomes archived and v${r.version} goes out as a new version. Any open draft is archived first. This is logged.`,
      confirm: "Roll back", danger: true,
    });
    if (!ok) return;
    try {
      const res = await call("website.rollback", { page, to_version: r.version });
      committedNote = res?.committed === false ? "Published in the Control Center; add a GITHUB_TOKEN secret to push it to gymcoapp.com." : null;
      toast(`Rolled back to v${r.version}`);
    } catch {
      toast("Couldn’t roll back", "bad");
    }
    await load();
  }

  await load();
}
