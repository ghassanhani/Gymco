// The Control Center's one admin entry point: check who is asking, then run
// the action if their role allows it. Every write is audited by its action.

import { aalOf, can, type Capability, type Role } from "./access.ts";
import type { AdminRow, AuditEntry, Store } from "./store.ts";
import { peopleRoutes } from "./people.ts";

export interface Reply {
  status: number;
  body?: unknown;
}

export interface Ctx {
  admin: AdminRow;
  store: Store;
  audit(e: Omit<AuditEntry, "admin_id" | "admin_email">): Promise<void>;
}

export interface Route {
  cap: Capability;
  run(ctx: Ctx, body: Record<string, unknown>): Promise<Reply>;
}

export interface Deps {
  store: Store;
  verify(jwt: string): Promise<{ id: string; email?: string } | null>;
  routes?: Record<string, Route>;
}

export const ok = (body: unknown = { ok: true }): Reply => ({ status: 200, body });
export const fail = (status: number, error: string, extra: Record<string, unknown> = {}): Reply => ({
  status,
  body: { error, ...extra },
});

export const allRoutes: Record<string, Route> = {
  me: {
    cap: "read",
    run: (ctx) => Promise.resolve(ok({ email: ctx.admin.email, role: ctx.admin.role })),
  },
  ...peopleRoutes,
};

export async function handle(input: { jwt: string | null; body: unknown }, deps: Deps): Promise<Reply> {
  if (!input.jwt) return fail(401, "signed_out");
  const user = await deps.verify(input.jwt);
  if (!user) return fail(401, "signed_out");
  if (aalOf(input.jwt) !== "aal2") return fail(403, "mfa_required");
  const admin = await deps.store.adminRow(user.id);
  if (!admin) return fail(403, "not_admin");

  const body = (input.body && typeof input.body === "object" ? input.body : {}) as Record<string, unknown>;
  const route = (deps.routes ?? allRoutes)[String(body.action ?? "")];
  if (!route) return fail(400, "unknown_action");
  if (!can(admin.role as Role, route.cap)) return fail(403, "forbidden");

  const ctx: Ctx = {
    admin,
    store: deps.store,
    audit: (e) => deps.store.appendAudit({ ...e, admin_id: admin.user_id, admin_email: admin.email }),
  };
  return route.run(ctx, body);
}
