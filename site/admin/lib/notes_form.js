// Pure helpers for the Notifications page: the server's checks on the
// words (so mistakes show before saving), the groups, and a preview with
// sample numbers filled in.

/** The placeholders each notification's words can use, as the server checks them. */
export const NOTE_VARS = {
  protein: ["g"],
  water: ["l"],
  workout: ["routine", "n", "m"],
  sessionMoved: ["routine", "day"],
  restOver: ["n", "exercise"],
  streakRisk: ["days"],
  freezeUsed: ["n"],
  challengeNew: ["month", "n"],
  checkIn: ["kcal", "w"],
  ironTip: ["tip"],
};

const MAX = { title: 60, body: 160 };

/** What the server would refuse in a notifications block, optionally for one kind. */
export function noteErrors(notifications, onlyKind = null) {
  const out = [];
  for (const [kind, parts] of Object.entries(notifications?.text ?? {})) {
    if (onlyKind && kind !== onlyKind) continue;
    for (const [part, langs] of Object.entries(parts ?? {})) {
      for (const [lang, s] of Object.entries(langs ?? {})) {
        if (s.length > MAX[part]) out.push(`${part === "title" ? "Title" : "Body"} (${lang}) is over ${MAX[part]} characters`);
        const unknown = [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).filter((v) => !(NOTE_VARS[kind] ?? []).includes(v));
        if (unknown.length) out.push(`{${unknown[0]}} isn’t a placeholder this notification has`);
      }
    }
  }
  return out;
}

/** The catalog in its groups, in order. */
export function noteGroups(notes) {
  const out = new Map();
  for (const n of notes) out.set(n.group, [...(out.get(n.group) ?? []), n]);
  return [...out.entries()];
}

const SAMPLE = { g: "40", l: "1.2", routine: "Push day", n: "6", m: "55", day: "Thursday", exercise: "Bench Press", days: "23", month: "November", kcal: "2,180", w: "3", tip: "Sleep 7–9 hours tonight — recovery is where strength is built." };

/** Numbers that read right for one notification ({n} means different things). */
const SAMPLE_FOR = { restOver: { n: "3" }, freezeUsed: { n: "2" }, challengeNew: { n: "12" } };

/** The words a phone would show in [lang], with sample numbers. */
export function notePreview(n, override, lang) {
  const sample = { ...SAMPLE, ...(SAMPLE_FOR[n.kind] ?? {}) };
  const pick = (part) => {
    const o = override?.[part];
    const s = (o?.[lang] || (lang === "ar_f" ? o?.ar : "") || "").trim() || n[part][lang] || n[part].en;
    return s.replace(/\{(\w+)\}/g, (m, v) => sample[v] ?? m).replace(/\{n, plural,.*?other\{(.*?)\}\}/s, "$1");
  };
  return { title: pick("title"), body: pick("body") };
}

/** A copy of the override with one language's text set, dropping empties. */
export function setNoteText(override, part, lang, value) {
  const out = structuredClone(override ?? {});
  const v = value.trim() ? value : "";
  out[part] = { ...(out[part] ?? {}), [lang]: v };
  if (!v) delete out[part][lang];
  if (!Object.keys(out[part]).length) delete out[part];
  return out;
}
