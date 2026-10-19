// Releases: the latest CI runs, which builds are out there, the version gate
// and release notes. The gate itself is edited through config.*.

import { checkT3 } from "../_shared/announcements.ts";
import { defaults } from "../_shared/config_schema.ts";
import { fail, ok, type Route } from "./handler.ts";
import type { Services } from "./services.ts";

const SECTION = "releases";
export const MIRROR = "iFynx/Gymco";

/** "1.2.0 (104)" → 104; anything without a build number stays as written. */
export function buildOf(appVersion: string): number | string {
  const m = /\((\d+)\)\s*$/.exec(appVersion);
  return m ? Number(m[1]) : appVersion;
}

/** The share of backups on each build, from the stats' app_version mix. */
export function versionShares(mix: Record<string, number> | undefined): { build: number | string; pct: number }[] {
  const byBuild = new Map<number | string, number>();
  for (const [v, n] of Object.entries(mix ?? {})) byBuild.set(buildOf(v), (byBuild.get(buildOf(v)) ?? 0) + n);
  const total = [...byBuild.values()].reduce((a, b) => a + b, 0);
  return [...byBuild].map(([build, n]) => ({ build, pct: total ? Math.round((n / total) * 1000) / 10 : 0 }))
    .sort((a, b) => b.pct - a.pct);
}

export function releaseRoutes(s: Services): Record<string, Route> {
  return {
    "releases.get": {
      cap: "read",
      run: async (ctx) => {
        const gh = s.github();
        const [runs, stats, config, notes] = await Promise.all([
          gh ? gh.latestRuns().catch(() => []) : Promise.resolve([]),
          ctx.store.stats(30) as Promise<any>,
          ctx.store.versions("remote_config"),
          ctx.store.releaseNotes(),
        ]);
        const live = (config.find((r) => r.status === "published")?.body as any)?.app_gate ?? {};
        const d = defaults().app_gate;
        return ok({
          runs,
          versions: versionShares(stats?.mix?.app_version),
          gate: {
            min_build_ios: live.min_build_ios ?? d.min_build_ios,
            min_build_android: live.min_build_android ?? d.min_build_android,
            recommended_build: live.recommended_build ?? d.recommended_build,
          },
          notes: notes.map((n) => ({ build: n.build, version: n.version, body: n.body, published: n.published })),
          github: !!gh,
          mirror: MIRROR,
        });
      },
    },

    "releases.rerun": {
      cap: "publish",
      run: async (ctx, body) => {
        const gh = s.github();
        if (!gh) return fail(503, "not_configured");
        const runId = Number(body.run_id);
        if (!Number.isInteger(runId) || runId <= 0) return fail(400, "bad_run");
        if (!(await gh.rerun(runId))) return fail(502, "github");
        await ctx.audit({ section: SECTION, action: "rerun", object_id: String(runId) });
        return ok();
      },
    },

    "releases.notes_save": {
      cap: "draft",
      run: async (ctx, body) => {
        const build = Number(body.build);
        const version = typeof body.version === "string" ? body.version.trim() : "";
        const text = checkT3(body.body, "body", 500);
        const errors = [...text.errors];
        if (!Number.isInteger(build) || build < 1 || build > 1_000_000) errors.unshift({ key: "build", message: "Enter the build number" });
        if (!version || version.length > 32) errors.unshift({ key: "version", message: "Enter the version, like 1.2.0" });
        if (errors.length) return fail(400, "invalid", { errors });
        const before = (await ctx.store.releaseNotes()).find((n) => n.build === build) ?? null;
        await ctx.store.upsertReleaseNote({ build, version, body: text.value, published: false, created_by: ctx.admin.email });
        await ctx.audit({ section: SECTION, action: "notes_save", object_id: String(build), before, after: { version, body: text.value } });
        return ok({ build });
      },
    },

    "releases.notes_publish": {
      cap: "publish",
      run: async (ctx, body) => {
        const build = Number(body.build);
        if (!(await ctx.store.publishReleaseNote(build))) return fail(404, "no_note");
        await ctx.audit({ section: SECTION, action: "notes_publish", object_id: String(build), after: { published: true } });
        return ok();
      },
    },
  };
}
