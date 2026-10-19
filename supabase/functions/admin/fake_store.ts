// An in-memory Store for the tests. Behaves like the database where the
// rules depend on it; nothing else.

import type { Role } from "./access.ts";
import type { AdminRow, AuditEntry, AuditQuery, Store } from "./store.ts";

/** A token with the given assurance level (the handler only reads `aal`). */
export const token = (aal: "aal1" | "aal2") => `h.${btoa(JSON.stringify({ aal })).replace(/=+$/, "")}.s`;

export class FakeStore implements Store {
  admins = new Map<string, AdminRow>();
  users = new Map<string, { id: string; email: string }>();
  backups = new Set<string>();
  grants = new Map<string, number>();
  capsReset: string[] = [];
  entitlements = new Map<string, unknown>();
  notes: { uid: string; note: string }[] = [];
  audit: (AuditEntry & { id: number })[] = [];
  codesSent: string[] = [];
  deletionsCounted = 0;
  calls: string[] = [];
  extra: Record<string, unknown> = {};

  adminRow(uid: string) {
    return Promise.resolve(this.admins.get(uid) ?? null);
  }
  stats(range: number) {
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
  setEntitlement(uid: string, plan: "pro" | "lifetime", expiresAt: string | null) {
    const before = this.entitlements.get(uid) ?? null;
    this.entitlements.set(uid, { plan, expiresAt });
    return Promise.resolve(before);
  }
  clearEntitlement(uid: string) {
    const before = this.entitlements.get(uid) ?? null;
    this.entitlements.delete(uid);
    return Promise.resolve(before);
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
}
