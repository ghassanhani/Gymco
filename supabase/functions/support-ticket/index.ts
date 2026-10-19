// A support ticket from the app's help form. No auth: anyone may ask for
// help, so the shape is checked here and an email may send five a day.
// Deploy with verify_jwt off.
//
// POST { email, subject, body, locale?, app_version?, platform?, kind? }
// -> 201 { id } | 400 { error: "invalid", errors } | 429 { error: "too_many" }

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { deletionDeadline, overDailyLimit, parseTicket } from "../_shared/tickets.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

async function serve(req: Request): Promise<Response> {
  let body: unknown = null;
  try {
    body = await req.json();
  } catch {
    // An unreadable body fails validation below.
  }
  const check = parseTicket(body);
  if (!check.ok) return json(400, { error: "invalid", errors: check.errors });

  const today = `${new Date().toISOString().slice(0, 10)}T00:00:00Z`;
  const { count, error } = await db.from("support_tickets").select("id", { count: "exact", head: true })
    .eq("email", check.row.email).gte("created_at", today);
  if (error) throw error;
  if (overDailyLimit(count ?? 0)) return json(429, { error: "too_many" });

  const { data, error: insertError } = await db.from("support_tickets").insert({
    ...check.row, source: "app", deadline_at: check.row.kind === "deletion" ? deletionDeadline() : null,
  }).select("id").single();
  if (insertError) throw insertError;
  return json(201, { id: data.id });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return json(405, { error: "method" });
  let res: Response;
  try {
    res = await serve(req);
  } catch (e) {
    console.error("support-ticket:", e);
    res = json(500, { error: "server" });
  }
  await db.rpc("note_fn_call", { fn: "support-ticket", ok: res.status < 500 }).then(() => {}, () => {});
  return res;
});
