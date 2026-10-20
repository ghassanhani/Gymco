// gymcoapp.com/ as one versioned document: which sections show, editable
// copy, prices, store links, the FAQ and the email sign-up. The page reads
// the published version through app-config?site=landing. Also the waitlist
// that the page's "Notify me" fills.

import { defaultLanding, LANDING_DEFAULTS, LANDING_KEYS, validateLanding } from "../_shared/landing.ts";
import { ok, type Route } from "./handler.ts";
import type { WaitlistRow } from "./store.ts";
import { versionedRoutes } from "./versioned.ts";

const routes = versionedRoutes("landing", {
  table: "site_landing",
  section: "website",
  validate: (body) => Promise.resolve(validateLanding(body)),
  base: () => defaultLanding(),
});

/** The full default body, with the built-in English as hints for every editable key. */
export const landingDefaults = () => ({
  ...defaultLanding(),
  copy: Object.fromEntries(LANDING_KEYS.map((k) => [k, { en: LANDING_DEFAULTS[k] }])),
});

const cell = (s: string) => (/[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);

export function waitlistCsv(rows: WaitlistRow[]): string {
  return ["email,locale,created_at", ...rows.map((r) => [r.email, r.locale, r.created_at].map((v) => cell(String(v ?? ""))).join(","))].join("\n");
}

const get = routes["landing.get"];
export const landingRoutes: Record<string, Route> = {
  ...routes,
  "landing.get": {
    cap: get.cap,
    run: async (ctx, body) => {
      const r = await get.run(ctx, body);
      if (r.status !== 200) return r;
      return ok({ ...(r.body as object), defaults: landingDefaults(), keys: [...LANDING_KEYS], waitlist: await ctx.store.waitlistStats() });
    },
  },

  "waitlist.export": {
    cap: "audit_export",
    run: async (ctx) => {
      const rows = await ctx.store.waitlistRows();
      await ctx.audit({ section: "website", action: "waitlist_export", after: { rows: rows.length } });
      return ok({ csv: waitlistCsv(rows) });
    },
  },
};
