// Totals for the admin dashboard (gymcoapp.com/admin). Only emails listed in
// the ADMIN_EMAILS secret get an answer, and the answer holds counts and sums
// only: admin_stats() never returns who.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { corsHeaders, isAdmin } from "./access.ts";

Deno.serve(async (req) => {
  const cors = corsHeaders(req.headers.get("Origin"));
  const reply = (status: number, body?: unknown) =>
    new Response(body === undefined ? null : JSON.stringify(body), {
      status,
      headers: { ...cors, ...(body === undefined ? {} : { "Content-Type": "application/json" }) },
    });

  if (req.method === "OPTIONS") return reply(204);
  if (req.method !== "POST") return reply(405);
  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return reply(401);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) return reply(401);
  if (!isAdmin(data.user.email, Deno.env.get("ADMIN_EMAILS"))) return reply(403);

  const stats = await admin.rpc("admin_stats");
  if (stats.error) return reply(500);
  return reply(200, stats.data);
});
