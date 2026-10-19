// The Control Center's admin API (gymcoapp.com/admin). POST {action, ...}
// with the admin's access token; the role, the second factor and every
// write's audit entry are checked and written here, never in the browser.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { corsHeaders } from "./access.ts";
import { handle } from "./handler.ts";
import { SupabaseStore } from "./store.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});
const store = new SupabaseStore(db);

Deno.serve(async (req) => {
  const cors = corsHeaders(req.headers.get("Origin"));
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return new Response(null, { status: 405, headers: cors });

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "") ?? null;
  let body: unknown = null;
  try {
    body = await req.json();
  } catch {
    // An empty or broken body is an unknown action below.
  }

  let status = 500;
  let payload: unknown = { error: "server" };
  try {
    const reply = await handle({ jwt, body }, {
      store,
      verify: async (t) => {
        const { data, error } = await db.auth.getUser(t);
        // Only a rejected token is "signed out"; an auth outage is an error,
        // so a blip never signs an admin out.
        if (error && (error.status === 401 || error.status === 403)) return null;
        if (error) throw error;
        return data.user ? { id: data.user.id, email: data.user.email } : null;
      },
    });
    status = reply.status;
    payload = reply.body;
  } catch (e) {
    console.error("admin:", e);
  }
  await store.noteCall("admin", status < 500).catch(() => {});
  return new Response(payload === undefined ? null : JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
