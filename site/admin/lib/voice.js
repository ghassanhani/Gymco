// A mirror of the server's voice check (_shared/voice.ts) so the editor can
// hint while typing. The server's warnings are the ones that count; this
// list only has to agree with it on the common cases.

const LISTS = {
  en: [
    ["burn off", "ties exercise to food. Try “Start the week strong”."],
    ["earn your", "makes food a reward. Say what the workout is for instead."],
    ["guilt", "shames the reader. Keep it calm and plain."],
    ["lose weight", "makes weight the goal. Talk about the habit instead."],
    ["fat", "as a word about people, it shames. Describe the food or the habit."],
  ],
  ar: [["احرق", "يربط التمرين بالطعام. جرّب «ابدأ الأسبوع بقوة»."], ["ذنب", "يُشعر القارئ بالخجل. اجعل النص هادئاً."], ["انقص وزنك", "يجعل الوزن هو الهدف. تحدّث عن العادة بدلاً من ذلك."]],
  es: [["quemar", "liga el ejercicio a la comida. Prueba «Empieza la semana con fuerza»."], ["culpa", "avergüenza a quien lee. Mantén un tono calmado."], ["perder peso", "hace del peso la meta. Habla del hábito."]],
};

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** Whole-word, case-insensitive hits: [{ phrase, hint }]. */
export function voiceIssues(text, lang = "en") {
  const t = String(text ?? "");
  if (!t.trim()) return [];
  return (LISTS[lang] ?? LISTS.en)
    .filter(([phrase]) => new RegExp(`(^|[^\\p{L}])${escape(phrase)}(?=$|[^\\p{L}])`, "iu").test(t))
    .map(([phrase, hint]) => ({ phrase, hint }));
}

/** Hits for every language of a T3 text, tagged with the language. */
export const voiceIssuesT3 = (t3) => ["en", "ar", "es"].flatMap((lang) => voiceIssues(t3?.[lang], lang).map((x) => ({ ...x, lang })));

export const voiceLine = (x) => `Voice check: “${x.phrase}” ${x.hint}`;
