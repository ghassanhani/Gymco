// Messaging: in-app announcements and push campaigns. Announcements reach
// phones through app-config once published; a campaign is only scheduled
// here (sending needs FCM, which isn't set up yet).

import { checkT3, cleanTargeting, overlapWarning, validateAnnouncement, voiceWarnings } from "../_shared/announcements.ts";
import { nextFreeDate, outsideQuietHours, parseLocal, weekTakenBy } from "../_shared/push_rules.ts";
import { fail, ok, type Route } from "./handler.ts";
import type { Services } from "./services.ts";
import type { CampaignRow } from "./store.ts";

const SECTION = "messaging";
const idOf = (v: unknown) => (Number.isInteger(Number(v)) && Number(v) > 0 ? Number(v) : null);

export function messagingRoutes(s: Services): Record<string, Route> {
  return {
    "announce.list": {
      cap: "read",
      run: async (ctx) => ok({ items: await ctx.store.announcements() }),
    },

    "announce.save": {
      cap: "draft",
      run: async (ctx, body) => {
        const check = validateAnnouncement(body);
        if (!check.ok) return fail(400, "invalid", { errors: check.errors });
        const all = await ctx.store.announcements();
        const id = idOf(body.id);
        const before = id ? all.find((a) => a.id === id) : undefined;
        if (id && !before) return fail(404, "no_announcement");
        const warnings = [...voiceWarnings(check.body)];
        const overlap = overlapWarning(check.body, all as (typeof all[number] & { id: number })[], s.now(), id ?? undefined);
        if (overlap) warnings.push(overlap);
        let saved = id!;
        if (before) {
          // Editing a published announcement takes it back to a draft.
          await ctx.store.updateAnnouncement(id!, { ...check.body, status: "draft", published_by: null });
        } else {
          saved = await ctx.store.insertAnnouncement({ ...check.body, status: "draft", created_by: ctx.admin.email });
        }
        await ctx.audit({ section: SECTION, action: "announce_save", object_id: String(saved), before: before ?? null, after: check.body });
        return ok({ id: saved, warnings });
      },
    },

    "announce.publish": {
      cap: "publish",
      run: async (ctx, body) => {
        const id = idOf(body.id);
        const row = id ? (await ctx.store.announcements()).find((a) => a.id === id) : undefined;
        if (!row) return fail(404, "no_announcement");
        if (row.status === "published") return ok();
        if (row.status === "archived") return fail(409, "not_publishable");
        await ctx.store.updateAnnouncement(id!, { status: "published", published_by: ctx.admin.email });
        await ctx.audit({ section: SECTION, action: "announce_publish", object_id: String(id), before: { status: row.status }, after: { status: "published" } });
        return ok();
      },
    },

    "announce.archive": {
      cap: "draft",
      run: async (ctx, body) => {
        const id = idOf(body.id);
        const row = id ? (await ctx.store.announcements()).find((a) => a.id === id) : undefined;
        if (!row) return fail(404, "no_announcement");
        await ctx.store.updateAnnouncement(id!, { status: "archived" });
        await ctx.audit({ section: SECTION, action: "announce_archive", object_id: String(id), before: { status: row.status }, after: { status: "archived" } });
        return ok();
      },
    },

    "push.list": {
      cap: "read",
      run: async (ctx) =>
        ok({ items: await ctx.store.campaigns(), configured: s.fcmConfigured(), tokens: await ctx.store.pushTokenCount() }),
    },

    "push.save": {
      cap: "draft",
      run: async (ctx, body) => {
        const title = checkT3(body.title, "title", 80);
        const text = checkT3(body.body, "body", 500);
        const errors = [...title.errors, ...text.errors];
        if (!parseLocal(body.send_at_local)) errors.push({ key: "send_at_local", message: "Enter a date and time (YYYY-MM-DDTHH:MM)" });
        if (errors.length) return fail(400, "invalid", { errors });
        const moved = outsideQuietHours(String(body.send_at_local));
        const id = idOf(body.id);
        const before = id ? (await ctx.store.campaigns()).find((c) => c.id === id) : undefined;
        if (id && !before) return fail(404, "no_campaign");
        if (before && before.status !== "draft") return fail(409, "not_draft");
        const fields = { title: title.value, body: text.value, send_at_local: moved.send_at_local, targeting: cleanTargeting(body.targeting) };
        let saved = id!;
        if (before) await ctx.store.updateCampaign(id!, fields);
        else saved = await ctx.store.insertCampaign({ ...fields, status: "draft", created_by: ctx.admin.email });
        await ctx.audit({ section: SECTION, action: "push_save", object_id: String(saved), before: before ?? null, after: fields });
        return ok({ id: saved, send_at_local: moved.send_at_local, moved: moved.moved });
      },
    },

    "push.schedule": {
      cap: "publish",
      run: async (ctx, body) => {
        const id = idOf(body.id);
        const all = await ctx.store.campaigns();
        const row = id ? all.find((c) => c.id === id) : undefined;
        if (!row) return fail(404, "no_campaign");
        if (row.status !== "draft") return fail(409, "not_draft");
        const slots = all as (CampaignRow & { id: number })[];
        const taken = weekTakenBy(slots, row.send_at_local, id!);
        if (taken) return fail(409, "week_taken", { taken_by: taken, next_free: nextFreeDate(slots, row.send_at_local) });
        if (!s.fcmConfigured()) return fail(503, "not_configured");
        await ctx.store.updateCampaign(id!, { status: "scheduled" });
        await ctx.audit({ section: SECTION, action: "push_schedule", object_id: String(id), before: { status: "draft" }, after: { status: "scheduled", send_at_local: row.send_at_local } });
        return ok();
      },
    },

    "push.cancel": {
      cap: "draft",
      run: async (ctx, body) => {
        const id = idOf(body.id);
        const row = id ? (await ctx.store.campaigns()).find((c) => c.id === id) : undefined;
        if (!row) return fail(404, "no_campaign");
        if (row.status === "sent") return fail(409, "already_sent");
        await ctx.store.updateCampaign(id!, { status: "cancelled" });
        await ctx.audit({ section: SECTION, action: "push_cancel", object_id: String(id), before: { status: row.status }, after: { status: "cancelled" } });
        return ok();
      },
    },
  };
}
