// An in-memory Store for the tests. Behaves like the database where the
// rules depend on it; nothing else.

import type { Role } from "./access.ts";
import type {
  AdminRow, AnnouncementRow, AuditEntry, AuditQuery, CampaignRow, ManualGrant, MessageRow, ReleaseNoteRow, Store,
  TicketCounts, TicketRow, TicketTab, VersionedTable, VersionRow, WaitlistRow,
} from "./store.ts";
import { kindColumn } from "./store.ts";

/** A token with the given assurance level (the handler only reads `aal`). */
export const token = (aal: "aal1" | "aal2") => `h.${btoa(JSON.stringify({ aal })).replace(/=+$/, "")}.s`;

export class FakeStore implements Store {
  admins = new Map<string, AdminRow>();
  users = new Map<string, { id: string; email: string }>();
  backups = new Set<string>();
  grants = new Map<string, number>();
  capsReset: string[] = [];
  entitlements = new Map<string, { plan: "pro" | "lifetime"; source: "store" | "manual"; expires_at: string | null; granted_by: string | null; at: string }>();
  notes: { uid: string; note: string }[] = [];
  audit: (AuditEntry & { id: number })[] = [];
  codesSent: string[] = [];
  deletionsCounted = 0;
  calls: string[] = [];
  extra: Record<string, unknown> = {};
  configs: VersionRow[] = [];
  packs: VersionRow[] = [];
  pages: VersionRow[] = [];
  landing: VersionRow[] = [];
  waitlist: WaitlistRow[] = [];
  announcementRows: AnnouncementRow[] = [];
  campaignRows: CampaignRow[] = [];
  ticketRows: TicketRow[] = [];
  messages: MessageRow[] = [];
  releaseNoteRows: ReleaseNoteRow[] = [];
  fnCalls: { fn: string; calls: number; errors: number }[] = [];
  tokens = 0;
  now = () => new Date();

  private rows(table: VersionedTable) {
    return table === "remote_config" ? this.configs : table === "website_pages" ? this.pages : table === "site_landing" ? this.landing : this.packs;
  }
  private kindOf(table: VersionedTable, r: VersionRow) {
    return r[kindColumn(table)];
  }
  versions(table: VersionedTable, kind?: string) {
    return Promise.resolve(this.rows(table).filter((r) => !kind || this.kindOf(table, r) === kind).map((r) => ({ ...r })).sort((a, b) => b.version - a.version));
  }
  insertVersion(table: VersionedTable, row: VersionRow) {
    this.rows(table).push({ ...row });
    return Promise.resolve();
  }
  updateVersion(table: VersionedTable, version: number, patch: Partial<VersionRow>, kind?: string) {
    const r = this.rows(table).find((x) => x.version === version && (!kind || this.kindOf(table, x) === kind));
    if (r) Object.assign(r, patch);
    return Promise.resolve();
  }
  publishVersion(table: VersionedTable, version: number, by: string, kind?: string) {
    const rows = this.rows(table).filter((x) => !kind || this.kindOf(table, x) === kind);
    const target = rows.find((x) => x.version === version && (x.status === "draft" || x.status === "in_review"));
    if (!target) return Promise.reject(new Error("not_publishable"));
    for (const r of rows) if (r.status === "published") r.status = "archived";
    Object.assign(target, { status: "published", published_by: by });
    return Promise.resolve();
  }

