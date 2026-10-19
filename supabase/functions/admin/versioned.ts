// Draft → in review → published, with a diff and one-click rollback, for
// anything that reaches phones: the remote config and each content pack.
// One editable draft per thing at a time; publishing archives the previous
// version; rollback publishes a copy of an earlier version as a new one.

import { can } from "./access.ts";
import { type Ctx, fail, ok, type Reply, type Route } from "./handler.ts";
import type { VersionedTable, VersionRow } from "./store.ts";

export interface Versioned {
  table: VersionedTable;
  section: string;
  /** Normalise and check a body; errors are shown next to their fields. Packs read other packs through ctx. */
  validate(body: unknown, kind: string | undefined, ctx: Ctx): Promise<{ ok: boolean; body: unknown; errors: { key: string; message: string }[] }>;
  /** Keys a non-owner changed that only the owner may change. */
  ownerKeys?(before: unknown, after: unknown): string[];
  checksum?(body: unknown): Promise<string>;
  /** Kinds this thing comes in (content packs); none for the config. */
  kinds?: readonly string[];
  /** The request field and column the kind is in; "kind" unless said otherwise (website pages use "page"). */
  kindField?: string;
  /** What a fresh draft starts from when nothing is published yet. */
  base(kind?: string): unknown;
}

export interface Change {
  key: string;
  before: unknown;
  after: unknown;
}

/** Leaf-level differences between two bodies, as dotted keys. */
export function diff(a: unknown, b: unknown, prefix = ""): Change[] {
  const isObj = (v: unknown) => v !== null && typeof v === "object" && !Array.isArray(v);
  if (isObj(a) && isObj(b)) {
    const keys = [...new Set([...Object.keys(a as object), ...Object.keys(b as object)])].sort();
    return keys.flatMap((k) => diff((a as any)[k], (b as any)[k], prefix ? `${prefix}.${k}` : k));
  }
  return JSON.stringify(a) === JSON.stringify(b) ? [] : [{ key: prefix, before: a ?? null, after: b ?? null }];
}

const meta = ({ body: _b, ...rest }: VersionRow) => rest;

