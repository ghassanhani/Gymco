// Remote config: one versioned JSON body for the whole app, edited through
// forms on the dashboard and read by phones through app-config.

import { defaults, ownerKeysChanged, SCHEMA, UNTARGETABLE, validate } from "../_shared/config_schema.ts";
import { ok, type Route } from "./handler.ts";
import { versionedRoutes } from "./versioned.ts";

const routes = versionedRoutes("config", {
  table: "remote_config",
  section: "config",
  validate: (body) => Promise.resolve(validate(body)),
  ownerKeys: ownerKeysChanged,
  base: () => defaults(),
});

// The dashboard builds its forms from the schema.
const get = routes["config.get"];
export const configRoutes: Record<string, Route> = {
  ...routes,
  "config.get": {
    cap: get.cap,
    run: async (ctx, body) => {
      const r = await get.run(ctx, body);
      return r.status === 200 ? ok({ ...(r.body as object), schema: SCHEMA, defaults: defaults(), untargetable: UNTARGETABLE }) : r;
    },
  },
};
