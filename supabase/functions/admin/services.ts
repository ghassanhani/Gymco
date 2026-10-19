// The outside services the admin routes touch (FCM, GitHub, Resend), read
// from secrets when a route runs and handed in as fakes by the tests.

import { resendSender, type SendEmail } from "../_shared/email.ts";
import { DEFAULT_REPO, type GitHub, githubClient } from "../_shared/github.ts";

export interface Services {
  /** True only when the FCM_SERVICE_ACCOUNT secret exists. */
  fcmConfigured(): boolean;
  /** Null without GITHUB_TOKEN. */
  github(): GitHub | null;
  /** Null without RESEND_API_KEY. */
  email(): SendEmail | null;
  now(): Date;
}

const env = (k: string) => {
  try {
    return Deno.env.get(k) || undefined;
  } catch {
    return undefined;
  }
};

export function envServices(): Services {
  return {
    fcmConfigured: () => !!env("FCM_SERVICE_ACCOUNT"),
    github: () => {
      const token = env("GITHUB_TOKEN");
      return token ? githubClient({ token, repo: env("GITHUB_REPO") ?? DEFAULT_REPO }) : null;
    },
    email: () => {
      const key = env("RESEND_API_KEY");
      return key ? resendSender(key) : null;
    },
    now: () => new Date(),
  };
}

/** Nothing configured and a fixed clock, for tests; override what a test needs. */
export function fakeServices(over: Partial<Services> = {}): Services {
  return {
    fcmConfigured: () => false,
    github: () => null,
    email: () => null,
    now: () => new Date("2026-10-20T12:00:00Z"),
    ...over,
  };
}
