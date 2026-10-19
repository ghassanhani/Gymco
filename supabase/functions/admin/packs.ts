// Content packs: one versioned body per kind, edited on the dashboard and
// read by phones through app-config. Some rules span packs (a template can't
// use an exercise the exercises pack removes, and the other way round), so
// validation reads the other kind's published pack.

import { checksum, emptyPack, PACK_KINDS, type PackContext, summarize, validatePack } from "../_shared/packs.ts";
import { type Ctx, fail, ok, type Route } from "./handler.ts";
import type { VersionRow } from "./store.ts";
import { versionedRoutes } from "./versioned.ts";

const published = async (ctx: Ctx, kind: string) =>
  (await ctx.store.versions("content_packs", kind)).find((r) => r.status === "published")?.body as Record<string, any> | undefined;

/** The facts from the other pack that [kind]'s rules need. */
async function contextFor(ctx: Ctx, kind: string): Promise<PackContext> {
  if (kind === "exercises") {
    const templateExercises = new Map<string, string[]>();
    for (const t of (await published(ctx, "templates"))?.items ?? []) {
      const ids = new Set<string>((t.routines ?? []).flatMap((r: any) => (r.items ?? []).map((i: any) => i.exercise)));
      for (const id of ids) templateExercises.set(id, [...(templateExercises.get(id) ?? []), t.name?.en ?? t.id]);
    }
    return { templateExercises };
  }
  if (kind === "templates") return { removedExercises: new Set((await published(ctx, "exercises"))?.removed ?? []) };
  return {};
}

const check = async (ctx: Ctx, kind: string, body: unknown) => validatePack(kind, body, await contextFor(ctx, kind));

const routes = versionedRoutes("packs", {
  table: "content_packs",
  section: "content",
  kinds: PACK_KINDS,
  validate: (body, kind, ctx) => check(ctx, kind!, body),
  checksum,
  base: (kind) => emptyPack(kind),
});

const isKind = (k: unknown) => (PACK_KINDS as readonly unknown[]).includes(k);
const editing = (r: VersionRow) => r.status === "draft" || r.status === "in_review";

const get = routes["packs.get"];
export const packRoutes: Record<string, Route> = {
  ...routes,

  // The editor also sees the draft's warnings and where every kind stands.
  "packs.get": {
    cap: get.cap,
    run: async (ctx, body) => {
      const r = await get.run(ctx, body);
      if (r.status !== 200) return r;
      const draft = (r.body as { draft: VersionRow | null }).draft;
      const warnings = draft ? (await check(ctx, String(body.kind), draft.body)).warnings : [];
      const summary = await Promise.all(PACK_KINDS.map(async (kind) => {
        const all = await ctx.store.versions("content_packs", kind);
        const pub = all.find((x) => x.status === "published");
        const d = all.find(editing);
        return { kind, published_version: pub?.version ?? null, draft_status: d?.status ?? null, items: summarize(kind, (d ?? pub)?.body) };
      }));
      return ok({ ...(r.body as object), warnings, summary });
    },
  },

  "packs.check": {
    cap: "draft",
    run: async (ctx, body) => {
      if (!isKind(body.kind)) return fail(400, "bad_kind");
      const r = await check(ctx, String(body.kind), body.body);
      return ok({ ok: r.ok, errors: r.errors, warnings: r.warnings });
    },
  },
};
