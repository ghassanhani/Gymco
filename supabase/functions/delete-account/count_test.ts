import { assertEquals } from "jsr:@std/assert@1.0.13";
import { noteDeletion } from "./count.ts";

Deno.test("a counter that throws does not stop the delete", async () => {
  assertEquals(await noteDeletion(() => Promise.reject(new Error("down"))), false);
});

Deno.test("a counter that returns an error does not stop the delete", async () => {
  assertEquals(await noteDeletion(() => Promise.resolve({ error: { message: "nope" } })), false);
});

Deno.test("a counted deletion says so", async () => {
  assertEquals(await noteDeletion(() => Promise.resolve({ error: null })), true);
});
