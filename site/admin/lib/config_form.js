// Pure helpers for the Remote config form: the same bounds the server checks
// (so mistakes show before saving), targeting summaries, and change counts.

export function checkField(spec, v, key = "") {
  if (spec.kind === "int" || spec.kind === "num") {
    if (typeof v !== "number" || !Number.isFinite(v)) return spec.kind === "int" ? "Must be a whole number" : "Must be a number";
    if (spec.kind === "int" && !Number.isInteger(v)) return "Must be a whole number";
    if (key === "limits.ai_scans_per_day" && v < 1) return "Use 1 or more. To stop photo logging, turn off photo_log instead.";
    if ((spec.min != null && v < spec.min) || (spec.max != null && v > spec.max)) return `Must be between ${spec.min} and ${spec.max}`;
  }
  return null;
}

const PLATFORM = { ios: "iOS", android: "Android" };

export function targetLabel(t = {}) {
  const parts = [];
  if (t.platform) parts.push(PLATFORM[t.platform]);
  if (t.locale) parts.push(t.locale.toUpperCase());
  if (t.min_build != null && t.max_build != null) parts.push(`builds ${t.min_build}–${t.max_build}`);
  else if (t.min_build != null) parts.push(`build ${t.min_build}+`);
  else if (t.max_build != null) parts.push(`up to build ${t.max_build}`);
  if (t.percent != null) parts.push(`${t.percent}%`);
  return parts.length ? parts.join(" · ") : "Everyone";
}

export function ruleSummary(rules, key) {
  const mine = (rules ?? []).filter((r) => r.key === key);
  return mine.length ? mine.map((r) => targetLabel(r.target)).join(", ") : "All";
}

const leaves = (o, p = "", out = {}) => {
  for (const [k, v] of Object.entries(o ?? {})) {
    if (v && typeof v === "object" && !Array.isArray(v)) leaves(v, `${p}${k}.`, out);
    else out[p + k] = JSON.stringify(v);
  }
  return out;
};

export function countChanges(a, b) {
  const x = leaves(a);
  const y = leaves(b);
  return [...new Set([...Object.keys(x), ...Object.keys(y)])].filter((k) => x[k] !== y[k]).length;
}

/** A copy of [body] with one dotted key set. */
export function setKey(body, key, value) {
  const out = structuredClone(body);
  const [g, k] = key.split(".");
  out[g] = { ...(out[g] ?? {}), [k]: value };
  return out;
}
