// Deletes the signed-in user's account. Their backup and scan counts go with
// it (both reference auth.users on delete cascade). The phone's own data is
// the app's to clear. Each deletion is counted, by day only, for the admin
// dashboard.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { noteDeletion } from "./count.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });
  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return new Response(null, { status: 401 });
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) return new Response(null, { status: 401 });
  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) return new Response(null, { status: 500 });
  await noteDeletion(() => admin.rpc("note_account_deletion"));
  return new Response(null, { status: 204 });
});
