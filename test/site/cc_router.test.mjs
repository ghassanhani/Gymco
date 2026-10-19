import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { NEEDS, can } from "../../site/admin/lib/roles.js";
import { NAV, PAGES, parseHash } from "../../site/admin/lib/routes.js";

test("the dashboard's role rules are the server's", () => {
  const ts = readFileSync(new URL("../../supabase/functions/admin/access.ts", import.meta.url), "utf8");
  const block = ts.slice(ts.indexOf("const needs"), ts.indexOf("};", ts.indexOf("const needs")));
  const server = Object.fromEntries([...block.matchAll(/(\w+): "(\w+)"/g)].map((m) => [m[1], m[2]]));
  assert.deepEqual(NEEDS, server);
});

test("support reads overview, health and releases and uses accounts and the inbox, nothing more", () => {
  const open = PAGES.filter((p) => can("support", p.cap)).map((p) => p.id);
  assert.deepEqual(open.sort(), ["accounts", "health", "overview", "releases", "support"]);
});

test("a viewer opens only the monitoring pages", () => {
  assert.deepEqual(PAGES.filter((p) => can("viewer", p.cap)).map((p) => p.id).sort(), ["health", "overview", "releases"]);
});

test("the owner opens all eleven sections", () => {
  assert.equal(PAGES.filter((p) => can("owner", p.cap)).length, 11);
});

test("the sidebar has the spec's five groups in order", () => {
  assert.deepEqual(NAV.map((g) => g.name), ["Monitor", "People", "App", "Ship", "Admin"]);
  assert.deepEqual(NAV.flatMap((g) => g.items.map((i) => i.id)), [
    "overview", "health", "accounts", "support", "config", "content", "plans", "messaging", "releases", "website", "team",
  ]);
});

test("hashes route to a page and its parameters", () => {
  assert.deepEqual(parseHash("#/accounts?email=a%40b.c"), { id: "accounts", params: { email: "a@b.c" } });
  assert.deepEqual(parseHash(""), { id: "overview", params: {} });
  assert.deepEqual(parseHash("#/nowhere"), { id: "overview", params: {} });
});
