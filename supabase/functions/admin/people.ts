// Overview numbers, account support, the team and the audit log.

import { can, type Role } from "./access.ts";
import { fail, ok, type Route } from "./handler.ts";

/** Why an admin opened or changed an account. Logged with every lookup and action. */
export const REASONS = ["support_ticket", "deletion_request", "abuse", "test"] as const;
const isReason = (r: unknown) => typeof r === "string" && (REASONS as readonly string[]).includes(r);

/** Roles an owner can hand out. Ghassan stays the only owner. */
const GRANTABLE: Role[] = ["viewer", "support", "editor"];

const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");
const sameEmail = (a: string, b: string) => a.trim().toLowerCase() === b.trim().toLowerCase();

const SUPPORT_ACTS = new Set(["reset_cap", "grant_scans", "resend_code"]);
const DESTROY_ACTS = new Set(["delete_backup", "delete_account", "grant_plan", "revoke_plan"]);

export const peopleRoutes: Record<string, Route> = {
  stats: {
    cap: "read",
    run: async (ctx, body) => {
      const range = [7, 30, 90].includes(Number(body.range)) ? Number(body.range) : 30;
      return ok(await ctx.store.stats(range));
    },
  },

  "account.lookup": {
    cap: "support",
    run: async (ctx, body) => {
      const email = str(body.email).toLowerCase();
      if (!email.includes("@")) return fail(400, "email_required");
      if (!isReason(body.reason)) return fail(400, "reason_required");
      const card = await ctx.store.accountCard(email);
      // Audited whether or not an account matched: looking is the act.
      await ctx.audit({ section: "accounts", action: "lookup", object_id: card?.user_id ?? email, reason: String(body.reason) });
      return card ? ok(card) : fail(404, "no_account");
    },
  },

  "account.action": {
    cap: "support",
    run: async (ctx, body) => {
      const act = str(body.act);
      const uid = str(body.user_id);
      if (!SUPPORT_ACTS.has(act) && !DESTROY_ACTS.has(act)) return fail(400, "unknown_act");
      if (DESTROY_ACTS.has(act) && !can(ctx.admin.role, "destroy")) return fail(403, "forbidden");
      if (!isReason(body.reason)) return fail(400, "reason_required");
      const reason = String(body.reason);
      const email = await ctx.store.userEmail(uid);
      if (!email) return fail(404, "no_account");
      const log = (before: unknown, after: unknown) =>
        ctx.audit({ section: "accounts", action: act, object_id: uid, before, after, reason });

      switch (act) {
        case "reset_cap":
          await ctx.store.resetCap(uid);
          await log(null, { scans_today: 0 });
          return ok();
        case "grant_scans": {
          const extra = Number(body.extra);
          if (!Number.isInteger(extra) || extra < 1 || extra > 100) return fail(400, "extra_out_of_range");
          await ctx.store.grantScans(uid, extra);
          await log(null, { extra_today: extra });
          return ok();
        }
        case "resend_code":
          await ctx.store.sendCode(email);
          await log(null, { code_sent: true });
          return ok();
        case "delete_backup":
        case "delete_account": {
          if (!sameEmail(str(body.confirm_email), email)) return fail(400, "confirm_mismatch");
          if (act === "delete_backup") {
            const had = await ctx.store.deleteBackup(uid);
            await log({ backup: had }, { backup: false });
          } else {
            await ctx.store.deleteUser(uid);
            await ctx.store.noteDeletion();
            await log({ account: true }, { account: false });
          }
          return ok();
        }
        case "grant_plan": {
          const plan = body.plan === "lifetime" ? "lifetime" : body.plan === "pro" ? "pro" : null;
          if (!plan) return fail(400, "plan_required");
          const expires = str(body.expires_at) || null;
          if (expires && Number.isNaN(Date.parse(expires))) return fail(400, "bad_date");
          const before = await ctx.store.setEntitlement(uid, plan, expires, ctx.admin.email);
          await log(before, { plan, source: "manual", expires_at: expires });
          return ok();
        }
        default: {
          const before = await ctx.store.clearEntitlement(uid);
          await log(before, null);
          return ok();
        }
      }
    },
  },

  "note.add": {
    cap: "support",
    run: async (ctx, body) => {
      const note = str(body.note);
      if (note.length < 1 || note.length > 2000) return fail(400, "note_length");
      const uid = str(body.user_id);
      if (!(await ctx.store.userEmail(uid))) return fail(404, "no_account");
      await ctx.store.addNote(uid, ctx.admin.email, note);
      await ctx.audit({ section: "accounts", action: "note", object_id: uid, after: { note } });
      return ok();
    },
  },

  "team.list": {
    cap: "read",
    run: async (ctx) => ok({ admins: await ctx.store.team() }),
  },

  "team.invite": {
    cap: "team",
    run: async (ctx, body) => {
      const email = str(body.email).toLowerCase();
      const role = body.role as Role;
      if (!email.includes("@")) return fail(400, "email_required");
      if (!GRANTABLE.includes(role)) return fail(400, "bad_role");
      const uid = (await ctx.store.userIdByEmail(email)) ?? (await ctx.store.createUser(email));
      const before = await ctx.store.adminRow(uid);
      if (before?.role === "owner") return fail(400, "last_owner");
      await ctx.store.upsertAdmin({ user_id: uid, email, role, invited_by: ctx.admin.email });
      await ctx.audit({ section: "team", action: "invite", object_id: email, before, after: { email, role } });
      return ok();
    },
  },

  "team.set_role": {
    cap: "team",
    run: async (ctx, body) => {
      const uid = str(body.user_id);
      const role = body.role as Role;
      const target = await ctx.store.adminRow(uid);
      if (!target) return fail(404, "no_admin");
      if (target.role === "owner" && (await ctx.store.ownerCount()) <= 1) return fail(400, "last_owner");
      if (!GRANTABLE.includes(role)) return fail(400, "bad_role");
      await ctx.store.setRole(uid, role);
      await ctx.audit({ section: "team", action: "set_role", object_id: target.email, before: { role: target.role }, after: { role } });
      return ok();
    },
  },

  "team.remove": {
    cap: "team",
    run: async (ctx, body) => {
      const uid = str(body.user_id);
      const target = await ctx.store.adminRow(uid);
      if (!target) return fail(404, "no_admin");
      if (target.role === "owner" && (await ctx.store.ownerCount()) <= 1) return fail(400, "last_owner");
      await ctx.store.removeAdmin(uid);
      await ctx.audit({ section: "team", action: "remove", object_id: target.email, before: { role: target.role }, after: null });
      return ok();
    },
  },

  "audit.list": {
    cap: "read",
    run: async (ctx, body) =>
      ok({
        entries: await ctx.store.auditList({
          section: str(body.section) || undefined,
          q: str(body.q) || undefined,
          before_id: Number(body.before_id) || undefined,
          limit: Number(body.limit) || 50,
        }),
      }),
  },

  "plans.grants": {
    cap: "support",
    run: async (ctx) => ok({ grants: await ctx.store.manualGrants() }),
  },

  "audit.export": {
    cap: "audit_export",
    run: async (ctx) => {
      const rows = await ctx.store.auditList({ limit: 500 });
      await ctx.audit({ section: "team", action: "audit_export", after: { rows: rows.length } });
      return ok({ csv: toCsv(rows) });
    },
  },
};

const cell = (v: unknown) => {
  const s = v == null ? "" : typeof v === "string" ? v : JSON.stringify(v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export function toCsv(rows: object[]): string {
  const cols = ["at", "admin_email", "section", "action", "object_id", "reason", "before", "after"];
  return ["at,admin,section,action,object,reason,before,after", ...rows.map((r) => cols.map((c) => cell((r as Record<string, unknown>)[c])).join(","))].join("\n");
}
