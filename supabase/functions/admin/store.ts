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
  /** website_pages names its kind "page". */
  page?: string;
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

export type VersionedTable = "remote_config" | "content_packs" | "website_pages" | "site_landing";

/** The column a table's kind lives in. */
export const kindColumn = (table: VersionedTable) => (table === "website_pages" ? "page" : "kind");

export interface AnnouncementRow {
  id?: number;
  title: unknown;
  body: unknown;
  cta: unknown;
  starts_at: string;
  ends_at: string;
  targeting: unknown;
  status: "draft" | "in_review" | "published" | "archived";
  created_by: string;
  created_at?: string;
  published_by?: string | null;
}

export interface CampaignRow {
  id?: number;
  title: unknown;
  body: unknown;
  send_at_local: string;
  targeting: unknown;
  status: "draft" | "scheduled" | "sent" | "cancelled";
  sent_count?: number;
  created_by: string;
  created_at?: string;
}

export interface TicketRow {
  id?: number;
  email: string;
  subject: string;
  body?: string;
  locale: string | null;
  app_version: string | null;
  platform: string | null;
  kind: "general" | "deletion";
  status: "new" | "waiting" | "solved";
  tags: string[];
  source: "app" | "email" | "admin";
  created_at?: string;
  updated_at?: string;
  deadline_at: string | null;
}

export interface MessageRow {
  id?: number;
  ticket_id: number;
  from_admin: boolean;
  author: string;
  body: string;
  at?: string;
}

export interface ReleaseNoteRow {
  build: number;
  version: string;
  body: unknown;
  published: boolean;
  created_by: string;
  created_at?: string;
  published_at?: string | null;
}

export interface TicketCounts {
  new: number;
  waiting: number;
  solved: number;
  deletion_open: number;
  overdue: number;
}

export type TicketTab = "new" | "waiting" | "solved" | "deletion";

/** One "Notify me" sign-up from the landing page. */
export interface WaitlistRow {
  email: string;
  locale: "en" | "ar" | "es";
  created_at: string;
}

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

  announcements(): Promise<AnnouncementRow[]>;
  insertAnnouncement(row: AnnouncementRow): Promise<number>;
  updateAnnouncement(id: number, patch: Partial<AnnouncementRow>): Promise<void>;
  campaigns(): Promise<CampaignRow[]>;
  insertCampaign(row: CampaignRow): Promise<number>;
  updateCampaign(id: number, patch: Partial<CampaignRow>): Promise<void>;
  /** Without bodies: a list never carries what people wrote. */
  tickets(tab: TicketTab, q?: string): Promise<TicketRow[]>;
  ticket(id: number): Promise<TicketRow | null>;
  insertTicket(row: TicketRow): Promise<number>;
  updateTicket(id: number, patch: Partial<TicketRow>): Promise<void>;
  ticketMessages(id: number): Promise<MessageRow[]>;
  insertMessage(row: MessageRow): Promise<number>;
  ticketCounts(): Promise<TicketCounts>;
  releaseNotes(): Promise<ReleaseNoteRow[]>;
  upsertReleaseNote(row: ReleaseNoteRow): Promise<void>;
  publishReleaseNote(build: number): Promise<boolean>;
  fnCalls24h(): Promise<{ fn: string; calls: number; errors: number }[]>;
  pushTokenCount(): Promise<number>;
  waitlistStats(): Promise<{ count: number; last_7d: number }>;
  /** Every sign-up, newest first. */
  waitlistRows(): Promise<WaitlistRow[]>;
}

function must<T>(r: { data: T; error: unknown }): T {
  if (r.error) throw r.error;
  return r.data;
}

export class SupabaseStore implements Store {
  constructor(private db: SupabaseClient) {}

