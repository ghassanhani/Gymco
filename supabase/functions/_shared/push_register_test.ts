import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { MAX_TOKENS, parseRegistration, refuseNewToken, parseUnregister } from "./push_register.ts";

Deno.test("a registration is kept to the token table's columns and values", () => {
  const r = parseRegistration({ token: " abc ", platform: "ios", locale: "ar", utc_offset_min: 180, app_version: "1.2.0 (104)", extra: 1 });
  assert(r.ok);
  assertEquals(r.row, { token: "abc", platform: "ios", locale: "ar", utc_offset_min: 180, app_version: "1.2.0 (104)" });
  const noVersion = parseRegistration({ token: "abc", platform: "android", locale: "en", utc_offset_min: -300 });
  assert(noVersion.ok);
  assertEquals(noVersion.row.app_version, null);
});

Deno.test("a registration with a bad platform, locale, offset or token is refused", () => {
  for (const body of [
    { token: "", platform: "ios", locale: "en", utc_offset_min: 0 },
    { token: "x".repeat(4097), platform: "ios", locale: "en", utc_offset_min: 0 },
    { token: "t", platform: "web", locale: "en", utc_offset_min: 0 },
    { token: "t", platform: "ios", locale: "fr", utc_offset_min: 0 },
    { token: "t", platform: "ios", locale: "en", utc_offset_min: 900 },
    { token: "t", platform: "ios", locale: "en", utc_offset_min: "60" },
    { token: "t", platform: "ios", locale: "en", utc_offset_min: 0, app_version: "x".repeat(33) },
    null,
  ]) {
    assertEquals(parseRegistration(body).ok, false, JSON.stringify(body));
  }
});

Deno.test("removing a token needs the token", () => {
  assertEquals(parseUnregister({ token: " abc " }), "abc");
  assertEquals(parseUnregister({}), null);
  assertEquals(parseUnregister({ token: 5 }), null);
});

Deno.test("past 100,000 tokens a new one is refused, a known one still updates", () => {
  assertEquals(MAX_TOKENS, 100_000);
  assertEquals(refuseNewToken(99_999, false), false);
  assertEquals(refuseNewToken(100_000, false), true);
  assertEquals(refuseNewToken(100_000, true), false);
});
