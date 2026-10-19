// The published remote config as functions see it: read at most once a
// minute, with today's defaults when nothing is published and the last good
// copy when a read fails, so a database hiccup never stops a request.

import { validate } from "./config_schema.ts";

const TTL_MS = 60_000;

export function cachedConfig(read: () => Promise<unknown>, clock: () => number = Date.now) {
  let value: any = null;
  let at = -Infinity;
  return async (): Promise<any> => {
    if (value && clock() - at < TTL_MS) return value;
    try {
      value = validate((await read()) ?? {}).body;
    } catch {
      value ??= validate({}).body;
    }
    at = clock();
    return value;
  };
}

/** Reads the published body with a service-role client. */
// deno-lint-ignore no-explicit-any
export const publishedBody = (db: any) => async () => {
  const { data, error } = await db.from("remote_config").select("body").eq("status", "published").maybeSingle();
  if (error) throw error;
  return data?.body ?? null;
};
