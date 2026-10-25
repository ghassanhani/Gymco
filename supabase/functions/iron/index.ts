// Iron, the coach inside Gymco. It reads a summary of the user's numbers
// (never the diary itself, photos or notes) and either gives today's tip or
// builds a full program: daily targets for eating and a week of training.
//
// POST { mode: "tip" | "program", numbers: {...summary...}, lang: "en" | "ar" | "es",
//        exercises?: [names] (program only), ask?: "what the user wants" (program only), bucket?: 0-99 }
// with the signed-in user's Authorization header.
// -> 200 tip:     { title, tip, action, left }
//        program: { summary, kcal, protein, carbs, fat, why, routines, habits, left }
// -> 429 { error: "daily_cap", left: 0 }
// -> 503 { error: "paused", reason: "feature_off" | "budget" | "maintenance" }
//
// Secrets: as food-photo.

import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";
import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { costEur, gate, pickModel } from "../_shared/ai_gate.ts";
import { cachedConfig, publishedBody } from "../_shared/live_config.ts";
import { exerciseNames, exerciseSystem, PLAN_RULES, routinesSchema } from "../_shared/routine_schema.ts";

const MAX_NUMBERS_CHARS = 6000;
const MAX_ASK_CHARS = 400;
const LANGS: Record<string, string> = { en: "English", ar: "Arabic", es: "Spanish" };
const ACTIONS = ["log_food", "start_workout", "drink_water", "weigh_in", "rest", "walk", "none"] as const;

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const PERSONA =
  "You are Iron, the coach inside the Gymco diet and training app. You talk like a good personal trainer: " +
  "direct, warm and short, with no emojis and no hype. Use only the numbers you are given and never invent any. " +
  "You are not a doctor: give no medical advice, and if the numbers look risky (eating far below target, losing " +
  "weight faster than 1% a week, training through pain) tell the user to ease off.";

const reportTip: Anthropic.Tool = {
  name: "report_tip",
  description: "Today's one tip for the user.",
  strict: true,
  input_schema: {
    type: "object",
    properties: {
      title: { type: "string", description: "Two to six words, the headline." },
      tip: {
        type: "string",
        description: "One or two sentences: one concrete thing to do today, tied to a number from the summary, and why it helps.",
      },
      action: { type: "string", enum: [...ACTIONS], description: "The app screen that helps them do it." },
    },
    required: ["title", "tip", "action"],
    additionalProperties: false,
  },
};

const reportProgram: Anthropic.Tool = {
  name: "report_program",
  description: "A full program: daily eating targets and a week of training.",
  strict: true,
  input_schema: {
    type: "object",
    properties: {
      summary: { type: "string", description: "Two or three sentences on the program and why it fits this user." },
      kcal: { type: "integer", description: "Daily calories." },
      protein: { type: "integer", description: "Daily protein, grams." },
      carbs: { type: "integer", description: "Daily carbohydrate, grams." },
      fat: { type: "integer", description: "Daily fat, grams." },
      why: { type: "string", description: "One sentence on how the targets follow from their numbers." },
      routines: routinesSchema,
      habits: {
        type: "array",
        description: "Three short daily habits for this user, each under twelve words.",
        items: { type: "string" },
      },
    },
    required: ["summary", "kcal", "protein", "carbs", "fat", "why", "routines", "habits"],
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

  let body: { mode?: unknown; numbers?: unknown; lang?: unknown; exercises?: unknown; ask?: unknown; bucket?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "body" });
  }
  const mode = body.mode === "program" ? "program" : body.mode === "tip" ? "tip" : null;
  if (!mode) return json(400, { error: "mode" });
  const numbers = body.numbers && typeof body.numbers === "object" ? JSON.stringify(body.numbers) : "";
  if (!numbers || numbers.length > MAX_NUMBERS_CHARS) return json(400, { error: "numbers" });
  const names = exerciseNames(body.exercises);
  if (mode === "program" && names.length === 0) return json(400, { error: "exercises" });
  const ask = typeof body.ask === "string" ? body.ask.trim().slice(0, MAX_ASK_CHARS) : "";
  const language = LANGS[typeof body.lang === "string" ? body.lang : "en"] ?? "English";

  const config = await liveConfig();
  const { data: spent, error: spendError } = await admin.rpc("ai_spend_today");
  if (spendError) console.error("iron: ai_spend_today:", spendError);
  const open = gate(config, "coach", spendError ? null : Number(spent ?? 0));
  if (!open.ok) return json(503, { error: "paused", reason: open.reason });
  const bucket = Number.isInteger(body.bucket) && (body.bucket as number) >= 0 && (body.bucket as number) < 100
    ? body.bucket as number
    : 99;
  const { model } = pickModel(config, bucket);
  const usage = async (ok: boolean, started: number, u?: { input_tokens?: number; output_tokens?: number }) => {
    await admin.rpc("note_ai_usage", {
      feature: "coach", tokens_in: u?.input_tokens ?? 0, tokens_out: u?.output_tokens ?? 0,
      cost_eur: u ? costEur(model, u) : 0, ok, latency_ms: Date.now() - started,
    });
  };

  const { data: left, error: creditError } = await admin.rpc("take_ai_credit", { uid });
  if (creditError) return json(500, { error: "credit" });
  if (left < 0) return json(429, { error: "daily_cap", left: 0 });

  const facts = `The user reads ${language}. Their numbers from the app: <numbers>${numbers}</numbers>\n`;
  const prompt = mode === "tip"
    ? facts +
      "Give today's tip: the one thing that would help most today, judging by what they have and haven't done yet " +
      "and how the last two weeks went. Praise a real win when there is one. Write it in the user's language."
    : facts +
      (ask ? `They add: <ask>${ask}</ask>\n` : "") +
      "Build their program, as a personal trainer would after reading these numbers. Set daily calories and macros " +
      "for their goal and current trend (protein about 1.6 to 2.2 g per kg of body weight), never below their " +
      "calorie floor. Plan a training week around the days and time they already train, or 3 to 4 days if they " +
      "have no pattern yet, and lift the muscles their weekly sets show are behind. " + PLAN_RULES + " " +
      "Write the summary, the routine names and the habits in the user's language.";

  const started = Date.now();
  try {
    const response = await anthropic.messages.create({
      model,
      max_tokens: mode === "tip" ? 512 : 4096,
      output_config: { effort: "low" },
      tools: [mode === "tip" ? reportTip : reportProgram],
      tool_choice: { type: "tool", name: mode === "tip" ? "report_tip" : "report_program" },
      system: mode === "tip"
        ? PERSONA
        : [{ type: "text", text: PERSONA }, exerciseSystem("When you plan training:", names)],
      messages: [{ role: "user", content: prompt }],
    });

    await usage(response.stop_reason !== "refusal", started, response.usage);
    if (response.stop_reason === "refusal") {
      await admin.rpc("refund_ai_credit", { uid });
      return json(422, { error: "refused", left: left + 1 });
    }
    const call = response.content.find((b) => b.type === "tool_use");
    const out = (call?.type === "tool_use" ? call.input : {}) as Record<string, unknown>;
    return json(200, { ...out, left });
  } catch (e) {
    await usage(false, started);
    await admin.rpc("refund_ai_credit", { uid });
    if (e instanceof Anthropic.RateLimitError) return json(503, { error: "busy", left: left + 1 });
    if (e instanceof Anthropic.APIError) return json(502, { error: "model", left: left + 1 });
    throw e;
  }
});
