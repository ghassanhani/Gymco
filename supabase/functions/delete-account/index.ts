// Deletes the signed-in user's account. Their backup and scan counts go with
// it (both reference auth.users on delete cascade). The phone's own data is
// the app's to clear.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });
  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return new Response(null, { status: 401 });
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) return new Response(null, { status: 401 });
  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  return new Response(null, { status: deleteError ? 500 : 204 });
});
