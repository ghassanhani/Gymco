// 11 Team & audit log: admins and their roles, and every change, append-only.

import { h, icon } from "../lib/dom.js";
import { errorText } from "../lib/errors.js";
import { relTime } from "../lib/format.js";
import { ROLE_LABEL } from "../lib/roles.js";
import { chip, confirmDialog, diffView, empty, pageHead, sheet, table } from "../lib/ui.js";

const SECTIONS = [["", "All sections"], ["accounts", "Accounts"], ["team", "Team"], ["config", "Remote config"], ["content", "Content"], ["plans", "Plans"], ["messaging", "Messaging"], ["support", "Support"], ["releases", "Releases"], ["website", "Website"]];

export async function render(el, { call, toast, me }) {
  const team = h("div", { class: "card" });
  const log = h("div", { class: "card" });
  el.append(pageHead("Admin", "& audit log", "Team"), team, log);

  async function drawTeam() {
    const { admins } = await call("team.list");
    const email = h("input", { class: "input", type: "email", id: "invite-email" });
    const role = h("select", { class: "input", id: "invite-role" }, ["viewer", "support", "editor"].map((r) => h("option", { value: r }, ROLE_LABEL[r])));
    team.replaceChildren(
      h("div", { class: "card-head" }, h("h2", {}, "Admins"), h("span", { class: "small muted" }, "Each role includes the one before it. Ghassan is the only Owner.")),
      table([
        { label: "Admin", class: "strong", cell: (a) => a.email },
        { label: "Role", cell: (a) => (a.role === "owner" ? chip("Owner", "brand") : roleSelect(a)) },
        { label: "Two-step", cell: (a) => (a.mfa ? chip("On", "good") : chip("Not set up", "warn")) },
        { label: "Last sign-in", cell: (a) => relTime(a.last_sign_in_at) },
        { label: "", end: true, cell: (a) => (a.role === "owner" ? "" : h("button", { type: "button", class: "btn small danger", on: { click: () => remove(a) } }, "Remove")) },
      ], admins),
      h("form", { class: "form", on: { submit: async (e) => {
        e.preventDefault();
        if (!email.value.includes("@")) return toast("Enter an email", "bad");
        const btn = e.submitter ?? e.target.querySelector("[type=submit]");
        btn.disabled = true;
        try {
          await call("team.invite", { email: email.value.trim(), role: role.value });
        } catch (err) {
          btn.disabled = false;
          return toast(errorText(err, `Couldn't add ${email.value.trim()}`), "bad");
        }
        toast(`${email.value.trim()} added as ${ROLE_LABEL[role.value]}`);
        drawTeam();
        drawLog();
      } } },
        h("label", { class: "field wide" }, h("span", {}, "Add an admin by email"), email),
        h("label", { class: "field" }, h("span", {}, "Role"), role),
        h("button", { type: "submit", class: "btn primary" }, icon("plus"), "Add"),
        h("p", { class: "small muted", style: { flexBasis: "100%", margin: "0" } }, "They sign in at gymcoapp.com/admin with an email code and set up an authenticator app on first sign-in.")));
  }

  function roleSelect(a) {
    const sel = h("select", { class: "input", style: { minHeight: "36px", width: "140px" }, "aria-label": `Role for ${a.email}` },
      ["viewer", "support", "editor"].map((r) => h("option", { value: r, selected: r === a.role }, ROLE_LABEL[r])));
    sel.addEventListener("change", async () => {
      sel.disabled = true;
      try {
        await call("team.set_role", { user_id: a.user_id, role: sel.value });
        a.role = sel.value;
        toast(`${a.email} is now ${ROLE_LABEL[sel.value]}`);
        drawLog();
      } catch (err) {
        // Show the role they still have.
        sel.value = a.role;
        toast(errorText(err, `Couldn't change ${a.email}'s role`), "bad");
      } finally {
        sel.disabled = false;
      }
    });
    return sel;
  }

  async function remove(a) {
    if (!(await confirmDialog({ title: `Remove ${a.email}?`, body: "They lose access at their next request. Their account stays.", confirm: "Remove", danger: true }))) return;
    try {
      await call("team.remove", { user_id: a.user_id });
    } catch (err) {
      return toast(errorText(err, `Couldn't remove ${a.email}`), "bad");
    }
    toast(`${a.email} removed`);
    drawTeam();
    drawLog();
  }

  let section = "";
  let q = "";
  async function drawLog() {
    const { entries } = await call("audit.list", { section, q, limit: 100 });
    const sectionSel = h("select", { class: "input", "aria-label": "Section", style: { width: "200px" } }, SECTIONS.map(([v, t]) => h("option", { value: v, selected: v === section }, t)));
    const search = h("input", { class: "input", type: "search", placeholder: "Search action, object or admin", value: q, "aria-label": "Search the audit log", style: { flex: "1 1 220px", width: "auto" } });
    sectionSel.addEventListener("change", () => { section = sectionSel.value; drawLog(); });
    search.addEventListener("change", () => { q = search.value.trim(); drawLog(); });
    log.replaceChildren(
      h("div", { class: "card-head" }, h("h2", {}, "Audit log · append-only · kept 2 years"),
        h("button", { type: "button", class: "btn small", on: { click: exportCsv } }, icon("download"), "Export CSV")),
      h("div", { class: "pills" }, sectionSel, search),
      table([
        { label: "When", cell: (r) => new Date(r.at).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) },
        { label: "Admin", cell: (r) => r.admin_email },
        { label: "Section", cell: (r) => r.section },
        { label: "Action", class: "strong", cell: (r) => r.action },
        { label: "Object", cell: (r) => h("span", { class: "mono" }, r.object_id ?? "") },
        { label: "Reason", cell: (r) => r.reason ?? "" },
      ], entries, {
        onRow: (r) => sheet(`${r.action} · ${r.section}`, h("div", { class: "stack" },
          h("div", { class: "muted small" }, `${r.admin_email} · ${new Date(r.at).toLocaleString()}${r.reason ? ` · reason: ${r.reason}` : ""}`),
          h("h3", {}, "Before → after"), diffView(r.before ?? {}, r.after ?? {}))),
        empty: empty("Nothing logged yet", "Lookups, account actions, team changes and every publish show up here."),
      }));
  }

  async function exportCsv() {
    try {
      const { csv } = await call("audit.export");
      const a = h("a", { href: URL.createObjectURL(new Blob([csv], { type: "text/csv" })), download: `gymco-audit-${new Date().toISOString().slice(0, 10)}.csv` });
      document.body.append(a);
      a.click();
      a.remove();
    } catch {
      toast("Export needs the Owner role", "bad");
    }
  }

  await Promise.all([drawTeam(), drawLog()]);
  void me;
}
