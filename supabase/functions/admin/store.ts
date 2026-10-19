// Everything the admin actions read or write, behind one interface so the
// rules can be tested without a database (fake_store.ts) and the real calls
// live in one place (SupabaseStore).

import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import type { Role } from "./access.ts";

export interface AdminRow {
  user_id: string;
  email: string;
  role: Role;
  invited_by?: string;
}

export interface AuditEntry {
  admin_id: string;
  admin_email: string;
  section: string;
  action: string;
  object_id?: string | null;
  before?: unknown;
  after?: unknown;
  reason?: string | null;
  at?: string;
}

export interface AuditQuery {
  section?: string;
  q?: string;
  before_id?: number;
  limit?: number;
}

/** One version of something published to phones: the config, or a content pack. */
export interface VersionRow {
  kind?: string;
  version: number;
  status: "draft" | "in_review" | "published" | "archived";
  body: unknown;
  checksum?: string;
  note?: string | null;
  created_by: string;
  created_at?: string;
  submitted_by?: string | null;
  published_by?: string | null;
  published_at?: string | null;
}

/** A plan granted by hand from the dashboard, not bought in a store. */
export interface ManualGrant {
  user_id: string;
  email: string | null;
  plan: "pro" | "lifetime";
  expires_at: string | null;
  granted_at: string;
  granted_by: string | null;
}

export type VersionedTable = "remote_config" | "content_packs";

export interface Store {
  versions(table: VersionedTable, kind?: string): Promise<VersionRow[]>;
  insertVersion(table: VersionedTable, row: VersionRow): Promise<void>;
  updateVersion(table: VersionedTable, version: number, patch: Partial<VersionRow>, kind?: string): Promise<void>;
  publishVersion(table: VersionedTable, version: number, by: string, kind?: string): Promise<void>;
  adminRow(uid: string): Promise<AdminRow | null>;
  stats(range: number): Promise<unknown>;
  accountCard(email: string): Promise<{ user_id: string; email: string } & Record<string, unknown> | null>;
  userEmail(uid: string): Promise<string | null>;
  resetCap(uid: string): Promise<void>;
  grantScans(uid: string, extra: number): Promise<void>;
  deleteBackup(uid: string): Promise<boolean>;
  deleteUser(uid: string): Promise<void>;
  noteDeletion(): Promise<void>;
  sendCode(email: string): Promise<void>;
  setEntitlement(uid: string, plan: "pro" | "lifetime", expiresAt: string | null, by: string): Promise<unknown>;
  clearEntitlement(uid: string): Promise<unknown>;
  manualGrants(): Promise<ManualGrant[]>;
  addNote(uid: string, by: string, note: string): Promise<void>;
  team(): Promise<unknown[]>;
  userIdByEmail(email: string): Promise<string | null>;
  createUser(email: string): Promise<string>;
  upsertAdmin(row: AdminRow): Promise<void>;
  setRole(uid: string, role: Role): Promise<void>;
  removeAdmin(uid: string): Promise<void>;
  ownerCount(): Promise<number>;
  appendAudit(entry: AuditEntry): Promise<void>;
  auditList(q: AuditQuery): Promise<(AuditEntry & { id: number })[]>;
  noteCall(fn: string, ok: boolean): Promise<void>;
}

function must<T>(r: { data: T; error: unknown }): T {
  if (r.error) throw r.error;
  return r.data;
}

export class SupabaseStore implements Store {
  constructor(private db: SupabaseClient) {}

  async versions(table: VersionedTable, kind?: string) {
    let q = this.db.from(table).select("*").order("version", { ascending: false }).limit(100);
    if (kind) q = q.eq("kind", kind);
    return must(await q) as VersionRow[];
  }
  async insertVersion(table: VersionedTable, row: VersionRow) {
    must(await this.db.from(table).insert(row));
  }
  async updateVersion(table: VersionedTable, version: number, patch: Partial<VersionRow>, kind?: string) {
    let q = this.db.from(table).update(patch).eq("version", version);
    if (kind) q = q.eq("kind", kind);
    must(await q);
  }
  async publishVersion(table: VersionedTable, version: number, by: string, kind?: string) {
    must(await (table === "remote_config"
      ? this.db.rpc("publish_config", { v: version, by_email: by })
      : this.db.rpc("publish_pack", { pack_kind: kind, v: version, by_email: by })));
  }

