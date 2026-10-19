import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { fillTemplate, TEMPLATES } from "./support_templates.ts";

Deno.test("templates: the four the contract names, in three languages, each with {email}", () => {
  assertEquals(Object.keys(TEMPLATES), ["deletion_confirmed", "restore_help", "cap_reset", "nothing_stored"]);
  for (const [name, t] of Object.entries(TEMPLATES)) {
    for (const lang of ["en", "ar", "es"] as const) {
      assert(t[lang].includes("{email}"), `${name}.${lang}`);
      assert(t[lang].trim().length > 0);
    }
  }
});

Deno.test("templates: the placeholder is filled", () => {
  assertEquals(fillTemplate("Hi {email}, done. {email}", "a@b.co"), "Hi a@b.co, done. a@b.co");
});
