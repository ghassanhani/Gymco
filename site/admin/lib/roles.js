// A copy of the server's role rules (supabase/functions/admin/access.ts),
// used only to decide what to show. The server still checks every request;
// a test keeps the two in step.

export const NEEDS = {
  read: "viewer",
  support: "support",
  destroy: "support",
  draft: "editor",
  publish: "owner",
  owner_keys: "owner",
  team: "owner",
  audit_export: "owner",
};

const RANK = { viewer: 0, support: 1, editor: 2, owner: 3 };

export const can = (role, cap) => role in RANK && RANK[role] >= RANK[NEEDS[cap]];

export const ROLE_LABEL = { viewer: "Viewer", support: "Support", editor: "Editor", owner: "Owner" };