  adminRow(uid: string) {
    return Promise.resolve(this.admins.get(uid) ?? null);
  }
  stats(range: number): Promise<unknown> {
    return Promise.resolve({ range });
  }
  accountCard(email: string) {
    const u = [...this.users.values()].find((x) => x.email === email.trim().toLowerCase());
    return Promise.resolve(u ? { user_id: u.id, email: u.email } : null);
  }
  userEmail(uid: string) {
    return Promise.resolve(this.users.get(uid)?.email ?? null);
  }
  resetCap(uid: string) {
    this.capsReset.push(uid);
    return Promise.resolve();
  }
  grantScans(uid: string, extra: number) {
    this.grants.set(uid, extra);
    return Promise.resolve();
  }
  deleteBackup(uid: string) {
    return Promise.resolve(this.backups.delete(uid));
  }
  deleteUser(uid: string) {
    this.users.delete(uid);
    return Promise.resolve();
  }
  noteDeletion() {
    this.deletionsCounted++;
    return Promise.resolve();
  }
  sendCode(email: string) {
    this.codesSent.push(email);
    return Promise.resolve();
  }
  setEntitlement(uid: string, plan: "pro" | "lifetime", expiresAt: string | null, by: string) {
    const before = this.entitlements.get(uid) ?? null;
    this.entitlements.set(uid, { plan, source: "manual", expires_at: expiresAt, granted_by: by, at: new Date().toISOString() });
    return Promise.resolve(before);
  }
  clearEntitlement(uid: string) {
    const before = this.entitlements.get(uid) ?? null;
    this.entitlements.delete(uid);
    return Promise.resolve(before);
  }
  manualGrants() {
    const out: ManualGrant[] = [...this.entitlements].filter(([, e]) => e.source === "manual").map(([uid, e]) => ({
      user_id: uid, email: this.users.get(uid)?.email ?? null, plan: e.plan, expires_at: e.expires_at, granted_at: e.at, granted_by: e.granted_by,
    }));
    return Promise.resolve(out);
  }
  addNote(uid: string, _by: string, note: string) {
    this.notes.push({ uid, note });
    return Promise.resolve();
  }
  team() {
    return Promise.resolve([...this.admins.values()]);
  }
  userIdByEmail(email: string) {
    return Promise.resolve([...this.users.values()].find((u) => u.email === email)?.id ?? null);
  }
  createUser(email: string) {
    const id = `u-${this.users.size + 1}-${email}`;
    this.users.set(id, { id, email });
    return Promise.resolve(id);
  }
  upsertAdmin(row: AdminRow) {
    this.admins.set(row.user_id, row);
    return Promise.resolve();
  }
  setRole(uid: string, role: Role) {
    const a = this.admins.get(uid);
    if (a) a.role = role;
    return Promise.resolve();
  }
  removeAdmin(uid: string) {
    this.admins.delete(uid);
    return Promise.resolve();
  }
  ownerCount() {
    return Promise.resolve([...this.admins.values()].filter((a) => a.role === "owner").length);
  }
  appendAudit(entry: AuditEntry) {
    this.audit.push({ ...entry, id: this.audit.length + 1, at: new Date().toISOString() });
    return Promise.resolve();
  }
  auditList(q: AuditQuery) {
    return Promise.resolve(
      [...this.audit].reverse().filter((e) => !q.section || e.section === q.section).slice(0, q.limit ?? 50),
    );
  }
  noteCall(fn: string) {
    this.calls.push(fn);
    return Promise.resolve();
  }

