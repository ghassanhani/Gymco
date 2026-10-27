// Which language a short note is in, so the app can tell a meal its own
// reader understands (English, Arabic, Spanish) from one only the AI can read.

import { franc } from "npm:franc-min@6.2.0";

/** The languages people are likely to speak to Gymco in, ISO 639-3 to 639-1. */
const COMMON: Record<string, string> = {
  eng: "en", spa: "es", fra: "fr", por: "pt", deu: "de", ita: "it", nld: "nl", tur: "tr", rus: "ru",
  ukr: "uk", pol: "pl", ind: "id", zlm: "ms", vie: "vi", tha: "th", hin: "hi", urd: "ur", ben: "bn",
  pes: "fa", cmn: "zh", jpn: "ja", kor: "ko", swh: "sw", tgl: "tl",
};

/** "" when the note is too short or mixed to tell. Arabic script is Arabic. */
export function spokenLanguage(text: string): string {
  const t = text.trim();
  if (/[؀-ۿ]/.test(t) && !/[پچگژکیٹڈڑںھہے]/.test(t)) {
    return "ar";
  }
  // Short notes ("eggs") read as almost anything.
  if (t.replace(/\s+/g, "").length < 12) return "";
  const code = franc(t, { minLength: 3, only: Object.keys(COMMON) });
  return COMMON[code] ?? "";
}
