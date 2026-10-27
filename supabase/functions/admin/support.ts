// The support inbox: tickets from the app, email or added by hand, with
// replies by email when Resend is set up and a mailto link when it isn't.

import { TEMPLATES } from "../_shared/support_templates.ts";
import { daysLeft, deletionDeadline, mailtoFor, parseTicket } from "../_shared/tickets.ts";
import { fail, ok, type Route } from "./handler.ts";
import type { Services } from "./services.ts";
import type { TicketRow, TicketTab } from "./store.ts";

const SECTION = "support";
const TABS: TicketTab[] = ["new", "waiting", "solved", "deletion", "feature"];
const STATUSES = ["new", "waiting", "solved"] as const;
const idOf = (v: unknown) => (Number.isInteger(Number(v)) && Number(v) > 0 ? Number(v) : null);
const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");

export function supportRoutes(s: Services): Record<string, Route> {
  const find = async (ctx: Parameters<Route["run"]>[0], id: unknown) => {
    const n = idOf(id);
    return n ? await ctx.store.ticket(n) : null;
  };

  return {
    "tickets.list": {
      cap: "support",
      run: async (ctx, body) => {
        const tab = TABS.includes(body.tab as TicketTab) ? (body.tab as TicketTab) : null;
        if (!tab) return fail(400, "bad_tab");
        const rows = await ctx.store.tickets(tab, str(body.q) || undefined);
        // Deletion requests: the nearest (or most overdue) deadline first.
        if (tab === "deletion") rows.sort((a, b) => (a.deadline_at ?? "9").localeCompare(b.deadline_at ?? "9"));
        const emails = [...new Set(rows.map((r) => r.email))];
        const accounts = new Map(await Promise.all(emails.map(async (e) => [e, !!(await ctx.store.userIdByEmail(e))] as const)));
        const items = rows.map(({ body: _b, ...r }) => ({ ...r, has_account: accounts.get(r.email) ?? false }));
        return ok({ items, counts: await ctx.store.ticketCounts() });
      },
    },

    "tickets.get": {
      cap: "support",
      run: async (ctx, body) => {
        const t = await find(ctx, body.id);
        if (!t) return fail(404, "no_ticket");
        const messages = (await ctx.store.ticketMessages(t.id!)).map((m) => ({ id: m.id, from_admin: m.from_admin, author: m.author, body: m.body, at: m.at }));
        const has_account = !!(await ctx.store.userIdByEmail(t.email));
        return ok({ ticket: { ...t, has_account }, messages, days_left: daysLeft(t.deadline_at, s.now()) });
      },
    },

    "tickets.add": {
      cap: "support",
      run: async (ctx, body) => {
        const check = parseTicket(body);
        if (!check.ok) return fail(400, "invalid", { errors: check.errors });
        const row: TicketRow = {
          ...check.row, status: "new", tags: check.row.kind === "feature" ? ["feature"] : [], source: "admin",
          deadline_at: check.row.kind === "deletion" ? deletionDeadline(s.now()) : null,
        };
        const id = await ctx.store.insertTicket(row);
        await ctx.audit({ section: SECTION, action: "ticket_add", object_id: String(id), after: { email: row.email, subject: row.subject, kind: row.kind } });
        return ok({ id });
      },
    },

    "tickets.reply": {
      cap: "support",
      run: async (ctx, body) => {
        const t = await find(ctx, body.id);
        if (!t) return fail(404, "no_ticket");
        const text = str(body.body);
        if (text.length < 1 || text.length > 5000) return fail(400, "body_length");
        const status = body.status === "solved" ? "solved" : body.status === "waiting" ? "waiting" : null;
        if (body.status != null && !status) return fail(400, "bad_status");
        // Stored and the status moved whether or not the email goes out.
        await ctx.store.insertMessage({ ticket_id: t.id!, from_admin: true, author: ctx.admin.email, body: text });
        await ctx.store.updateTicket(t.id!, { status: status ?? "waiting" });
        const subject = `Re: ${t.subject}`;
        const send = s.email();
        let sent = false;
        let error: string | undefined;
        if (send) {
          try {
            await send({ to: t.email, subject, text });
            sent = true;
          } catch (e) {
            error = (e as Error).message;
          }
        }
        await ctx.audit({ section: SECTION, action: "ticket_reply", object_id: String(t.id), before: { status: t.status }, after: { status: status ?? "waiting", sent } });
        return sent ? ok({ sent: true }) : ok({ sent: false, mailto: mailtoFor(t.email, t.subject, text), ...(error ? { error } : {}) });
      },
    },

    "tickets.set_status": {
      cap: "support",
      run: async (ctx, body) => {
        const t = await find(ctx, body.id);
        if (!t) return fail(404, "no_ticket");
        const status = STATUSES.find((x) => x === body.status);
        if (!status) return fail(400, "bad_status");
        await ctx.store.updateTicket(t.id!, { status });
        await ctx.audit({ section: SECTION, action: "ticket_status", object_id: String(t.id), before: { status: t.status }, after: { status } });
        return ok();
      },
    },

    "tickets.tag": {
      cap: "support",
      run: async (ctx, body) => {
        const t = await find(ctx, body.id);
        if (!t) return fail(404, "no_ticket");
        const raw = Array.isArray(body.tags) ? body.tags : null;
        const tags = raw?.map((x) => str(x)).filter(Boolean) ?? [];
        if (!raw || tags.length > 5 || tags.some((x) => x.length > 20)) return fail(400, "bad_tags");
        await ctx.store.updateTicket(t.id!, { tags });
        await ctx.audit({ section: SECTION, action: "ticket_tag", object_id: String(t.id), before: { tags: t.tags }, after: { tags } });
        return ok();
      },
    },

    "tickets.templates": {
      cap: "support",
      run: () => Promise.resolve(ok({ templates: TEMPLATES })),
    },
  };
}
