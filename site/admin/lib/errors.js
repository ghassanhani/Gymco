// Plain words for a failed call: known server codes first, then network
// failures, then the caller's own line or a safe default.

const CODE_TEXT = {
  last_owner: "The last Owner can't be removed or demoted",
  forbidden: "Your role can't do that",
  is_admin: "Admins can't be deleted from Accounts. Remove them from the team first",
};

export const NETWORK_TEXT = "Couldn't reach the server";
export const FALLBACK_TEXT = "Something went wrong. Nothing was changed.";

/** A short sentence for a toast, from an ApiError or any thrown value. */
export function errorText(err, fallback) {
  const known = CODE_TEXT[err?.code];
  if (known) return known;
  // status 0 is the api's "offline"; a TypeError is fetch failing outright.
  if (err?.status === 0 || err instanceof TypeError) return NETWORK_TEXT;
  return fallback ?? FALLBACK_TEXT;
}
