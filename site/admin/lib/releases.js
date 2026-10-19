// Pure helpers for the Releases page: builds in use, what a version gate
// would block, and What's New bullets.

/** The build number behind a version label: 102, "102" or "1.0.2+102"; null when unknown. */
export function buildNumber(v) {
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  const m = /(?:^|\+)(\d+)$/.exec(String(v ?? ""));
  return m ? Number(m[1]) : null;
}

/** Share of devices on builds under [minBuild], from [{ build, pct }]. */
export function blockedPct(versions, minBuild) {
  if (!minBuild) return 0;
  return Math.min(100, Math.round(versions.reduce((a, v) => {
    const b = buildNumber(v.build);
    return b != null && b < minBuild ? a + (Number(v.pct) || 0) : a;
  }, 0)));
}

/** The highest known build in use, or null. */
export function latestBuild(versions) {
  const known = versions.map((v) => buildNumber(v.build)).filter((b) => b != null);
  return known.length ? Math.max(...known) : null;
}

/** "1.0.2 (102)" when a note names the version, else "Build 102". */
export function buildLabel(build, notes = []) {
  const n = notes.find((x) => Number(x.build) === Number(build));
  return n?.version ? `${n.version} (${build})` : `Build ${build}`;
}

/** The label of a versions row: a build becomes "Build 102" or "1.0.2 (102)"; anything else is shown as sent. */
export function versionLabel(v, notes = []) {
  const b = buildNumber(v.build);
  if (b == null) return v.build === "unknown" || v.build == null ? "Not reported yet" : String(v.build);
  return buildLabel(b, notes);
}

export const toBullets = (text) => String(text ?? "").split("\n").map((l) => l.replace(/^[-*•]\s*/, "").trim()).filter(Boolean);

export const RUN_TONE = { passed: "good", failed: "bad", running: "warn", queued: "flat" };
export const RUN_LABEL = { passed: "Passed", failed: "Failed", running: "Running", queued: "Queued" };
