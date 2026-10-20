// The landing page's "Notify me". No auth: anyone may sign up, so the shape
// is checked here and everyone together may add 500 a day (UTC). A repeat
// email is still 201, so the form can't be used to test addresses.
// Deploy with verify_jwt off.
//
// POST { email, locale }
// -> 201 { ok: true } | 400 { error: "invalid" } | 429 { error: "too_many" }

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { overWaitlistCeiling, parseSignup } from "../_shared/waitlist.ts";

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
  const check = parseSignup(body);
  if (!check.ok) return json(400, { error: "invalid" });

  const today = `${new Date().toISOString().slice(0, 10)}T00:00:00Z`;
  const { count, error } = await db.from("landing_waitlist").select("email", { count: "exact", head: true }).gte("created_at", today);
  if (error) throw error;
  if (overWaitlistCeiling(count ?? 0)) return json(429, { error: "too_many" });

  // Already on the list: keep the first sign-up as it was.
  const { error: insertError } = await db.from("landing_waitlist").upsert(check.row, { onConflict: "email", ignoreDuplicates: true });
  if (insertError) throw insertError;
  return json(201, { ok: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return json(405, { error: "method" });
  let res: Response;
  try {
    res = await serve(req);
  } catch (e) {
    console.error("waitlist:", e);
    res = json(500, { error: "server" });
  }
  await db.rpc("note_fn_call", { fn: "waitlist", ok: res.status < 500 }).then(() => {}, () => {});
  return res;
});
