// The one way the dashboard talks to the server: the admin function, with
// the signed-in admin's token. The page holds no secrets.

export const SUPABASE_URL = "https://vncadogzpeoawikgafaj.supabase.co";
export const PUBLISHABLE_KEY = "sb_publishable_8ZM7KKxLHCzpUpfygmyFcA_5kK_PY2P";
export const ADMIN_URL = "https://gymcoapp.com/admin/";

// supabase-js comes from a CDN; null means it didn't load.
export const sb = window.supabase?.createClient(SUPABASE_URL, PUBLISHABLE_KEY) ?? null;

export class ApiError extends Error {
  constructor(status, code, body) {
    super(code);
    this.status = status;
    this.code = code;
    this.body = body;
  }
}

/** Hooks the app sets: what to do when the session or second factor is gone. */
export const onAuthLost = { handler: null };

export async function call(action, body = {}) {
  const { data } = await sb.auth.getSession();
  const token = data.session?.access_token;
  if (!token) {
    onAuthLost.handler?.("signed_out");
    throw new ApiError(401, "signed_out");
  }
  let res;
  try {
    res = await fetch(`${SUPABASE_URL}/functions/v1/admin`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, apikey: PUBLISHABLE_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ action, ...body }),
    });
  } catch {
    throw new ApiError(0, "offline");
  }
  let json = null;
  try {
    json = await res.json();
  } catch {
    // An empty or non-JSON body is reported by its status alone.
  }
  if (!res.ok) {
    const code = json?.error ?? "server";
    if (res.status === 401 || code === "mfa_required") onAuthLost.handler?.(code);
    throw new ApiError(res.status, code, json);
  }
  return json;
}
