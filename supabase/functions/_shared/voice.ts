// The voice check for anything an admin writes to users: phrases that tie
// exercise to food or shame the reader. Short lists, whole words, ignoring
// case. "Cheat day" is allowed: the app uses it.

export type Lang = "en" | "ar" | "es";

export interface VoiceIssue {
  phrase: string;
  hint: string;
}

const FOOD = "ties exercise to food. Try “Start the week strong”.";
const EARN = "ties food to exercise. Food isn't earned.";
const SHAME = "shames. Say what to do next instead.";
const WEIGHT = "frames the app around weight. Talk about strength or habits.";
const BODY = "judges bodies. Leave people's shape out of it.";

/** [phrase, hint, pattern]; the pattern (when given) narrows where the phrase counts. */
type Entry = [string, string, RegExp?];

// JS \b knows only ASCII, so boundaries are spelled out with Unicode classes.
const word = (p: string, flags = "iu") => new RegExp(`(?<![\\p{L}\\p{N}])${p}(?![\\p{L}\\p{N}])`, flags);
// Arabic attaches و، ف، ال، ب and ل to the front of a word.
const arWord = (p: string) => new RegExp(`(?<![\\p{L}\\p{N}])(?:و|ف)?(?:ال|بال|لل|ب|ل)?${p}(?![\\p{L}\\p{N}])`, "iu");

const LISTS: Record<Lang, Entry[]> = {
  en: [
    ["burn off", FOOD],
    ["work off", FOOD],
    ["earn your", EARN],
    ["earned your", EARN],
    ["guilt", SHAME],
    ["guilty", SHAME],
    ["lose weight", WEIGHT],
    ["weight loss", WEIGHT],
    // "fat" only as a word about people, never the nutrient.
    ["fat", BODY, word("(?:(?:you're|you are|feel|feeling|get|getting|got|too|so|being)\\s+fat|fat\\s+(?:people|person|body|bodies|folks|guys|girls))")],
  ],
  ar: [
    ["احرق السعرات", FOOD, arWord("(?:احرق|حرق|نحرق|تحرق)\\s+(?:ال)?سعرات")],
    ["استحق", EARN, arWord("(?:استحق|تستحق|استحقيت|استحقيتي)")],
    ["ذنب", SHAME, arWord("(?:ذنب|مذنب|مذنبة)")],
    ["انقاص الوزن", WEIGHT, arWord("(?:انقاص|إنقاص|خسارة|خساره|فقدان|نزول)\\s+(?:ال)?وزن")],
    ["سمين", BODY, arWord("(?:سمين|سمينة|سمينه|بدين|بدينة)")],
  ],
  es: [
    ["quema lo que", FOOD, word("quem(?:a|ar|aste)\\s+lo\\s+que")],
    ["gánate", EARN, word("g[aá]nate|ganarte|te\\s+lo\\s+ganaste")],
    ["culpa", SHAME, word("culpa|culpable")],
    ["perder peso", WEIGHT, word("perder\\s+peso|bajar\\s+de\\s+peso|adelgazar")],
    ["gordo", BODY, word("gord[oa]s?")],
  ],
};

/** Phrases in [text] that break the voice rules for [lang], once each. */
export function voiceIssues(text: string, lang: Lang): VoiceIssue[] {
  const out: VoiceIssue[] = [];
  for (const [phrase, hint, pattern] of LISTS[lang] ?? []) {
    const re = pattern ?? (lang === "ar" ? arWord(phrase) : word(phrase.replace(/\s+/g, "\\s+")));
    if (re.test(text)) out.push({ phrase, hint });
  }
  return out;
}
