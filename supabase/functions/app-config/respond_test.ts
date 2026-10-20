import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { deviceOf, landingReply, packReply, respond, siteOf } from "./respond.ts";
import { checksum } from "../_shared/packs.ts";

const now = new Date("2026-10-20T12:00:00Z");
const ann = (over: Record<string, unknown> = {}) => ({
  id: 1, title: { en: "New", ar: "جديد", es: "Nuevo" }, body: { en: "b", ar: "b", es: "b" }, cta: null,
  starts_at: "2026-10-19T00:00:00Z", ends_at: "2026-10-30T00:00:00Z", targeting: {}, status: "published", ...over,
});

Deno.test("with nothing published, phones get today's defaults", () => {
  const r = respond({ config: null, packs: [], announcements: [], device: {}, now });
  assertEquals(r.config_version, 0);
  assertEquals(r.config.limits.ai_scans_per_day, 10);
  assertEquals(r.packs, {});
});

Deno.test("the published config is resolved for this device", () => {
  const r = respond({
    config: { version: 7, body: { limits: { ai_scans_per_day: 12 }, rules: [{ key: "features.dictate", value: false, target: { platform: "android" } }] } },
    packs: [], announcements: [], device: { platform: "android" }, now,
  });
  assertEquals([r.config_version, r.config.limits.ai_scans_per_day, r.config.features.dictate], [7, 12, false]);
  assert(!("rules" in r.config));
});

Deno.test("packs are listed by kind with version and checksum, never their bodies", () => {
  const r = respond({ config: null, packs: [{ kind: "foods", version: 3, checksum: "abc" }], announcements: [], device: {}, now });
  assertEquals(r.packs, { foods: { version: 3, checksum: "abc" } });
});

Deno.test("only live announcements targeted at this device are sent", () => {
  const list = [
    ann({ id: 1 }),
    ann({ id: 2, starts_at: "2026-10-25T00:00:00Z" }),
    ann({ id: 3, ends_at: "2026-10-20T11:00:00Z" }),
    ann({ id: 4, status: "draft" }),
    ann({ id: 5, targeting: { platform: "ios" } }),
    ann({ id: 6, targeting: { locale: "ar", min_build: 102 } }),
  ];
  const ids = (device: object) => respond({ config: null, packs: [], announcements: list, device, now }).announcements.map((a: { id: number }) => a.id);
  assertEquals(ids({ platform: "android", locale: "ar", build: 102 }), [1, 6]);
  assertEquals(ids({ platform: "ios", locale: "en", build: 101 }), [1, 5]);
});

Deno.test("whats_new is the published note for this device's build, or null", () => {
  const notes = [
    { build: 104, version: "1.2.0", body: { en: "Faster", ar: "أسرع", es: "Más rápido" }, published: true },
    { build: 105, version: "1.3.0", body: { en: "Soon", ar: "قريبًا", es: "Pronto" }, published: false },
  ];
  const at = (build?: number) => respond({ config: null, packs: [], announcements: [], release_notes: notes, device: { build }, now }).whats_new;
  assertEquals(at(104), { build: 104, version: "1.2.0", body: { en: "Faster", ar: "أسرع", es: "Más rápido" } });
  assertEquals(at(105), null);
  assertEquals(at(103), null);
  assertEquals(at(undefined), null);
  assertEquals(respond({ config: null, packs: [], announcements: [], device: { build: 104 }, now }).whats_new, null);
});

Deno.test("device details are read from the query and kept to known values", () => {
  const d = deviceOf(new URL("https://x/app-config?platform=ios&locale=ar&build=103&bucket=42"));
  assertEquals(d, { platform: "ios", locale: "ar", build: 103, bucket: 42 });
  assertEquals(deviceOf(new URL("https://x/app-config?platform=windows&bucket=500")), { platform: undefined, locale: undefined, build: undefined, bucket: undefined });
});

Deno.test("a pack is served as the canonical string its checksum was computed over", async () => {
  // jsonb hands keys back in its own order; the served string must not depend on it.
  const body = { items: [{ name: { es: "Labné", en: "Labneh", ar: "لبنة" }, kcal: 160, id: "labneh", fat: 14, protein: 6, carbs: 4 }] };
  const saved = await checksum(body);
  const r = packReply({ kind: "foods", version: 3, checksum: saved, body });
  assertEquals(Object.keys(r), ["kind", "version", "checksum", "body_json"]);
  assertEquals(r.body_json, '{"items":[{"carbs":4,"fat":14,"id":"labneh","kcal":160,"name":{"ar":"لبنة","en":"Labneh","es":"Labné"},"protein":6}]}');
  const hash = [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(r.body_json)))].map((b) => b.toString(16).padStart(2, "0")).join("");
  assertEquals(hash, r.checksum);
  assertEquals(JSON.parse(r.body_json), body);
});

Deno.test("the landing page gets the published landing version and body, or version 0 and null", () => {
  const body = { beta: false, prices: { pro_month: "€5.99" } };
  assertEquals(landingReply({ version: 4, body }), { version: 4, body });
  assertEquals(landingReply(null), { version: 0, body: null });
});

Deno.test("?site= is read only for the sites app-config serves", () => {
  assertEquals(siteOf(new URL("https://x/app-config?site=landing")), "landing");
  assertEquals(siteOf(new URL("https://x/app-config?site=admin")), "unknown");
  assertEquals(siteOf(new URL("https://x/app-config?platform=ios")), null);
});
