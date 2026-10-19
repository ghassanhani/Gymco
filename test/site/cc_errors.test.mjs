import { test } from "node:test";
import assert from "node:assert/strict";
import { errorText } from "../../site/admin/lib/errors.js";

const err = (status, code) => Object.assign(new Error(code), { status, code });

test("known server codes read as plain words", () => {
  assert.equal(errorText(err(409, "last_owner")), "The last Owner can't be removed or demoted");
  assert.equal(errorText(err(403, "forbidden")), "Your role can't do that");
  assert.equal(errorText(err(403, "is_admin")), "Admins can't be deleted from Accounts. Remove them from the team first");
});

test("network failures say the server was out of reach", () => {
  assert.equal(errorText(err(0, "offline")), "Couldn't reach the server");
  assert.equal(errorText(new TypeError("Failed to fetch")), "Couldn't reach the server");
});

test("anything else falls back to a safe line, or the caller's own", () => {
  assert.equal(errorText(err(500, "server")), "Something went wrong. Nothing was changed.");
  assert.equal(errorText(undefined), "Something went wrong. Nothing was changed.");
  assert.equal(errorText("boom"), "Something went wrong. Nothing was changed.");
  assert.equal(errorText(err(409, "conflict"), "Couldn't publish"), "Couldn't publish");
  assert.equal(errorText(err(403, "forbidden"), "Couldn't publish"), "Your role can't do that");
});
