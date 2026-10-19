// System health at a glance: function calls and errors over the last day,
// database and backup sizes, push tokens, the support queue, and the state
// of the services around the app.

import { ok, type Route } from "./handler.ts";
import type { Services } from "./services.ts";

type State = "ok" | "warn" | "bad" | "unknown";

export function healthRoutes(s: Services): Record<string, Route> {
  return {
    health: {
      cap: "read",
      run: async (ctx) => {
        const gh = s.github();
        const [calls, stats, tokens, tickets, runs] = await Promise.all([
          ctx.store.fnCalls24h(),
          ctx.store.stats(7) as Promise<any>,
          ctx.store.pushTokenCount(),
          ctx.store.ticketCounts(),
          gh ? gh.latestRuns().catch(() => []) : Promise.resolve([]),
        ]);
        const site = runs.find((r) => r.name === "Website");
        const ci = runs.find((r) => r.name === "CI");
        const pagesState: State = !site ? "unknown" : site.status === "passed" ? "ok" : site.status === "failed" ? "bad" : "warn";
        const fcm = s.fcmConfigured();
        return ok({
          functions: calls.map((c) => ({ ...c, rate: c.calls ? Math.round((c.errors / c.calls) * 10000) / 10000 : 0 })),
          db_bytes: stats?.db_bytes ?? null,
          backups: stats?.backups ?? { count: 0, bytes: 0 },
          tokens,
          tickets,
          crashlytics: false,
          services: [
            { name: "Auth email delivery", note: "Not tracked yet", state: "unknown" as State },
            { name: "ImprovMX forwarding", note: "support@gymcoapp.com → inbox", state: "ok" as State },
            {
              name: "GitHub Pages",
              note: site ? `Website workflow ${site.status} · ${site.when}` : gh ? "No Website run yet" : "GitHub not connected",
              state: pagesState,
            },
            { name: "Push (FCM)", note: fcm ? "Configured" : "Not set up", state: (fcm ? "ok" : "warn") as State },
          ],
          ci: ci ? { name: ci.name, status: ci.status, when: ci.when, url: ci.url } : null,
          generated_at: s.now().toISOString(),
        });
      },
    },
  };
}