  async adminRow(uid: string) {
    return must(await this.db.from("admins").select("user_id, email, role, invited_by").eq("user_id", uid).maybeSingle()) as AdminRow | null;
  }
  async stats(range: number) {
    return must(await this.db.rpc("admin_stats_range", { range_days: range }));
  }
  async accountCard(email: string) {
    return must(await this.db.rpc("admin_account_card", { lookup_email: email }));
  }
  async userEmail(uid: string) {
    const { data, error } = await this.db.auth.admin.getUserById(uid);
    if (error) return null;
    return data.user?.email ?? null;
  }
  async resetCap(uid: string) {
    const today = new Date().toISOString().slice(0, 10);
    must(await this.db.from("ai_usage").delete().eq("user_id", uid).eq("day", today));
  }
  async grantScans(uid: string, extra: number) {
    const today = new Date().toISOString().slice(0, 10);
    must(await this.db.from("ai_grants").upsert({ user_id: uid, day: today, extra }));
  }
  async deleteBackup(uid: string) {
    const rows = must(await this.db.from("backups").delete().eq("user_id", uid).select("user_id"));
    return (rows ?? []).length > 0;
  }
  async deleteUser(uid: string) {
    const { error } = await this.db.auth.admin.deleteUser(uid);
    if (error) throw error;
  }
  async noteDeletion() {
    await this.db.rpc("note_account_deletion");
  }
  async sendCode(email: string) {
    const { error } = await this.db.auth.signInWithOtp({ email, options: { shouldCreateUser: false } });
    if (error) throw error;
  }
  async setEntitlement(uid: string, plan: "pro" | "lifetime", expiresAt: string | null, by: string) {
    const before = must(await this.db.from("entitlements").select("*").eq("user_id", uid).maybeSingle());
    must(await this.db.from("entitlements").upsert({ user_id: uid, plan, source: "manual", expires_at: expiresAt, granted_by: by, at: new Date().toISOString() }));
    return before;
  }
  async clearEntitlement(uid: string) {
    const before = must(await this.db.from("entitlements").select("*").eq("user_id", uid).maybeSingle());
    must(await this.db.from("entitlements").delete().eq("user_id", uid).eq("source", "manual"));
    return before;
  }
  async manualGrants() {
    const rows = must(await this.db.from("entitlements").select("user_id, plan, expires_at, granted_by, at")
      .eq("source", "manual").order("at", { ascending: false }).limit(500)) as any[];
    // Few rows (grants are by hand), so one lookup each is fine.
    return Promise.all(rows.map(async (r) => ({
      user_id: r.user_id, email: await this.userEmail(r.user_id), plan: r.plan,
      expires_at: r.expires_at, granted_at: r.at, granted_by: r.granted_by,
    })));
  }
  async addNote(uid: string, by: string, note: string) {
    must(await this.db.from("account_notes").insert({ user_id: uid, admin_email: by, note }));
  }
  async team() {
    return must(await this.db.rpc("admin_team")) as unknown[];
  }
  async userIdByEmail(email: string) {
    return must(await this.db.rpc("admin_user_id", { lookup_email: email })) as string | null;
  }
  async createUser(email: string) {
    const { data, error } = await this.db.auth.admin.createUser({ email, email_confirm: true });
    if (error || !data.user) throw error ?? new Error("create user");
    return data.user.id;
  }
  async upsertAdmin(row: AdminRow) {
    must(await this.db.from("admins").upsert(row));
  }
  async setRole(uid: string, role: Role) {
    must(await this.db.from("admins").update({ role }).eq("user_id", uid));
  }
  async removeAdmin(uid: string) {
    must(await this.db.from("admins").delete().eq("user_id", uid));
  }
  async ownerCount() {
    const { count, error } = await this.db.from("admins").select("user_id", { count: "exact", head: true }).eq("role", "owner");
    if (error) throw error;
    return count ?? 0;
  }
  async appendAudit(entry: AuditEntry) {
    must(await this.db.from("audit_log").insert(entry));
  }
  async auditList(q: AuditQuery) {
    let query = this.db.from("audit_log").select("*").order("id", { ascending: false }).limit(Math.min(q.limit ?? 50, 500));
    if (q.section) query = query.eq("section", q.section);
    if (q.before_id) query = query.lt("id", q.before_id);
    if (q.q) query = query.or(`action.ilike.%${q.q.replace(/[%,()]/g, "")}%,object_id.ilike.%${q.q.replace(/[%,()]/g, "")}%,admin_email.ilike.%${q.q.replace(/[%,()]/g, "")}%`);
    return must(await query) as (AuditEntry & { id: number })[];
  }
  async noteCall(fn: string, ok: boolean) {
    await this.db.rpc("note_fn_call", { fn, ok });
  }
}
