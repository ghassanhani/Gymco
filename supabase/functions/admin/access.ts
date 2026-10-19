// Who may do what in the Control Center. Four roles, each a superset of the
// one below it (the spec's matrix); the server checks every request.

export type Role = "viewer" | "support" | "editor" | "owner";

export type Capability =
  | "read" //          Overview, health, releases
  | "support" //       account lookup, notes, cap reset, extra scans, support inbox, audit list
  | "destroy" //       delete backup or account, manual plan grant (always with a reason)
  | "draft" //         draft content, copy, config, announcements; submit for review
  | "publish" //       publish or roll back anything that reaches phones
  | "owner_keys" //    safety values, AI budget, force-update, pricing
  | "team" //          manage admins
  | "audit_export";

const rank: Record<Role, number> = { viewer: 0, support: 1, editor: 2, owner: 3 };

const needs: Record<Capability, Role> = {
  read: "viewer",
  support: "support",
  destroy: "support",
  draft: "editor",
  publish: "owner",
  owner_keys: "owner",
  team: "owner",
  audit_export: "owner",
};

export function can(role: Role, cap: Capability): boolean {
  return role in rank && rank[role] >= rank[needs[cap]];
}

/** Assurance level from an access token already verified by auth.getUser. */
export function aalOf(jwt: string): "aal1" | "aal2" {
  try {
    const part = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(part + "=".repeat((4 - (part.length % 4)) % 4)));
    return payload.aal === "aal2" ? "aal2" : "aal1";
  } catch {
    return "aal1";
  }
}

const origins = new Set(["https://gymcoapp.com", "http://localhost:8765"]);

export function corsHeaders(origin: string | null): Record<string, string> {
  const h: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    Vary: "Origin",
  };
  if (origin && origins.has(origin)) h["Access-Control-Allow-Origin"] = origin;
  return h;
}
