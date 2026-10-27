// Now and then the model ends a text field early and writes the rest of its
// answer inside it, as raw `</why><parameter name="routines">[...]` markup.
// This takes such answers apart again: each leaked field is put back where
// it belongs (when it's missing), and every text is cut where the markup
// starts, so none of it reaches the user.

const PARAM = /<parameter name="([a-z_]+)">([\s\S]*?)(?:<\/parameter>|$)/g;
/** Markup, or JSON written out inside a sentence. */
const LEAK = /<\/?[a-z_]+(?:\s[^>]*)?>|"\s*:\s*[[{"\d]|\{"[a-z_]+"\s*:/;

function empty(v: unknown) {
  return v === undefined || v === null || v === "" || (Array.isArray(v) && v.length === 0);
}

function parse(raw: string): unknown {
  const t = raw.trim();
  try {
    return JSON.parse(t);
  } catch {
    return t;
  }
}

/** Whether any text in the answer carries leaked markup. */
export function leaked(v: unknown): boolean {
  if (typeof v === "string") return LEAK.test(v);
  if (Array.isArray(v)) return v.some(leaked);
  if (v && typeof v === "object") return Object.values(v).some(leaked);
  return false;
}

function cut(v: unknown): unknown {
  if (typeof v === "string") {
    const m = LEAK.exec(v);
    return m ? v.slice(0, m.index).trim() : v;
  }
  if (Array.isArray(v)) return v.map(cut);
  if (v && typeof v === "object") return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, cut(x)]));
  return v;
}

/** The answer with leaked fields put back (top level) and the markup cut out. */
export function repaired(out: Record<string, unknown>): Record<string, unknown> {
  const fixed: Record<string, unknown> = { ...out };
  for (const v of Object.values(out)) {
    if (typeof v !== "string") continue;
    for (const [, key, raw] of v.matchAll(PARAM)) {
      if (key in fixed && !empty(fixed[key])) continue;
      fixed[key] = parse(raw);
    }
  }
  return cut(fixed) as Record<string, unknown>;
}
