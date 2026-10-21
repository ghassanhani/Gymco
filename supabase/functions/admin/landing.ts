// gymcoapp.com/ as one versioned document: which sections show, editable
// copy, prices, store links, the FAQ and the email sign-up. The page reads
// the published version through app-config?site=landing. Also the waitlist
// that the page's "Notify me" fills.

import { defaultLanding, LANDING_DEFAULTS, LANDING_KEYS, SCREENS, validateLanding } from "../_shared/landing.ts";
import { fail, ok, type Route } from "./handler.ts";
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

/** Largest picture accepted for a hero phone; the dashboard sends about 150 KB. */
export const SCREEN_MAX_BYTES = 2_000_000;
const KINDS: Record<string, { ext: string; magic: number[] }> = {
  "image/jpeg": { ext: "jpg", magic: [0xff, 0xd8, 0xff] },
  "image/png": { ext: "png", magic: [0x89, 0x50, 0x4e, 0x47] },
  "image/webp": { ext: "webp", magic: [0x52, 0x49, 0x46, 0x46] },
};

function decodeBase64(s: string): Uint8Array<ArrayBuffer> | null {
  try {
    const bin = atob(s);
    const out = new Uint8Array(new ArrayBuffer(bin.length));
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  } catch {
    return null;
  }
}

const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");

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

  // A hero phone's picture goes to the public "site" bucket under its SHA-256,
  // so a URL never changes what it shows. It only becomes live once a draft
  // that names it is published.
  "landing.upload_screen": {
    cap: "draft",
    run: async (ctx, body) => {
      const slot = String(body.slot ?? "");
      if (!(SCREENS as readonly string[]).includes(slot)) return fail(400, "invalid", { errors: [{ key: "screens", message: "Not a screen on the page" }] });
      const kind = KINDS[String(body.type ?? "")];
      const bytes = typeof body.data === "string" ? decodeBase64(body.data) : null;
      const err = (message: string) => fail(400, "invalid", { errors: [{ key: `screens.${slot}`, message }] });
      if (!kind) return err("A JPEG, PNG or WebP picture");
      if (!bytes || !bytes.length) return err("The picture didn’t arrive; try again");
      if (bytes.length > SCREEN_MAX_BYTES) return err("At most 2 MB");
      if (!kind.magic.every((b, i) => bytes[i] === b)) return err("That file isn’t the picture it says it is");
      const path = `landing/${hex(await crypto.subtle.digest("SHA-256", bytes))}.${kind.ext}`;
      const url = await ctx.store.uploadSiteImage(path, bytes, String(body.type));
      await ctx.audit({ section: "website", action: "landing_upload_screen", after: { slot, path, bytes: bytes.length } });
      return ok({ url });
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
