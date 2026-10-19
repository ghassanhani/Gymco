// The phone's view of the Control Center: what is switched on, the limits,
// which content pack versions are current, and live announcements.
// Public and read-only; deploy with verify_jwt off.
//
// GET ?platform=ios|android&locale=en|ar|es&build=103&bucket=0-99
// -> 200 { config_version, config, packs: { kind: { version, checksum } }, announcements, whats_new, generated_at }
// GET ?pack=<kind>
// -> 200 { kind, version, checksum, body_json } | 404 { error: "no_pack" }

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { deviceOf, packReply, respond } from "./respond.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

const json = (status: number, body: unknown, maxAge = 300) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": status === 200 ? `public, max-age=${maxAge}` : "no-store",
    },
  });

async function serve(url: URL): Promise<Response> {
  const pack = url.searchParams.get("pack");
  if (pack) {
    const { data, error } = await db.from("content_packs").select("kind, version, checksum, body")
      .eq("kind", pack).eq("status", "published").maybeSingle();
    if (error) throw error;
    // A pack's body never changes for a version, so phones may keep it a day.
    return data ? json(200, packReply(data), 86_400) : json(404, { error: "no_pack" });
  }
  const device = deviceOf(url);
  const [config, packs, announcements, notes] = await Promise.all([
    db.from("remote_config").select("version, body").eq("status", "published").maybeSingle(),
    db.from("content_packs").select("kind, version, checksum").eq("status", "published"),
    db.from("announcements").select("id, title, body, cta, starts_at, ends_at, targeting, status")
      .eq("status", "published").gt("ends_at", new Date().toISOString()),
    db.from("release_notes").select("build, version, body, published").eq("published", true).eq("build", device.build ?? -1),
  ]);
  for (const r of [config, packs, announcements, notes]) if (r.error) throw r.error;
  return json(200, respond({
    config: config.data, packs: packs.data ?? [], announcements: announcements.data ?? [], release_notes: notes.data ?? [],
    device, now: new Date(),
  }));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } });
  if (req.method !== "GET") return json(405, { error: "method" });
  let res: Response;
  try {
    res = await serve(new URL(req.url));
  } catch (e) {
    console.error(e);
    res = json(500, { error: "server" });
  }
  await db.rpc("note_fn_call", { fn: "app-config", ok: res.status < 500 });
  return res;
});
