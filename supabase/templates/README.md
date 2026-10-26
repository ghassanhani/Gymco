# Sign-in emails

Gymco's own versions of the two emails Supabase Auth sends: a new account
(`confirmation.html`) and a returning sign-in (`magic_link.html`). Both carry
the sign-in button and the 6-digit code, come in English, Arabic or Spanish
(the account's `locale`, which the app sets), and switch to Control Center
wording when the sign-in comes from gymcoapp.com/admin.

Edit `build.py`, then run `python3 supabase/templates/build.py`. Never edit the
`.html` files by hand.

## Putting them live

The quick way: add the repository secret `SUPABASE_ACCESS_TOKEN` (supabase.com →
Account → Access tokens), and `RESEND_API_KEY` to send from Gymco, then run
Actions → **Sign-in emails**. It builds both emails and sets the subjects,
templates and SMTP below in one go.

### By hand (Supabase dashboard)

Authentication → Emails → Templates:

| Template       | Subject              | Body                          |
|----------------|----------------------|-------------------------------|
| Confirm signup | `{{ .Token }} · Gymco` | paste `confirmation.html` |
| Magic link     | `{{ .Token }} · Gymco` | paste `magic_link.html`   |

Authentication → Emails → SMTP settings (so emails come from Gymco, not
"Supabase Auth", and aren't held to Supabase's few-an-hour test limit):

- Sender email `hello@gymcoapp.com`, sender name `Gymco`
- Host `smtp.resend.com`, port `465`, username `resend`
- Password: a Resend API key with sending access to gymcoapp.com

Authentication → URL Configuration → Redirect URLs must list
`app.gymco.gymco://login-callback` and `https://gymcoapp.com/admin/`.
