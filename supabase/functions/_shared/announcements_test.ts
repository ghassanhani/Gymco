import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { checkT3, overlapWarning, validateAnnouncement, voiceWarnings } from "./announcements.ts";

const t3 = (en: string) => ({ en, ar: "ع", es: "e" });
const good = { title: t3("New"), body: t3("Hello"), starts_at: "2026-10-20T00:00:00Z", ends_at: "2026-10-27T00:00:00Z" };

Deno.test("T3: every language, trimmed, within the limit", () => {
  assertEquals(checkT3({ en: " a ", ar: "ب", es: "c" }, "title", 80), { value: { en: "a", ar: "ب", es: "c" }, errors: [] });
  assertEquals(checkT3({ en: "a", ar: " ", es: "c" }, "title", 80).errors, [{ key: "title.ar", message: "Needed in English, Arabic and Spanish" }]);
  assertEquals(checkT3({ en: "a".repeat(81), ar: "b", es: "c" }, "title", 80).errors, [{ key: "title.en", message: "Keep it under 80 characters" }]);
  assertEquals(checkT3("nope", "title", 80).errors.length, 3);
});

Deno.test("announcement: a valid body comes back normalised", () => {
  const r = validateAnnouncement({ ...good, cta: { label: t3("Open"), url: "https://gymcoapp.com/x" }, targeting: { platform: "ios", locale: "fr", min_build: 100, percent: 5 } });
  assert(r.ok);
  assertEquals(r.body.cta, { label: t3("Open"), url: "https://gymcoapp.com/x" });
  assertEquals(r.body.targeting, { platform: "ios", min_build: 100 });
  assertEquals(validateAnnouncement(good).body.cta, null);
});

Deno.test("announcement: ends before starts is a field error with the contract's text", () => {
  const r = validateAnnouncement({ ...good, ends_at: "2026-10-20T00:00:00Z" });
  assertEquals(r.ok, false);
  assertEquals(r.errors, [{ key: "ends_at", message: "End date is before the start date." }]);
  assertEquals(validateAnnouncement({ ...good, ends_at: "soon" }).errors[0].key, "ends_at");
});

Deno.test("announcement: a missing language and a non-https cta are errors", () => {
  const r = validateAnnouncement({ ...good, body: { en: "x", ar: "", es: "y" }, cta: { label: t3("Go"), url: "http://x.com" } });
  assertEquals(r.errors.map((e) => e.key), ["body.ar", "cta.url"]);
});

Deno.test("announcement: overlapping a live published one is a warning", () => {
  const now = new Date("2026-10-21T00:00:00Z");
  const live = [
    { id: 1, status: "published", starts_at: "2026-10-15T00:00:00Z", ends_at: "2026-10-22T00:00:00Z", targeting: {} },
    { id: 2, status: "published", starts_at: "2026-10-15T00:00:00Z", ends_at: "2026-10-22T00:00:00Z", targeting: { platform: "android" } },
    { id: 3, status: "published", starts_at: "2026-10-01T00:00:00Z", ends_at: "2026-10-10T00:00:00Z", targeting: {} },
    { id: 4, status: "draft", starts_at: "2026-10-15T00:00:00Z", ends_at: "2026-10-22T00:00:00Z", targeting: {} },
  ];
  const mine = { ...good, targeting: { platform: "ios" } };
  assertEquals(overlapWarning(mine, live, now, undefined), { key: "starts_at", message: "Overlaps 1 live announcement · only the newest shows" });
  assertEquals(overlapWarning({ ...good, targeting: {} }, live, now, undefined)?.message, "Overlaps 2 live announcements · only the newest shows");
  // Editing the live one itself is not an overlap with itself.
  assertEquals(overlapWarning(mine, live, now, 1), null);
  assertEquals(overlapWarning({ ...good, starts_at: "2026-10-23T00:00:00Z", ends_at: "2026-10-30T00:00:00Z" }, live, now, undefined), null);
});

Deno.test("announcement: voice hits are warnings keyed by field and language", () => {
  const w = voiceWarnings({ title: t3("Burn off the weekend"), body: { en: "ok", ar: "لا تشعر بالذنب", es: "ok" } });
  assertEquals(w, [
    { key: "title.en", message: "“burn off” ties exercise to food. Try “Start the week strong”." },
    { key: "body.ar", message: "“ذنب” shames. Say what to do next instead." },
  ]);
});
