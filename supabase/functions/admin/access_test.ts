import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { aalOf, can, corsHeaders, type Capability, type Role } from "./access.ts";

// The spec's matrix, row by row: who may do what.
const matrix: Record<Capability, Role[]> = {
  read: ["viewer", "support", "editor", "owner"],
  support: ["support", "editor", "owner"],
  destroy: ["support", "editor", "owner"],
  draft: ["editor", "owner"],
  publish: ["owner"],
  owner_keys: ["owner"],
  team: ["owner"],
  audit_export: ["owner"],
};

for (const [cap, allowed] of Object.entries(matrix) as [Capability, Role[]][]) {
  Deno.test(`${cap}: allowed for ${allowed.join(", ")} only`, () => {
    for (const role of ["viewer", "support", "editor", "owner"] as Role[]) {
      assertEquals(can(role, cap), allowed.includes(role), `${role} / ${cap}`);
    }
  });
}

Deno.test("a role that isn't one of the four can do nothing", () => {
  assert(!can("root" as Role, "read"));
});

const jwt = (payload: unknown) => `h.${btoa(JSON.stringify(payload)).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_")}.s`;

Deno.test("the second factor is read from the token", () => {
  assertEquals(aalOf(jwt({ aal: "aal2" })), "aal2");
  assertEquals(aalOf(jwt({ aal: "aal1" })), "aal1");
});

Deno.test("a token with no level or garbage is aal1", () => {
  assertEquals(aalOf(jwt({})), "aal1");
  assertEquals(aalOf("not-a-jwt"), "aal1");
});

Deno.test("only the dashboard's origins get CORS", () => {
  assertEquals(corsHeaders("https://gymcoapp.com")["Access-Control-Allow-Origin"], "https://gymcoapp.com");
  assertEquals(corsHeaders("https://evil.example")["Access-Control-Allow-Origin"], undefined);
});