  private nextId(rows: { id?: number }[]) {
    return rows.reduce((m, r) => Math.max(m, r.id ?? 0), 0) + 1;
  }
  announcements() {
    return Promise.resolve([...this.announcementRows].reverse().map((r) => ({ ...r })));
  }
  insertAnnouncement(row: AnnouncementRow) {
    const id = this.nextId(this.announcementRows);
    this.announcementRows.push({ ...row, id, created_at: this.now().toISOString(), published_by: row.published_by ?? null });
    return Promise.resolve(id);
  }
  updateAnnouncement(id: number, patch: Partial<AnnouncementRow>) {
    const r = this.announcementRows.find((x) => x.id === id);
    if (r) Object.assign(r, patch);
    return Promise.resolve();
  }
  campaigns() {
    return Promise.resolve([...this.campaignRows].reverse().map((r) => ({ ...r })));
  }
  insertCampaign(row: CampaignRow) {
    const id = this.nextId(this.campaignRows);
    this.campaignRows.push({ sent_count: 0, ...row, id, created_at: this.now().toISOString() });
    return Promise.resolve(id);
  }
  updateCampaign(id: number, patch: Partial<CampaignRow>) {
    const r = this.campaignRows.find((x) => x.id === id);
    if (r) Object.assign(r, patch);
    return Promise.resolve();
  }
  tickets(tab: TicketTab, q?: string) {
    const needle = (q ?? "").toLowerCase();
    const hit = (t: TicketRow) => !needle || t.email.toLowerCase().includes(needle) || t.subject.toLowerCase().includes(needle);
    const inTab = (t: TicketRow) => tab === "deletion" || tab === "feature" ? t.kind === tab : t.status === tab && t.kind !== "feature";
    const rows = this.ticketRows.filter((t) => inTab(t) && hit(t));
    const sorted = tab === "deletion"
      ? rows.sort((a, b) => (a.deadline_at ?? "9").localeCompare(b.deadline_at ?? "9"))
      : rows.sort((a, b) => (b.created_at ?? "").localeCompare(a.created_at ?? "") || (b.id ?? 0) - (a.id ?? 0));
    return Promise.resolve(sorted.map(({ body: _b, ...rest }) => ({ ...rest })));
  }
  ticket(id: number) {
    const r = this.ticketRows.find((x) => x.id === id);
    return Promise.resolve(r ? { ...r } : null);
  }
  insertTicket(row: TicketRow) {
    const id = this.nextId(this.ticketRows);
    const at = this.now().toISOString();
    this.ticketRows.push({ ...row, id, created_at: row.created_at ?? at, updated_at: at });
    return Promise.resolve(id);
  }
  updateTicket(id: number, patch: Partial<TicketRow>) {
    const r = this.ticketRows.find((x) => x.id === id);
    if (r) Object.assign(r, patch, { updated_at: this.now().toISOString() });
    return Promise.resolve();
  }
  ticketMessages(id: number) {
    return Promise.resolve(this.messages.filter((m) => m.ticket_id === id).map((m) => ({ ...m })));
  }
  insertMessage(row: MessageRow) {
    const id = this.nextId(this.messages);
    this.messages.push({ ...row, id, at: this.now().toISOString() });
    return Promise.resolve(id);
  }
  ticketCounts() {
    const t = this.ticketRows;
    const now = this.now().toISOString();
    const inbox = t.filter((x) => x.kind !== "feature");
    const open = t.filter((x) => x.kind === "deletion" && x.status !== "solved");
    const counts: TicketCounts = {
      new: inbox.filter((x) => x.status === "new").length,
      waiting: inbox.filter((x) => x.status === "waiting").length,
      solved: inbox.filter((x) => x.status === "solved").length,
      deletion_open: open.length,
      overdue: open.filter((x) => x.deadline_at && x.deadline_at < now).length,
      feature_open: t.filter((x) => x.kind === "feature" && x.status !== "solved").length,
    };
    return Promise.resolve(counts);
  }
  releaseNotes() {
    return Promise.resolve([...this.releaseNoteRows].sort((a, b) => b.build - a.build).map((r) => ({ ...r })));
  }
  upsertReleaseNote(row: ReleaseNoteRow) {
    const cur = this.releaseNoteRows.find((x) => x.build === row.build);
    if (cur) Object.assign(cur, { version: row.version, body: row.body });
    else this.releaseNoteRows.push({ ...row, created_at: this.now().toISOString(), published_at: null });
    return Promise.resolve();
  }
  publishReleaseNote(build: number) {
    const cur = this.releaseNoteRows.find((x) => x.build === build);
    if (cur) Object.assign(cur, { published: true, published_at: this.now().toISOString() });
    return Promise.resolve(!!cur);
  }
  fnCalls24h() {
    return Promise.resolve(this.fnCalls.map((r) => ({ ...r })));
  }
  pushTokenCount() {
    return Promise.resolve(this.tokens);
  }
  waitlistStats() {
    const since = this.now().getTime() - 7 * 86_400_000;
    return Promise.resolve({ count: this.waitlist.length, last_7d: this.waitlist.filter((w) => Date.parse(w.created_at) >= since).length });
  }
  waitlistRows() {
    return Promise.resolve([...this.waitlist].sort((a, b) => b.created_at.localeCompare(a.created_at)).map((w) => ({ ...w })));
  }
  /** Files put in the "site" bucket, by path. */
  siteFiles = new Map<string, { bytes: Uint8Array; contentType: string }>();
  uploadSiteImage(path: string, bytes: Uint8Array, contentType: string) {
    this.siteFiles.set(path, { bytes, contentType });
    return Promise.resolve(`https://vncadogzpeoawikgafaj.supabase.co/storage/v1/object/public/site/${path}`);
  }
}
