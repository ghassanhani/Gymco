import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { corsHeaders, isAdmin } from "./access.ts";

Deno.test("an admin email matches whatever its case or spacing", () => {
  assert(isAdmin("GhassanHani0@gmail.com", " ghassanhani0@gmail.com ,x@y.z"));
});

Deno.test("an email not on the list is refused", () => {
  assert(!isAdmin("a@b.c", "x@y.z"));
});

Deno.test("no email is refused", () => {
  assert(!isAdmin(undefined, "x@y.z"));
});

Deno.test("an empty or missing list lets nobody in", () => {
  assert(!isAdmin("a@b.c", ""));
  assert(!isAdmin("a@b.c", undefined));
  assert(!isAdmin("", " , "));
});

Deno.test("the site's own origin is allowed", () => {
  assertEquals(corsHeaders("https://gymcoapp.com")["Access-Control-Allow-Origin"], "https://gymcoapp.com");
  assertEquals(corsHeaders("http://localhost:8765")["Access-Control-Allow-Origin"], "http://localhost:8765");
});

Deno.test("any other origin gets no allow header", () => {
  assertEquals(corsHeaders("https://evil.example")["Access-Control-Allow-Origin"], undefined);
  assertEquals(corsHeaders(null)["Access-Control-Allow-Origin"], undefined);
});