export function versionedRoutes(prefix: string, v: Versioned): Record<string, Route> {
  const field = v.kindField ?? "kind";
  const kindOf = (body: Record<string, unknown>) => (v.kinds ? String(body[field] ?? "") : undefined);
  const withKind = (kind?: string) => (kind ? { [field]: kind } : {});
  const badKind = (kind?: string) => v.kinds && !v.kinds.includes(kind ?? "");
  const rows = (ctx: Ctx, kind?: string) => ctx.store.versions(v.table, kind);
  const live = (all: VersionRow[]) => all.find((r) => r.status === "published") ?? null;
  const editing = (all: VersionRow[]) => all.find((r) => r.status === "draft" || r.status === "in_review") ?? null;

  async function publish(ctx: Ctx, kind: string | undefined, row: VersionRow, all: VersionRow[], action: string): Promise<Reply> {
    const before = live(all);
    const check = await v.validate(row.body, kind, ctx);
    if (!check.ok) return fail(400, "invalid", { errors: check.errors });
    try {
      await ctx.store.publishVersion(v.table, row.version, ctx.admin.email, kind);
    } catch {
      return fail(409, "not_publishable");
    }
    const changes = diff(before?.body ?? v.base(kind), check.body);
    await ctx.audit({
      section: v.section, action, object_id: `${kind ? `${kind} ` : ""}v${row.version}`,
      before: before?.body ?? null, after: check.body, reason: row.note ?? null,
    });
    return ok({ version: row.version, diff: changes });
  }

  return {
    [`${prefix}.get`]: {
      cap: "read",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        if (badKind(kind)) return fail(400, "bad_kind");
        const all = await rows(ctx, kind);
        const pub = live(all);
        const draft = editing(all);
        return ok({
          base: v.base(kind),
          published: pub,
          draft,
          diff: draft ? diff(pub?.body ?? v.base(kind), draft.body) : [],
          history: all.slice(0, 30).map(meta),
        });
      },
    },

    [`${prefix}.save_draft`]: {
      cap: "draft",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        if (badKind(kind)) return fail(400, "bad_kind");
        const check = await v.validate(body.body, kind, ctx);
        if (!check.ok) return fail(400, "invalid", { errors: check.errors });
        const all = await rows(ctx, kind);
        const pub = live(all);
        const draft = editing(all);
        const compareTo = pub?.body ?? v.base(kind);
        // Owner keys are checked against the shared draft, so an editor can save
        // over the owner's draft changes but can't quietly undo them.
        const ownerOnly = v.ownerKeys?.(draft?.body ?? compareTo, check.body) ?? [];
        if (ownerOnly.length && !can(ctx.admin.role, "owner_keys")) return fail(403, "owner_keys", { keys: ownerOnly });
        const note = typeof body.note === "string" ? body.note.slice(0, 500) : null;
        const checksum = v.checksum ? await v.checksum(check.body) : undefined;
        if (draft) {
          await ctx.store.updateVersion(v.table, draft.version, { body: check.body, status: "draft", note, checksum, submitted_by: null }, kind);
        } else {
          const next = (all[0]?.version ?? 0) + 1;
          await ctx.store.insertVersion(v.table, {
            ...withKind(kind), version: next, status: "draft", body: check.body, note, created_by: ctx.admin.email,
            ...(checksum ? { checksum } : {}),
          });
        }
        await ctx.audit({ section: v.section, action: "save_draft", object_id: `${kind ? `${kind} ` : ""}v${draft?.version ?? (all[0]?.version ?? 0) + 1}`, before: draft?.body ?? compareTo, after: check.body, reason: note });
        return ok({ diff: diff(compareTo, check.body) });
      },
    },

    [`${prefix}.submit`]: {
      cap: "draft",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        if (badKind(kind)) return fail(400, "bad_kind");
        const draft = editing(await rows(ctx, kind));
        if (!draft || draft.status !== "draft") return fail(404, "no_draft");
        await ctx.store.updateVersion(v.table, draft.version, { status: "in_review", submitted_by: ctx.admin.email }, kind);
        await ctx.audit({ section: v.section, action: "submit", object_id: `${kind ? `${kind} ` : ""}v${draft.version}`, after: { status: "in_review" } });
        return ok();
      },
    },

    [`${prefix}.discard`]: {
      cap: "draft",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        if (badKind(kind)) return fail(400, "bad_kind");
        const draft = editing(await rows(ctx, kind));
        if (!draft) return fail(404, "no_draft");
        await ctx.store.updateVersion(v.table, draft.version, { status: "archived" }, kind);
        await ctx.audit({ section: v.section, action: "discard", object_id: `${kind ? `${kind} ` : ""}v${draft.version}`, before: draft.body, after: null });
        return ok();
      },
    },

    [`${prefix}.publish`]: {
      cap: "publish",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        // Without a kind the rows of every pack would match the version.
        if (badKind(kind)) return fail(400, "bad_kind");
        const all = await rows(ctx, kind);
        const row = all.find((r) => r.version === Number(body.version) && (r.status === "draft" || r.status === "in_review"));
        if (!row) return fail(404, "no_draft");
        return publish(ctx, kind, row, all, "publish");
      },
    },

    [`${prefix}.rollback`]: {
      cap: "publish",
      run: async (ctx, body) => {
        const kind = kindOf(body);
        if (badKind(kind)) return fail(400, "bad_kind");
        const all = await rows(ctx, kind);
        const from = all.find((r) => r.version === Number(body.to_version) && r.status !== "draft" && r.status !== "in_review");
        if (!from) return fail(404, "no_version");
        // Check first: an old version may no longer fit (a pack it uses changed),
        // and the open draft must survive a refused rollback.
        const check = await v.validate(from.body, kind, ctx);
        if (!check.ok) return fail(400, "invalid", { errors: check.errors });
        // A draft in progress would collide with the copy: archive it first.
        const draft = editing(all);
        if (draft) await ctx.store.updateVersion(v.table, draft.version, { status: "archived" }, kind);
        const next = (all[0]?.version ?? 0) + 1;
        const copy: VersionRow = {
          ...withKind(kind), version: next, status: "draft", body: from.body, note: `Rollback to v${from.version}`,
          created_by: ctx.admin.email, ...(from.checksum ? { checksum: from.checksum } : {}),
        };
        await ctx.store.insertVersion(v.table, copy);
        return publish(ctx, kind, copy, await rows(ctx, kind), "rollback");
      },
    },
  };
}
