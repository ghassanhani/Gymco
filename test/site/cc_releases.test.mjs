import { test } from "node:test";
import assert from "node:assert/strict";
import { blockedPct, buildLabel, buildNumber, latestBuild, toBullets, versionLabel } from "../../site/admin/lib/releases.js";

const versions = [{ build: 102, pct: 70 }, { build: 101, pct: 18 }, { build: "100", pct: 8 }, { build: "unknown", pct: 4 }];

test("build numbers come from numbers, digit strings and version+build labels", () => {
  assert.equal(buildNumber(102), 102);
  assert.equal(buildNumber("101"), 101);
  assert.equal(buildNumber("1.0.2+102"), 102);
  assert.equal(buildNumber("1.0.2"), null);
  assert.equal(buildNumber("unknown"), null);
});

test("a hard block counts the share on builds below the minimum", () => {
  assert.equal(blockedPct(versions, 102), 26);
  assert.equal(blockedPct(versions, 101), 8);
  assert.equal(blockedPct(versions, 100), 0);
  assert.equal(blockedPct(versions, 0), 0);
  assert.equal(blockedPct([], 102), 0);
});

test("the newest build and its label", () => {
  assert.equal(latestBuild(versions), 102);
  assert.equal(latestBuild([{ build: "unknown", pct: 100 }]), null);
  const notes = [{ build: 102, version: "1.0.2" }];
  assert.equal(buildLabel(102, notes), "1.0.2 (102)");
  assert.equal(buildLabel(101, notes), "Build 101");
  assert.equal(versionLabel({ build: "unknown" }), "Not reported yet");
  assert.equal(versionLabel({ build: "1.0.2" }), "1.0.2");
  assert.equal(versionLabel({ build: 102 }, notes), "1.0.2 (102)");
});

test("What's New bullets: one per line, markers dropped, blanks skipped", () => {
  assert.deepEqual(toBullets("- Faster photo logging\n\n• Fixes\n  Plain line "), ["Faster photo logging", "Fixes", "Plain line"]);
  assert.deepEqual(toBullets(null), []);
});
