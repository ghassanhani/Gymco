// 10 Releases: the latest GitHub Actions runs, the build on TestFlight and
// Google Play, versions in use, the version gate (a Remote config change,
// published with a diff like Plans does) and What's New notes per build.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { relTime } from "../lib/format.js";
import { countChanges, setKey } from "../lib/config_form.js";
import { blockedPct, buildLabel, latestBuild, RUN_LABEL, RUN_TONE, toBullets, versionLabel } from "../lib/releases.js";
import { can } from "../lib/roles.js";
import { chip, confirmDialog, diffView, empty, langField, mixList, pageHead, statusChip, table } from "../lib/ui.js";

const put = (el, ...kids) => el.replaceChildren(...kids.flat().filter((k) => k != null && k !== false));
const ACTIONS_URL = "https://github.com/ghassanhani/Gymco/actions";
const GATE_KEYS = [["app_gate.min_build_ios", "Minimum build · iOS"], ["app_gate.min_build_android", "Minimum build · Android"], ["app_gate.recommended_build", "Recommended build"]];
const ext = (href, label) => h("a", { href, target: "_blank", rel: "noopener", class: "small", style: { fontWeight: "600", display: "inline-flex", gap: "4px", alignItems: "center" } }, label, icon("ext", 14));

export async function render(el, { call, toast, me, isCurrent }) {
  const publisher = can(me.role, "publish");
  const drafter = can(me.role, "draft");
  let data;
  let cfg = null;
  let gate = {};
  let noteBuild = null;
  const head = h("div");
  const stores = h("div", { class: "grid stores" });
  const runsCard = h("section", { class: "card" });
  const gateCard = h("section", { class: "card" });
  const notesCard = h("section", { class: "card" });
  el.append(head, stores, runsCard, h("div", { class: "grid two" }, gateCard, notesCard));

  async function load() {
    [data, cfg] = await Promise.all([call("releases.get"), drafter ? call("config.get").catch(() => null) : null]);
    if (!isCurrent()) return;
    gate = { ...data.gate, ...(cfg ? { min_build_ios: live().app_gate.min_build_ios, min_build_android: live().app_gate.min_build_android, recommended_build: live().app_gate.recommended_build } : {}) };
    noteBuild ??= data.notes?.[0]?.build ?? null;
    put(head, pageHead(`Ship · mirror: ${data.mirror ?? "iFynx/Gymco"}`, "Releases", "& builds",
      h("div", { class: "pills" }, ext(ACTIONS_URL, "Open in GitHub"), h("button", { type: "button", class: "btn small", on: { click: load } }, icon("refresh", 16), "Refresh"))));
    drawStores();
    drawRuns();
    drawGate();
    drawNotes();
  }

  const live = () => cfg?.published?.body ?? cfg?.base;

  function drawStores() {
    const latest = latestBuild(data.versions ?? []);
    // The newest build with a published note, or the newest seen in backups.
    const newest = (data.notes ?? []).find((n) => n.published);
    const label = newest?.build && (!latest || newest.build >= latest) ? buildLabel(newest.build, data.notes) : latest ? buildLabel(latest, data.notes) : "No build yet";
    const store = (name, sub, url, linkLabel) => h("section", { class: "card" },
      h("div", { class: "card-head" }, h("h2", {}, name), chip(sub, "flat")),
      h("div", { class: "plan-price num" }, label),
      h("span", { class: "small muted" }, latest ? `Newest build seen in backups: ${latest}` : "No build has reported from backups yet"),
      h("div", { class: "pills" }, ext(url, `Status in ${linkLabel}`)));
    put(stores,
      store("TestFlight", "iOS", "https://appstoreconnect.apple.com/apps", "App Store Connect"),
      store("Google Play · internal", "Android", "https://play.google.com/console", "Play Console"),
      h("section", { class: "card" },
        h("div", { class: "card-head" }, h("h2", {}, "Versions in use"), h("span", { class: "small muted" }, "Share of backups · 30 days")),
        mixList("Build", (data.versions ?? []).map((v) => ({ label: versionLabel(v, data.notes), pct: Math.round(Number(v.pct) || 0) }))),
        h("span", { class: "small muted" }, "From backup metadata only; phones without backup aren’t counted.")));
  }

  function drawRuns() {
    put(runsCard,
      h("div", { class: "card-head" }, h("h2", {}, "GitHub Actions"), h("span", { class: "small muted" }, "Latest run of each workflow")),
      data.github
        ? table([
            { label: "Workflow", class: "strong", cell: (r) => r.name },
            { label: "Commit", cell: (r) => h("span", { class: "mono" }, r.sha7 ?? "") },
            { label: "Status", cell: (r) => chip(RUN_LABEL[r.status] ?? r.status, RUN_TONE[r.status] ?? "flat") },
            { label: "When", cell: (r) => relTime(r.when) },
            { label: "", end: true, cell: (r) => h("div", { class: "pills", style: { justifyContent: "flex-end" } },
              r.url ? ext(r.url, "View log") : null,
              publisher ? h("button", { type: "button", class: "btn small", on: { click: () => rerun(r) } }, "Re-run") : null) },
          ], data.runs ?? [], { empty: empty("No runs yet", "Workflow runs appear after the first push.") })
        : empty("Add a GITHUB_TOKEN secret to see runs here", "Re-run works once the token is set. Until then, open the runs on GitHub.", h("div", { class: "pills" }, ext(ACTIONS_URL, "Open in GitHub"))));
  }

  async function rerun(r) {
    if (!(await confirmDialog({ title: `Re-run “${r.name}”?`, body: `Starts the workflow again on ${r.sha7}. A release run can upload a new build.`, confirm: "Re-run" }))) return;
    try {
      await call("releases.rerun", { run_id: r.id });
      toast(`${r.name} queued`);
      load();
    } catch (e) {
      toast(e instanceof ApiError && e.code === "not_configured" ? "Add a GITHUB_TOKEN secret first" : "Couldn’t re-run it", "bad");
    }
  }

  // ---- version gate: three Remote config keys, published with a diff
  function drawGate() {
    const work = { ...gate };
    const pct = () => blockedPct(data.versions ?? [], Math.max(Number(work.min_build_ios) || 0, Number(work.min_build_android) || 0));
    const line = h("span", { class: "small", role: "status" });
    const refresh = () => {
      const n = pct();
      line.textContent = `A hard block stops ${n}% of devices still on older builds.`;
      line.style.color = n > 20 ? "var(--critical)" : n > 0 ? "var(--warn)" : "var(--text-3)";
    };
    const inputs = GATE_KEYS.map(([path, label]) => {
      const k = path.split(".")[1];
      const i = h("input", { class: "input num", type: "number", min: "0", max: "100000", step: "1", value: String(work[k] ?? 0), "aria-label": label, disabled: !drafter || !cfg });
      i.addEventListener("input", () => { work[k] = Number(i.value); refresh(); });
      return h("label", { class: "field" }, h("span", {}, label), i);
    });
    refresh();
    const changed = () => GATE_KEYS.some(([p]) => Number(work[p.split(".")[1]]) !== Number(gate[p.split(".")[1]]));
    put(gateCard,
      h("div", { class: "card-head" }, h("h2", {}, "Version gate"), h("span", { class: "small muted" }, "Builds under the minimum see a hard block; under recommended, a soft prompt")),
      h("div", { class: "form" }, inputs),
      line,
      cfg?.draft ? h("span", { class: "small", style: { color: "var(--warn)" } }, `Draft v${cfg.draft.version} in Remote config is open; the gate change goes out with it.`) : null,
      h("div", { class: "pills" },
        drafter && cfg
          ? publisher
            ? h("button", { type: "button", class: "btn small publish", on: { click: () => (changed() ? publishGate(work) : toast("Nothing changed")) } }, "Publish gate")
            : h("button", { type: "button", class: "btn small primary", on: { click: () => (changed() ? saveGate(work) : toast("Nothing changed")) } }, "Save to Remote config draft")
          : h("span", { class: "small muted" }, drafter ? "Remote config didn’t load; the gate shows the server’s values." : "Changing the gate needs the Editor role.")),
      h("span", { class: "small muted" }, "These are app_gate keys in Remote config. Rollback lives there."));
  }

  const nextBody = (work) => GATE_KEYS.reduce((b, [p]) => setKey(b, p, Number(work[p.split(".")[1]]) || 0), cfg.draft?.body ?? live());

  async function saveGate(work) {
    try {
      await call("config.save_draft", { body: nextBody(work), note: "Version gate" });
      toast("Saved to the Remote config draft · send it for review there");
      load();
    } catch (e) {
      toast(e instanceof ApiError && e.code === "owner_keys" ? "Only the Owner can change the gate" : "Couldn’t save the draft", "bad");
    }
  }

  async function publishGate(work) {
    const next = nextBody(work);
    const others = cfg.draft ? countChanges(live(), cfg.draft.body) : 0;
    const n = blockedPct(data.versions ?? [], Math.max(Number(work.min_build_ios) || 0, Number(work.min_build_android) || 0));
    const ok = await confirmDialog({
      title: "Publish the version gate?",
      body: h("div", { class: "stack" }, diffView(live(), next),
        h("span", { class: "small", style: { color: n ? "var(--warn)" : "var(--text-3)" } }, `A hard block stops ${n}% of devices still on older builds.`),
        others ? h("span", { class: "small", style: { color: "var(--warn)" } }, `Draft v${cfg.draft.version} in Remote config has ${others} other change${others === 1 ? "" : "s"}; ${others === 1 ? "it goes" : "they go"} out with this.`) : null,
        h("span", { class: "small muted" }, "This publishes a new Remote config version. Phones pick it up on next launch or within 6 h.")),
      confirm: "Publish",
    });
    if (!ok) return;
    try {
      await call("config.save_draft", { body: next, note: "Version gate" });
      const fresh = await call("config.get");
      await call("config.publish", { version: fresh.draft.version });
      toast(`Version gate published · v${fresh.draft.version}`);
    } catch (e) {
      toast(e instanceof ApiError && e.code === "owner_keys" ? "Only the Owner can change the gate" : "Couldn’t publish the gate", "bad");
    }
    load();
  }

  // ---- What's New per build
  function drawNotes() {
    const notes = data.notes ?? [];
    const cur = notes.find((n) => n.build === noteBuild) ?? null;
    const work = cur ? structuredClone(cur) : { build: (latestBuild(data.versions ?? []) ?? 100) + 1, version: "", body: { en: "", ar: "", es: "" }, published: false };
    const pick = h("select", { class: "input", "aria-label": "Build" },
      notes.map((n) => h("option", { value: String(n.build), selected: n.build === noteBuild }, `${n.version} (${n.build})${n.published ? "" : " · draft"}`)),
      h("option", { value: "new", selected: !cur }, "New note…"));
    pick.addEventListener("change", () => { noteBuild = pick.value === "new" ? null : Number(pick.value); drawNotes(); });
    const build = h("input", { class: "input num", type: "number", min: "1", value: String(work.build), "aria-label": "Build number", disabled: !!cur, on: { input: () => { work.build = Number(build.value); } } });
    const version = h("input", { class: "input", placeholder: "1.0.3", value: work.version ?? "", "aria-label": "Version", on: { input: () => { work.version = version.value.trim(); } } });
    const bodyF = langField("What’s New · one bullet per line", work.body, { multiline: true, max: 500, onChange: (v) => { work.body = v; drawBullets(); } });
    const bullets = h("ul", { class: "bullets" });
    const drawBullets = () => put(bullets, toBullets(work.body?.en).map((b) => h("li", {}, b)));
    drawBullets();
    put(notesCard,
      h("div", { class: "card-head" }, h("h2", {}, `What’s New${cur ? ` · ${cur.version}` : ""}`), cur ? statusChip(cur.published ? "published" : "draft") : chip("New", "flat")),
      h("div", { class: "form" }, h("label", { class: "field" }, h("span", {}, "Note for"), pick), h("label", { class: "field" }, h("span", {}, "Build"), build), h("label", { class: "field" }, h("span", {}, "Version"), version)),
      bodyF, bullets,
      h("div", { class: "pills" },
        h("button", { type: "button", class: "btn small primary", disabled: !drafter, on: { click: () => saveNote(work) } }, "Save"),
        publisher ? h("button", { type: "button", class: "btn small publish", disabled: !cur || cur.published, on: { click: () => publishNote(work) } }, cur?.published ? "Published" : "Publish") : null),
      h("span", { class: "small muted" }, "Phones on this build see the sheet once, from app-config, after the note is published."));
  }

  async function saveNote(work) {
    if (!work.build || !work.version) return toast("Build and version are needed", "bad");
    try {
      await call("releases.notes_save", { build: work.build, version: work.version, body: work.body });
      toast(`Note for ${work.version} saved`);
      noteBuild = work.build;
      load();
    } catch (e) {
      toast(e instanceof ApiError && e.code === "invalid" ? (e.body?.errors?.[0]?.message ?? "Every language needs text") : "Couldn’t save the note", "bad");
    }
  }

  async function publishNote(work) {
    if (!(await confirmDialog({ title: `Publish What’s New for ${work.version}?`, body: "Phones on this build show the sheet once on next launch.", confirm: "Publish" }))) return;
    try {
      await call("releases.notes_publish", { build: work.build });
      toast(`What’s New for ${work.version} published`);
      load();
    } catch (e) {
      toast(e instanceof ApiError && e.code === "invalid" ? "Every language needs text first" : "Couldn’t publish the note", "bad");
    }
  }

  await load();
}
