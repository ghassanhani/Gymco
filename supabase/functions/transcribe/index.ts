// Writes down a short voice note: what someone ate, or what they want from
// Iron. OpenAI's transcription hears some fifty languages, and Arabic and
// English even mixed in one sentence. Arabic goes to the full model, English
// and Spanish to the mini one. The audio is passed through and never stored.
//
// POST { audio: <base64 m4a>, lang: "en" | "ar" | "es", seconds: 4.2, bucket?: 0-99 }
// with the signed-in user's Authorization header.
// -> 200 { text, lang, left }   text is "" when nothing was said (that isn't
//    counted); lang is the two-letter language it was spoken in, "" when
//    unsure; left is voice notes left today. Notes don't take one of the day's
//    AI requests; they have their own cap (limits.voice_notes_per_day).
// -> 429 { error: "daily_cap", left: 0 }
// -> 503 { error: "paused", reason } when the Control Center has switched voice
//    off or today's AI budget is spent.
//
// Secrets: OPENAI_API_KEY. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are
// provided by Supabase.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { gate } from "../_shared/ai_gate.ts";
import { spokenLanguage } from "../_shared/spoken_language.ts";
import { cachedConfig, publishedBody } from "../_shared/live_config.ts";

// Arabic goes to the full model, which follows dialect far better; the
// mini one is good enough for English and Spanish at half the price. The
// app's language decides first; a note that turns out to be Arabic in an
// English or Spanish app is heard again by the full model.
const STRONG = Deno.env.get("TRANSCRIBE_MODEL_STRONG") ?? "gpt-4o-transcribe";
const NORMAL = Deno.env.get("TRANSCRIBE_MODEL") ?? "gpt-4o-mini-transcribe";
/** Dollars a minute, as euros a second. */
const EUR_PER_SECOND: Record<string, number> = {
  "gpt-4o-transcribe": (0.006 * 0.92) / 60,
  "gpt-4o-mini-transcribe": (0.003 * 0.92) / 60,
};
/** A minute and a bit of 64 kbps audio. */
const MAX_AUDIO_BYTES = 1_000_000;
const MAX_SECONDS = 75;
const ARABIC_LETTERS = /[\u0600-\u06FF]/;

// What the transcriber expects to hear steers it: the same hint whatever
// the app's language, since people speak Arabic to an English app and the
// other way round. Written mostly in Arabic so Arabic stays in Arabic
// letters (not translated, not spelled out in Latin), with the English
// words people mix in left in English, and Gulf, Levantine and Egyptian
// food words named so they're spelled right.
const HINT =
  "ملاحظة صوتية في تطبيق حمية وتمارين، باللهجة الخليجية أو الشامية أو المصرية أو بالفصحى، وقد تختلط بالإنجليزية. " +
  "اكتب الكلام كما قيل بحروفه، العربية بالعربية والإنجليزية بالإنجليزية، ولا تترجم. " +
  "أمثلة: أكلت كبسة دجاج، مندي لحم، شاورما، فلافل، فول، حمص، كشري، ملوخية، مجبوس، هريس، لبنة، خبز، رز، " +
  "سلطة، تمر، قهوة، شاي، كوب، صحن، ملعقة، حبة، نص، ربع، غرام، تمرين، صدر، ظهر، رجل. " +
  "English words like chicken burger, protein shake, oats, whey, bench press. Spanish is fine too.";

/** For the mini model: as much English as Arabic, so neither pulls the other. */
const HINT_MIXED =
  "A voice note in a diet and training app, in English, Spanish or Arabic, sometimes mixed. Write each word " +
  "as it was said, in its own letters; never translate. Foods like oats, whey, chicken breast, rice, kabsa. " +
  "ملاحظة في تطبيق حمية وتمارين، العربية تُكتب بالعربية مثل كبسة، شاورما، رز، دجاج.";

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const liveConfig = cachedConfig(publishedBody(admin));

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method" });
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) return json(503, { error: "paused", reason: "feature_off" });

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return json(401, { error: "auth" });
  const { data: who, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !who.user) return json(401, { error: "auth" });
  const uid = who.user.id;

  let body: { audio?: unknown; lang?: unknown; seconds?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "body" });
  }
  const audio = typeof body.audio === "string" ? body.audio : "";
  if (!audio) return json(400, { error: "empty" });
  if (audio.length * 0.75 > MAX_AUDIO_BYTES) return json(400, { error: "audio" });
  const seconds = Math.min(Math.max(Number(body.seconds) || 0, 0), MAX_SECONDS);
  const appLang = typeof body.lang === "string" ? body.lang : "en";

  const config = await liveConfig();
  const { data: spent, error: spendError } = await admin.rpc("ai_spend_today");
  if (spendError) console.error("transcribe: ai_spend_today:", spendError);
  const open = gate(config, "voice", spendError ? null : Number(spent ?? 0));
  if (!open.ok) return json(503, { error: "paused", reason: open.reason });

  // Not one of the day's AI requests: notes have a cap of their own.
  const cap = Number(config.limits?.voice_notes_per_day ?? 60);
  const { data: left, error: capError } = await admin.rpc("take_voice_note", { uid, cap });
  if (capError) return json(500, { error: "credit" });
  if (left < 0) return json(429, { error: "daily_cap", left: 0 });

  const started = Date.now();
  let cost = 0;
  const usage = (ok: boolean) =>
    admin.rpc("note_ai_usage", {
      feature: "voice", tokens_in: 0, tokens_out: 0, cost_eur: cost, ok, latency_ms: Date.now() - started,
    });
  const refund = async (status: number, error: string) => {
    await usage(false);
    await admin.rpc("give_back_voice_note", { uid });
    return json(status, { error, left: left + 1 });
  };

  try {
    const bytes = Uint8Array.from(atob(audio), (c) => c.charCodeAt(0));
    const hear = async (model: string, prompt: string) => {
      const form = new FormData();
      form.append("file", new Blob([bytes], { type: "audio/mp4" }), "note.m4a");
      form.append("model", model);
      form.append("response_format", "json");
      form.append("prompt", prompt);
      form.append("temperature", "0");
      const r = await fetch("https://api.openai.com/v1/audio/transcriptions", {
        method: "POST",
        headers: { Authorization: `Bearer ${key}` },
        body: form,
      });
      if (!r.ok) {
        console.error("transcribe: openai", model, r.status, (await r.text()).slice(0, 300));
        return { status: r.status, text: "" };
      }
      cost += seconds * (EUR_PER_SECOND[model] ?? EUR_PER_SECOND["gpt-4o-transcribe"]);
      return { status: 200, text: String(((await r.json()) as { text?: unknown }).text ?? "").trim().slice(0, 1000) };
    };

    let heard = appLang === "ar" ? await hear(STRONG, HINT) : await hear(NORMAL, HINT_MIXED);
    // Arabic after all: the full model hears it again. Should that fail, the
    // first try still stands.
    if (heard.status === 200 && appLang !== "ar" && ARABIC_LETTERS.test(heard.text)) {
      const again = await hear(STRONG, HINT);
      if (again.status === 200 && again.text) heard = again;
    }
    if (heard.status !== 200) return await refund(heard.status === 429 ? 503 : 502, heard.status === 429 ? "busy" : "model");
    await usage(true);
    // Nothing said: it costs the user nothing.
    if (!heard.text) {
      await admin.rpc("give_back_voice_note", { uid });
      return json(200, { text: "", lang: "", left: left + 1 });
    }
    return json(200, { text: heard.text, lang: spokenLanguage(heard.text), left });
  } catch (e) {
    console.error("transcribe:", e);
    return await refund(502, "model");
  }
});
