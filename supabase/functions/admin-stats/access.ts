// Who may read the dashboard, and which pages may ask.

const origins = new Set(["https://gymcoapp.com", "http://localhost:8765"]);

/** [email] is on [list], a comma-separated ADMIN_EMAILS value. */
export function isAdmin(email: string | undefined, list: string | undefined): boolean {
  const me = email?.trim().toLowerCase();
  if (!me) return false;
  return (list ?? "").split(",").some((e) => e.trim().toLowerCase() === me);
}

/** CORS for the dashboard page; other origins get no allow header. */
export function corsHeaders(origin: string | null): Record<string, string> {
  const h: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    Vary: "Origin",
  };
  if (origin && origins.has(origin)) h["Access-Control-Allow-Origin"] = origin;
  return h;
}
