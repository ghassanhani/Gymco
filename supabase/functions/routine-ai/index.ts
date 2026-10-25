// Builds training routines from the user's own words: how many days, what
// for, how long, what equipment. The app sends the names of the exercises
// it has, so every exercise that comes back is one the phone can match.
//
// POST { text: "3 days a week, push pull legs, 45 min, dumbbells only",
//        exercises: ["Barbell Bench Press - Medium Grip", ...], lang: "en" | "ar" | "es", bucket?: 0-99 }
// with the signed-in user's Authorization header.
// -> 200 { routines: [{ name, days: [0-6], items: [{ exercise, sets, rep_low, rep_high, rest_seconds }] }],
//          summary, left }   days: 0 is Monday.
// -> 429 { error: "daily_cap", left: 0 }
// -> 503 { error: "paused", reason: "feature_off" | "budget" | "maintenance" }
//
// Secrets: as food-photo.

import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";
import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { costEur, gate, pickModel } from "../_shared/ai_gate.ts";
import { cachedConfig, publishedBody } from "../_shared/live_config.ts";
import { exerciseNames, exerciseSystem, PLAN_RULES, routinesSchema } from "../_shared/routine_schema.ts";

const MAX_TEXT_CHARS = 600;
const LANGS: Record<string, string> = { en: "English", ar: "Arabic", es: "Spanish" };

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const reportRoutines: Anthropic.Tool = {
  name: "report_routines",
  description: "Report the training routines that make up the plan the user asked for.",
  strict: true,
  input_schema: {
    type: "object",
    properties: {
      routines: routinesSchema,
      summary: { type: "string", description: "One or two sentences in the user's language on how the plan works." },
    },
    required: ["routines", "summary"],
    additionalProperties: false,
  },
};

const workspace = Deno.env.get("ANTHROPIC_WORKSPACE_ID");
const anthropic = new Anthropic(workspace ? { defaultHeaders: { "anthropic-workspace-id": workspace } } : {});
const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const liveConfig = cachedConfig(publishedBody(admin));

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method" });

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return json(401, { error: "auth" });
  const { data: who, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !who.user) return json(401, { error: "auth" });
  const uid = who.user.id;

  let body: { text?: unknown; exercises?: unknown; lang?: unknown; bucket?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "body" });
  }
  const text = typeof body.text === "string" ? body.text.trim().slice(0, MAX_TEXT_CHARS) : "";
  if (!text) return json(400, { error: "empty" });
  const names = exerciseNames(body.exercises);
  if (names.length === 0) return json(400, { error: "exercises" });
  const language = LANGS[typeof body.lang === "string" ? body.lang : "en"] ?? "English";

  const config = await liveConfig();
  const { data: spent, error: spendError } = await admin.rpc("ai_spend_today");
  if (spendError) console.error("routine-ai: ai_spend_today:", spendError);
  const open = gate(config, "routine", spendError ? null : Number(spent ?? 0));
  if (!open.ok) return json(503, { error: "paused", reason: open.reason });
  const bucket = Number.isInteger(body.bucket) && (body.bucket as number) >= 0 && (body.bucket as number) < 100
    ? body.bucket as number
    : 99;
  const { model } = pickModel(config, bucket);
  const usage = async (ok: boolean, started: number, u?: { input_tokens?: number; output_tokens?: number }) => {
    await admin.rpc("note_ai_usage", {
      feature: "routine", tokens_in: u?.input_tokens ?? 0, tokens_out: u?.output_tokens ?? 0,
      cost_eur: u ? costEur(model, u) : 0, ok, latency_ms: Date.now() - started,
    });
  };

  const { data: left, error: creditError } = await admin.rpc("take_ai_credit", { uid });
  if (creditError) return json(500, { error: "credit" });
  if (left < 0) return json(429, { error: "daily_cap", left: 0 });

  const started = Date.now();
  try {
    const response = await anthropic.messages.create({
      model,
      max_tokens: 4096,
      output_config: { effort: "low" },
      tools: [reportRoutines],
      tool_choice: { type: "tool", name: "report_routines" },
      system: [exerciseSystem("You plan strength training for a lifting app.", names)],
      messages: [
        {
          role: "user",
          content:
            `The user reads ${language} and asks for: <request>${text}</request>\n` +
            "Build the plan they describe. Follow what they say about days, goal, time, equipment and level; " +
            "where they say nothing, plan for muscle growth for a lifter with some experience. " +
            PLAN_RULES + " " +
            "Name the routines and write the summary in the user's language. " +
            "If the request is not about training, report no routines.",
        },
      ],
    });

    await usage(response.stop_reason !== "refusal", started, response.usage);
    if (response.stop_reason === "refusal") {
      await admin.rpc("refund_ai_credit", { uid });
      return json(422, { error: "refused", left: left + 1 });
    }
    const call = response.content.find((b) => b.type === "tool_use");
    const out = (call?.type === "tool_use" ? call.input : null) as { routines?: unknown; summary?: unknown } | null;
    return json(200, { routines: out?.routines ?? [], summary: out?.summary ?? "", left });
  } catch (e) {
    await usage(false, started);
    await admin.rpc("refund_ai_credit", { uid });
    if (e instanceof Anthropic.RateLimitError) return json(503, { error: "busy", left: left + 1 });
    if (e instanceof Anthropic.APIError) return json(502, { error: "model", left: left + 1 });
    throw e;
  }
});
