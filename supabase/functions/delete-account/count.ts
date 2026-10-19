/** Counts a deletion for the admin dashboard. Never throws: a counter that is
 * down must not turn a finished delete into a failure. True when counted. */
export async function noteDeletion(call: () => PromiseLike<{ error: unknown }>): Promise<boolean> {
  try {
    return (await call()).error == null;
  } catch {
    return false;
  }
}
