// 03 Accounts: find one account by exact email, see sizes and dates (never
// contents), and act on it. Every lookup and action is audited with a reason.

import { ApiError } from "../lib/api.js";
import { h, icon } from "../lib/dom.js";
import { dayLabel, fmtBytes, fmtInt, relTime } from "../lib/format.js";
import { can } from "../lib/roles.js";
import { chip, confirmDialog, empty, pageHead } from "../lib/ui.js";

export const REASONS = [["support_ticket", "Support ticket"], ["deletion_request", "Deletion request"], ["abuse", "Abuse"], ["test", "Test"]];
const LANG = { en: "English", ar: "Arabic", es: "Spanish" };
const PLATFORM = { ios: "iOS", android: "Android" };

export async function render(el, { call, params, toast, me }) {
  const email = h("input", { class: "input", type: "email", id: "lookup-email", value: params.email ?? "", required: true, autocomplete: "off" });
  const reason = h("select", { class: "input", id: "lookup-reason" }, REASONS.map(([v, t]) => h("option", { value: v }, t)));
  const result = h("div", { class: "stack", style: { gap: "16px" } });
  const form = h("form", { class: "card form", on: { submit: (e) => { e.preventDefault(); lookup(); } } },
    h("label", { class: "field wide" }, h("span", {}, "Exact email"), email),
    h("label", { class: "field" }, h("span", {}, "Reason (logged)"), reason),
    h("button", { type: "submit", class: "btn primary" }, "Look up"),
    h("p", { class: "small muted", style: { flexBasis: "100%", margin: "0" } }, "No browse-all list. Opening an account writes an audit entry with your reason."));

  el.append(pageHead("People", "accounts", "Your", null, { emFirst: true }), form, result);

  async function lookup() {
    const v = email.value.trim();
    if (!v.includes("@")) return toast("Enter the exact email", "bad");
    result.replaceChildren(h("div", { class: "skel", style: { height: "320px", borderRadius: "24px" } }));
    try {
      const card = await call("account.lookup", { email: v, reason: reason.value });
      result.replaceChildren(cardView(card));
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) {
        result.replaceChildren(h("div", { class: "card" }, empty(`No account for ${v}`, "Gymco accounts are optional, so many people never make one. The lookup was still logged.")));
      } else throw e;
    }
  }

  function cardView(c) {
    const b = c.backup;
    const scansNote = c.scans_today >= c.cap_today ? "At cap" : `${c.cap_today - c.scans_today} left`;
    const facts = [
      ["Last backup", b ? relTime(b.updated_at) : "None", b ? new Date(b.updated_at).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "Backup is off or never ran"],
      ["Backup size", b ? fmtBytes(b.bytes) : "—", "Contents never shown"],
      ["AI scans today", `${c.scans_today} / ${c.cap_today}`, c.grant_today ? `${scansNote} · +${c.grant_today} granted` : scansNote],
      ["Scans · 30 d", fmtInt(c.scans_30d), "Photo, Write, Eating out"],
    ];
    const plan = c.entitlement ? `${c.entitlement.plan === "lifetime" ? "Lifetime" : "Pro"} · ${c.entitlement.source}` : "Free · testing unlock";
    const meta = [`Created ${dayLabel(c.created_at)}`, b?.platform ? PLATFORM[b.platform] : null, b?.app_version ? `v${b.app_version}` : null, b?.locale ? LANG[b.locale] : null].filter(Boolean).join(" · ");
    const note = h("textarea", { class: "input", rows: "2", id: "note", maxlength: "2000" });
    const act = (label, cls, fn, cap = "support") => (can(me.role, cap) ? h("button", { type: "button", class: `btn ${cls}`, on: { click: fn } }, label) : null);
    const run = async (body, done) => {
      try {
        await call("account.action", { user_id: c.user_id, reason: reason.value, ...body });
        toast(done);
        lookup();
      } catch (e) {
        toast(e.code === "confirm_mismatch" ? "The email didn't match" : `Couldn't do that (${e.code})`, "bad");
      }
    };

    return h("section", { class: "row" },
      h("div", { class: "card grow" },
        h("div", { class: "card-head" },
          h("div", { style: { display: "flex", gap: "12px", alignItems: "center" } },
            h("span", { class: "icon-btn", "aria-hidden": "true", style: { cursor: "default" } }, c.email[0].toUpperCase()),
            h("div", {}, h("div", { style: { fontWeight: "700", fontSize: "16px" } }, c.email), h("div", { class: "small muted" }, meta))),
          h("div", { class: "pills" }, chip(plan, "brand"), c.is_admin ? chip("Admin", "warn") : null)),
        h("div", { class: "grid", style: { gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: "12px" } },
          facts.map(([l, v, n]) => h("div", { class: "well stack", style: { gap: "4px" } },
            h("span", { class: "small muted", style: { fontWeight: "600" } }, l), h("span", { class: "num", style: { fontSize: "20px", fontWeight: "700" } }, v), h("span", { class: "small muted" }, n)))),
        h("div", { class: "stack" }, h("span", { class: "small muted", style: { fontWeight: "600" } }, "Consent records"),
          h("span", { class: "small muted" }, "Consents are kept on the phone with the diary. The server only knows the account exists" + (b ? " and that backup is on." : "."))),
        h("div", { class: "lock-note" }, icon("lock"), "Diary, backup content, photos and Health data stay on the phone. This card shows size and dates only.")),
      h("div", { class: "side-col" },
        h("div", { class: "card", style: { gap: "10px" } },
          h("h2", {}, "Actions"),
          act("Reset today's scan cap", "primary", () => run({ act: "reset_cap" }, "Scan cap reset for today")),
          act("Grant extra scans for today", "", async () => {
            const n = h("input", { class: "input", type: "number", min: "1", max: "100", value: "5", id: "extra" });
            const ok = await confirmDialog({ title: "Extra scans for today", body: "Added to today's allowance only. Tomorrow is back to normal.", confirm: "Grant", field: h("label", { class: "field" }, h("span", {}, "How many (1–100)"), n) });
            if (ok) run({ act: "grant_scans", extra: Number(n.value) }, `${n.value} extra scans granted`);
          }),
          act("Resend sign-in code", "", () => run({ act: "resend_code" }, "Sign-in code sent")),
          act("Grant Pro or Lifetime…", "", async () => {
            const p = h("select", { class: "input" }, h("option", { value: "pro" }, "Pro"), h("option", { value: "lifetime" }, "Lifetime"));
            const until = h("input", { class: "input", type: "date" });
            const ok = await confirmDialog({ title: "Grant a plan", body: "For testers, refunds or press. Leave the date empty for no end.", confirm: "Grant",
              field: h("div", { class: "stack" }, h("label", { class: "field" }, h("span", {}, "Plan"), p), h("label", { class: "field" }, h("span", {}, "Ends (optional)"), until)) });
            if (ok) run({ act: "grant_plan", plan: p.value, expires_at: until.value ? `${until.value}T23:59:59Z` : null }, "Plan granted");
          }, "destroy"),
          c.entitlement?.source === "manual" ? act("Remove the granted plan", "", () => run({ act: "revoke_plan" }, "Plan removed"), "destroy") : null,
          can(me.role, "destroy") ? h("div", { class: "rule" }) : null,
          act("Delete backup only", "danger", async () => {
            const typed = await confirmDialog({ title: "Delete this backup?", body: "The account stays. The phone keeps its diary; a new backup arrives the next time the app backs up.", confirm: "Delete backup", danger: true, typeToConfirm: c.email });
            if (typed) run({ act: "delete_backup", confirm_email: typed }, "Backup deleted");
          }, "destroy"),
          act("Delete account and backup", "danger solid", async () => {
            const typed = await confirmDialog({ title: "Delete the account and its backup?", body: "This can't be undone. The phone keeps its diary until the user deletes it there.", confirm: "Delete account", danger: true, typeToConfirm: c.email });
            if (typed) {
              try {
                await call("account.action", { user_id: c.user_id, reason: reason.value, act: "delete_account", confirm_email: typed });
                toast("Account deleted");
                result.replaceChildren(h("div", { class: "card" }, empty("Account deleted", "Its backup and scan counts went with it. The deletion is counted on the Overview.")));
              } catch (e) {
                toast(`Couldn't delete (${e.code})`, "bad");
              }
            }
          }, "destroy"),
          can(me.role, "destroy") ? h("span", { class: "small muted" }, "Deleting asks you to type the email to confirm.") : null),
        h("div", { class: "card", style: { gap: "12px" } },
          h("h2", {}, "Internal notes"),
          c.notes.length ? c.notes.map((n) => h("div", { class: "well" }, h("div", {}, n.note), h("div", { class: "small muted", style: { marginTop: "4px" } }, `${n.by.split("@")[0]} · ${dayLabel(n.at)}`))) : h("span", { class: "small muted" }, "No notes yet."),
          h("label", { class: "field" }, h("span", {}, "Add a note"), note),
          h("button", { type: "button", class: "btn small", on: { click: async () => {
            if (!note.value.trim()) return;
            await call("note.add", { user_id: c.user_id, note: note.value.trim() });
            toast("Note added");
            lookup();
          } } }, "Add note"))));
  }

  if (params.email) lookup();
}