  async versions(table: VersionedTable, kind?: string) {
    let q = this.db.from(table).select("*").order("version", { ascending: false }).limit(100);
    if (kind) q = q.eq(kindColumn(table), kind);
    return must(await q) as VersionRow[];
  }
  async insertVersion(table: VersionedTable, row: VersionRow) {
    must(await this.db.from(table).insert(row));
  }
  async updateVersion(table: VersionedTable, version: number, patch: Partial<VersionRow>, kind?: string) {
    let q = this.db.from(table).update(patch).eq("version", version);
    if (kind) q = q.eq(kindColumn(table), kind);
    must(await q);
  }
  async publishVersion(table: VersionedTable, version: number, by: string, kind?: string) {
    must(await (table === "remote_config"
      ? this.db.rpc("publish_config", { v: version, by_email: by })
      : table === "website_pages"
      ? this.db.rpc("publish_page", { page_name: kind, v: version, by_email: by })
      : table === "site_landing"
      ? this.db.rpc("publish_landing", { v: version, by_email: by })
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

  async announcements() {
    return must(await this.db.from("announcements").select("*").order("id", { ascending: false }).limit(200)) as AnnouncementRow[];
  }
  async insertAnnouncement(row: AnnouncementRow) {
    return (must(await this.db.from("announcements").insert(row).select("id").single()) as { id: number }).id;
  }
  async updateAnnouncement(id: number, patch: Partial<AnnouncementRow>) {
    must(await this.db.from("announcements").update(patch).eq("id", id));
  }
  async campaigns() {
    return must(await this.db.from("push_campaigns").select("*").order("id", { ascending: false }).limit(200)) as CampaignRow[];
  }
  async insertCampaign(row: CampaignRow) {
    return (must(await this.db.from("push_campaigns").insert(row).select("id").single()) as { id: number }).id;
  }
  async updateCampaign(id: number, patch: Partial<CampaignRow>) {
    must(await this.db.from("push_campaigns").update(patch).eq("id", id));
  }

  private static TICKET_COLS = "id, email, subject, locale, app_version, platform, kind, status, tags, source, created_at, updated_at, deadline_at";
  async tickets(tab: TicketTab, q?: string) {
    let query = this.db.from("support_tickets").select(SupabaseStore.TICKET_COLS).limit(200);
    query = tab === "deletion"
      ? query.eq("kind", "deletion").order("deadline_at", { ascending: true, nullsFirst: false })
      : query.eq("status", tab).order("created_at", { ascending: false }).order("id", { ascending: false });
    if (q) {
      const safe = q.replace(/[%,()]/g, "");
      query = query.or(`email.ilike.%${safe}%,subject.ilike.%${safe}%`);
    }
    return must(await query) as unknown as TicketRow[];
  }
  async ticket(id: number) {
    return must(await this.db.from("support_tickets").select("*").eq("id", id).maybeSingle()) as TicketRow | null;
  }
  async insertTicket(row: TicketRow) {
    return (must(await this.db.from("support_tickets").insert(row).select("id").single()) as { id: number }).id;
  }
  async updateTicket(id: number, patch: Partial<TicketRow>) {
    must(await this.db.from("support_tickets").update({ ...patch, updated_at: new Date().toISOString() }).eq("id", id));
  }
  async ticketMessages(id: number) {
    return must(await this.db.from("ticket_messages").select("*").eq("ticket_id", id).order("id", { ascending: true })) as MessageRow[];
  }
  async insertMessage(row: MessageRow) {
    return (must(await this.db.from("ticket_messages").insert(row).select("id").single()) as { id: number }).id;
  }
  async ticketCounts() {
    return must(await this.db.rpc("support_ticket_counts")) as TicketCounts;
  }

  async releaseNotes() {
    return must(await this.db.from("release_notes").select("*").order("build", { ascending: false }).limit(100)) as ReleaseNoteRow[];
  }
  async upsertReleaseNote(row: ReleaseNoteRow) {
    // A saved note keeps its published flag: re-saving corrects, publishing is its own step.
    const { published: _p, ...rest } = row;
    const cur = must(await this.db.from("release_notes").select("build").eq("build", row.build).maybeSingle());
    must(await (cur ? this.db.from("release_notes").update(rest).eq("build", row.build) : this.db.from("release_notes").insert(row)));
  }
  async publishReleaseNote(build: number) {
    const rows = must(await this.db.from("release_notes").update({ published: true, published_at: new Date().toISOString() }).eq("build", build).select("build"));
    return (rows ?? []).length > 0;
  }
  async fnCalls24h() {
    return must(await this.db.rpc("fn_calls_24h")) as { fn: string; calls: number; errors: number }[];
  }
  async pushTokenCount() {
    return must(await this.db.rpc("push_token_count")) as number;
  }
  async waitlistStats() {
    return must(await this.db.rpc("waitlist_stats")) as { count: number; last_7d: number };
  }
  async waitlistRows() {
    // PostgREST hands back at most 1000 rows a request, so read in pages.
    const out: WaitlistRow[] = [];
    for (let from = 0; from < 200_000; from += 1000) {
      const page = must(await this.db.from("landing_waitlist").select("email, locale, created_at")
        .order("created_at", { ascending: false }).order("email").range(from, from + 999)) as WaitlistRow[];
      out.push(...page);
      if (page.length < 1000) break;
    }
    return out;
  }
}
