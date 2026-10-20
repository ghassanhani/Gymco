import { assertEquals } from "jsr:@std/assert@1.0.13";
import { overWaitlistCeiling, parseSignup, WAITLIST_DAILY_LIMIT } from "./waitlist.ts";

Deno.test("waitlist: an email is trimmed and lower-cased, the locale kept to en, ar or es", () => {
  assertEquals(parseSignup({ email: "  Lifter@Example.COM ", locale: "ar" }), { ok: true, row: { email: "lifter@example.com", locale: "ar" } });
  assertEquals(parseSignup({ email: "a@b.co", locale: "es" }), { ok: true, row: { email: "a@b.co", locale: "es" } });
  for (const locale of [undefined, "fr", "", 3, "EN"]) {
    assertEquals(parseSignup({ email: "a@b.co", locale }), { ok: true, row: { email: "a@b.co", locale: "en" } }, String(locale));
  }
});

Deno.test("waitlist: anything that isn't an email is refused", () => {
  for (const email of [undefined, "", "nope", "a@b", "a b@c.d", "@b.co", 42, `${"a".repeat(316)}@b.co`]) {
    assertEquals(parseSignup({ email, locale: "en" }), { ok: false, row: null }, String(email));
  }
  for (const input of [null, "a@b.co", [], 1]) assertEquals(parseSignup(input).ok, false);
});

Deno.test("waitlist: the day's ceiling is 500 sign-ups from everyone together", () => {
  assertEquals(WAITLIST_DAILY_LIMIT, 500);
  assertEquals([overWaitlistCeiling(0), overWaitlistCeiling(499), overWaitlistCeiling(500), overWaitlistCeiling(900)], [false, false, true, true]);
});
