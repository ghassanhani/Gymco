// Support replies by email through Resend. Behind a function so the routes
// can be handed a fake and the tests never send anything.

export const FROM = "Gymco Support <support@gymcoapp.com>";

export type SendEmail = (msg: { to: string; subject: string; text: string }) => Promise<void>;

type FetchFn = (url: string, init?: RequestInit) => Promise<Response>;

export function resendSender(apiKey: string, fetchFn: FetchFn = fetch): SendEmail {
  return async (msg) => {
    const r = await fetchFn("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: FROM, to: [msg.to], subject: msg.subject, text: msg.text }),
    });
    if (!r.ok) {
      const detail = (await r.json().catch(() => ({}))).message ?? "";
      throw new Error(`resend ${r.status}: ${detail}`);
    }
  };
}
