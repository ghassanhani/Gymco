// Writes down a short voice note: what someone ate, or what they want from
// Iron. OpenAI's transcription follows Arabic, English and Spanish, even
// mixed in one sentence. The audio is passed through and never stored.
//
// POST { audio: <base64 m4a>, lang: "en" | "ar" | "es", seconds: 4.2, bucket?: 0-99 }
// with the signed-in user's Authorization header.
// -> 200 { text, left }   text is "" when nothing was said (that costs nothing).
// -> 429 { error: "daily_cap", left: 0 }
// -> 503 { error: "paused", reason } when the Control Center has switched voice
//    off or today's AI budget is spent.
//
// Secrets: OPENAI_API_KEY. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are
// provided by Supabase.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { gate } from "../_shared/ai_gate.ts";
import { cachedConfig, publishedBody } from "../_shared/live_config.ts";

const MODEL = "gpt-4o-mini-transcribe";
/** About a minute and a half of 32 kbps audio. */
const MAX_AUDIO_BYTES = 400_000;
const MAX_SECONDS = 75;
/** $0.003 a minute, in euros. */
const EUR_PER_SECOND = (0.003 * 0.92) / 60;

// Words in the user's own language steer the transcriber towards it, and
// name the kind of thing people say here.
const HINTS: Record<string, string> = {
  en: "A note in a diet and training app: foods, portions, meals, workouts. Arabic words may be mixed in.",
  ar: "ملاحظة في تطبيق للحمية والتمارين: أطعمة وكميات ووجبات وتمارين، مثل كبسة، شاورما، دجاج، رز. قد تختلط كلمات إنجليزية مثل protein shake.",
  es: "Una nota en una app de dieta y entrenamiento: comidas, raciones, entrenos. Puede haber palabras en inglés.",
};

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
  const lang = typeof body.lang === "string" && body.lang in HINTS ? body.lang : "en";
  const seconds = Math.min(Math.max(Number(body.seconds) || 0, 0), MAX_SECONDS);

  const config = await liveConfig();
  const { data: spent, error: spendError } = await admin.rpc("ai_spend_today");
  if (spendError) console.error("transcribe: ai_spend_today:", spendError);
  const open = gate(config, "voice", spendError ? null : Number(spent ?? 0));
  if (!open.ok) return json(503, { error: "paused", reason: open.reason });

  const { data: left, error: creditError } = await admin.rpc("take_ai_credit", { uid });
  if (creditError) return json(500, { error: "credit" });
  if (left < 0) return json(429, { error: "daily_cap", left: 0 });

  const usage = (ok: boolean, started: number) =>
    admin.rpc("note_ai_usage", {
      feature: "voice", tokens_in: 0, tokens_out: 0,
      cost_eur: ok ? seconds * EUR_PER_SECOND : 0, ok, latency_ms: Date.now() - started,
    });

  const started = Date.now();
  try {
    const bytes = Uint8Array.from(atob(audio), (c) => c.charCodeAt(0));
    const form = new FormData();
    form.append("file", new Blob([bytes], { type: "audio/mp4" }), "note.m4a");
    form.append("model", MODEL);
    form.append("response_format", "json");
    form.append("prompt", HINTS[lang]);
    const r = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}` },
      body: form,
    });
    if (!r.ok) {
      console.error("transcribe: openai", r.status, (await r.text()).slice(0, 300));
      await usage(false, started);
      await admin.rpc("refund_ai_credit", { uid });
      return json(r.status === 429 ? 503 : 502, { error: r.status === 429 ? "busy" : "model", left: left + 1 });
    }
    const text = String(((await r.json()) as { text?: unknown }).text ?? "").trim().slice(0, 1000);
    await usage(true, started);
    // Nothing said: it costs the user nothing.
    if (!text) {
      await admin.rpc("refund_ai_credit", { uid });
      return json(200, { text: "", left: left + 1 });
    }
    return json(200, { text, left });
  } catch (e) {
    console.error("transcribe:", e);
    await usage(false, started);
    await admin.rpc("refund_ai_credit", { uid });
    return json(502, { error: "model", left: left + 1 });
  }
});
