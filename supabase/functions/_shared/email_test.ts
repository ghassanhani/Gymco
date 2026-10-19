import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.13";
import { FROM, resendSender } from "./email.ts";

Deno.test("resend: one POST with the support sender, bearer key and plain text", async () => {
  const calls: { url: string; init?: RequestInit }[] = [];
  const send = resendSender("re_123", (url, init) => {
    calls.push({ url, init });
    return Promise.resolve(new Response("{}", { status: 200 }));
  });
  await send({ to: "ana@example.com", subject: "Re: Restore", text: "Done." });
  assertEquals(calls[0].url, "https://api.resend.com/emails");
  assertEquals((calls[0].init?.headers as Record<string, string>).Authorization, "Bearer re_123");
  assertEquals(JSON.parse(String(calls[0].init?.body)), { from: FROM, to: ["ana@example.com"], subject: "Re: Restore", text: "Done." });
  assertEquals(FROM, "Gymco Support <support@gymcoapp.com>");
});

Deno.test("resend: a refusal is an error with the status", async () => {
  const send = resendSender("re_123", () => Promise.resolve(new Response('{"message":"nope"}', { status: 422 })));
  await assertRejects(() => send({ to: "a@b.co", subject: "s", text: "t" }), Error, "resend 422: nope");
});
