// Registers a phone's push token: the token, platform, language and UTC
// offset, nothing about who holds the phone. No auth, by design. Deploy
// with verify_jwt off. (Sending isn't built yet; this keeps tokens ready.)
//
// POST { token, platform, locale, utc_offset_min, app_version? } -> 200 { ok }
// DELETE { token } -> 200 { ok }

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { parseRegistration, parseUnregister } from "../_shared/push_register.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, DELETE, OPTIONS",
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
  if (req.method === "DELETE") {
    const token = parseUnregister(body);
    if (!token) return json(400, { error: "token" });
    const { error } = await db.from("push_tokens").delete().eq("token", token);
    if (error) throw error;
    return json(200, { ok: true });
  }
  const check = parseRegistration(body);
  if (!check.ok) return json(400, { error: check.error });
  const { error } = await db.from("push_tokens").upsert({ ...check.row, updated_at: new Date().toISOString() });
  if (error) throw error;
  return json(200, { ok: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST" && req.method !== "DELETE") return json(405, { error: "method" });
  let res: Response;
  try {
    res = await serve(req);
  } catch (e) {
    console.error("push-register:", e);
    res = json(500, { error: "server" });
  }
  await db.rpc("note_fn_call", { fn: "push-register", ok: res.status < 500 }).then(() => {}, () => {});
  return res;
});
