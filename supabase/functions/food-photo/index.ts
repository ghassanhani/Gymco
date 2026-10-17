// Names the foods on a photographed plate. It does not guess amounts: a photo
// cannot tell how much is there, so the app asks the user for those.
//
// POST { image: <base64 JPEG>, lang: "en" | "ar" | "es" }
// with the signed-in user's Authorization header.
// -> 200 { foods: [{ name, local, sure }], left }
// -> 429 { error: "daily_cap", left: 0 }
//
// Secrets: ANTHROPIC_API_KEY (set with `supabase secrets set`), plus
// ANTHROPIC_WORKSPACE_ID when that key is not scoped to a workspace.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";
import { createClient } from "npm:@supabase/supabase-js@2.117.2";

const MAX_IMAGE_BYTES = 4_000_000;
const LANGS: Record<string, string> = { en: "English", ar: "Arabic", es: "Spanish" };

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const reportFoods: Anthropic.Tool = {
  name: "report_foods",
  description: "Report the distinct foods visible on the plate or in the photo.",
  strict: true,
  input_schema: {
    type: "object",
    properties: {
      foods: {
        type: "array",
        description: "One entry per distinct food, most prominent first. Empty if no food is visible.",
        items: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description:
                "Generic English name as a nutrition database lists it, e.g. 'Chicken breast', 'White rice, cooked', 'Hummus'.",
            },
            local: { type: "string", description: "The same food named in the user's language." },
            sure: { type: "boolean", description: "True when the food is clearly identifiable." },
          },
          required: ["name", "local", "sure"],
          additionalProperties: false,
        },
      },
    },
    required: ["foods"],
    additionalProperties: false,
  },
};

// A key that is not scoped to a workspace must name one on every request.
const workspace = Deno.env.get("ANTHROPIC_WORKSPACE_ID");
const anthropic = new Anthropic(workspace ? { defaultHeaders: { "anthropic-workspace-id": workspace } } : {});

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method" });

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return json(401, { error: "auth" });
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: who, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !who.user) return json(401, { error: "auth" });
  const uid = who.user.id;

  let body: { image?: unknown; lang?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "body" });
  }
  const image = typeof body.image === "string" ? body.image : "";
  if (!image || image.length * 0.75 > MAX_IMAGE_BYTES) return json(400, { error: "image" });
  const language = LANGS[typeof body.lang === "string" ? body.lang : "en"] ?? "English";

  const { data: left, error: creditError } = await admin.rpc("take_ai_credit", { uid });
  if (creditError) return json(500, { error: "credit" });
  if (left < 0) return json(429, { error: "daily_cap", left: 0 });

  try {
    const response = await anthropic.messages.create({
      model: "claude-haiku-5-5",
      max_tokens: 2048,
      output_config: { effort: "low" },
      tools: [reportFoods],
      tool_choice: { type: "tool", name: "report_foods" },
      messages: [
        {
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
            {
              type: "text",
              text:
                `List the foods you can see in this photo of a meal. The user reads ${language}. ` +
                "Name each food generically, as a nutrition database would, and do not estimate amounts. " +
                "Mark a food as not sure when it is partly hidden or could be something else. " +
                "If there is no food in the photo, report an empty list.",
            },
          ],
        },
      ],
    });

    if (response.stop_reason === "refusal") {
      await admin.rpc("refund_ai_credit", { uid });
      return json(422, { error: "refused", left: left + 1 });
    }
    const call = response.content.find((b) => b.type === "tool_use");
    const foods = (call?.type === "tool_use" ? (call.input as { foods?: unknown }).foods : null) ?? [];
    return json(200, { foods, left });
  } catch (e) {
    await admin.rpc("refund_ai_credit", { uid });
    if (e instanceof Anthropic.RateLimitError) return json(503, { error: "busy", left: left + 1 });
    if (e instanceof Anthropic.APIError) return json(502, { error: "model", left: left + 1 });
    throw e;
  }
});
