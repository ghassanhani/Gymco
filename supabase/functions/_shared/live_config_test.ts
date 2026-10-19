import { assertEquals } from "jsr:@std/assert@1.0.13";
import { cachedConfig } from "./live_config.ts";

Deno.test("the published config is read once a minute, and defaults stand in when none is published", async () => {
  let reads = 0;
  let t = 0;
  const get = cachedConfig(() => {
    reads++;
    return Promise.resolve(reads === 1 ? null : { limits: { ai_scans_per_day: 12 } });
  }, () => t);
  assertEquals((await get()).limits.ai_scans_per_day, 10);
  t = 59_000;
  await get();
  assertEquals(reads, 1);
  t = 61_000;
  assertEquals((await get()).limits.ai_scans_per_day, 12);
  assertEquals(reads, 2);
});

Deno.test("a failed read keeps the last good config instead of failing the request", async () => {
  let t = 0;
  let fail = false;
  const get = cachedConfig(() => fail ? Promise.reject(new Error("db")) : Promise.resolve({ ai: { daily_budget_eur: 3 } }), () => t);
  assertEquals((await get()).ai.daily_budget_eur, 3);
  fail = true;
  t = 120_000;
  assertEquals((await get()).ai.daily_budget_eur, 3);
});
