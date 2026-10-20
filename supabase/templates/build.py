"""Builds the two sign-in emails Supabase sends from one source.

Supabase renders these with Go's html/template. The person's language comes
from user metadata (`locale`, set by the app at sign-up and after each sign-in);
the Control Center's own sign-in is told apart by its redirect address.

    python3 supabase/templates/build.py   # writes confirmation.html, magic_link.html
"""
from pathlib import Path

HERE = Path(__file__).parent

# Every string per language. {code} and {link} stay template variables.
T = {
    "en": dict(
        dir="ltr", align="left",
        h_signup="Welcome to Gymco", h_signin="Sign in to Gymco", h_admin="Sign in to the Control Center",
        body="Tap the button on your phone to sign in, or type this code in the app.",
        body_admin="Tap the button to open the Control Center, or type this code on the sign-in page.",
        cta="Sign in to Gymco", cta_admin="Open the Control Center",
        code="Your code", expiry="It works once, for the next hour.",
        ignore="Didn't ask for this? You can ignore this email. Nobody can sign in without the link or the code.",
        foot="Diet and training for lifters",
    ),
    "ar": dict(
        dir="rtl", align="right",
        h_signup="مرحبًا بك في Gymco", h_signin="سجّل الدخول إلى Gymco", h_admin="سجّل الدخول إلى مركز التحكم",
        body="اضغط الزر على هاتفك لتسجيل الدخول، أو اكتب هذا الرمز في التطبيق.",
        body_admin="اضغط الزر لفتح مركز التحكم، أو اكتب هذا الرمز في صفحة الدخول.",
        cta="تسجيل الدخول إلى Gymco", cta_admin="فتح مركز التحكم",
        code="رمزك", expiry="يعمل مرة واحدة خلال الساعة القادمة.",
        ignore="لم تطلب هذا؟ يمكنك تجاهل هذه الرسالة. لا يمكن لأحد الدخول دون الرابط أو الرمز.",
        foot="التغذية والتمرين لرافعي الأثقال",
    ),
    "es": dict(
        dir="ltr", align="left",
        h_signup="Te damos la bienvenida a Gymco", h_signin="Entra en Gymco", h_admin="Entra en el Control Center",
        body="Toca el botón en tu teléfono para entrar, o escribe este código en la app.",
        body_admin="Toca el botón para abrir el Control Center, o escribe este código en la página de acceso.",
        cta="Entrar en Gymco", cta_admin="Abrir el Control Center",
        code="Tu código", expiry="Sirve una vez, durante la próxima hora.",
        ignore="¿No lo pediste? Puedes ignorar este email. Nadie puede entrar sin el enlace o el código.",
        foot="Dieta y entrenamiento para levantadores",
    ),
}

ADMIN = "https://gymcoapp.com/admin/"


def body(lang: str, kind: str) -> str:
    t = T[lang]
    head = t["h_signup"] if kind == "signup" else t["h_signin"]
    return f"""
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" dir="{t['dir']}" style="background:#f4f5ef;">
  <tr><td align="center" style="padding:32px 16px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:480px;background:#ffffff;border-radius:24px;">
      <tr><td style="padding:32px 28px 8px;text-align:{t['align']};">
        <img src="https://gymcoapp.com/icon.png" width="48" height="48" alt="Gymco" style="display:block;border:0;border-radius:12px;{'margin-left:auto;' if t['dir']=='rtl' else ''}">
      </td></tr>
      <tr><td style="padding:16px 28px 0;text-align:{t['align']};font-family:{FONT};">
        <h1 style="margin:0;font-size:26px;line-height:1.2;font-weight:800;color:#10120e;letter-spacing:-0.4px;">{{{{ if $admin }}}}{t['h_admin']}{{{{ else }}}}{head}{{{{ end }}}}</h1>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.55;color:#3b4038;">{{{{ if $admin }}}}{t['body_admin']}{{{{ else }}}}{t['body']}{{{{ end }}}}</p>
      </td></tr>
      <tr><td style="padding:24px 28px 0;text-align:{t['align']};">
        <a href="{{{{ .ConfirmationURL }}}}" style="display:inline-block;background:#c6f432;color:#0a0b09;font-family:{FONT};font-size:16px;font-weight:700;text-decoration:none;padding:15px 28px;border-radius:999px;">{{{{ if $admin }}}}{t['cta_admin']}{{{{ else }}}}{t['cta']}{{{{ end }}}}</a>
      </td></tr>
      <tr><td style="padding:28px 28px 0;font-family:{FONT};text-align:{t['align']};">
        <div style="font-size:13px;font-weight:700;color:#6a7066;text-transform:uppercase;letter-spacing:1px;">{t['code']}</div>
        <div dir="ltr" style="margin-top:8px;background:#f4f5ef;border-radius:16px;padding:16px 20px;text-align:center;font-family:'SFMono-Regular',Menlo,Consolas,monospace;font-size:34px;font-weight:700;letter-spacing:8px;color:#10120e;">{{{{ .Token }}}}</div>
        <p style="margin:10px 0 0;font-size:14px;color:#6a7066;">{t['expiry']}</p>
      </td></tr>
      <tr><td style="padding:28px 28px 32px;font-family:{FONT};text-align:{t['align']};">
        <p style="margin:0;padding-top:20px;border-top:1px solid #e2e5dc;font-size:13px;line-height:1.5;color:#6a7066;">{t['ignore']}</p>
      </td></tr>
    </table>
    <p style="margin:18px 0 0;font-family:{FONT};font-size:12px;color:#8a9085;">Gymco · {t['foot']} · <a href="https://gymcoapp.com" style="color:#5f8a00;text-decoration:none;">gymcoapp.com</a></p>
  </td></tr>
</table>"""


FONT = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif"


def page(kind: str) -> str:
    branches = "\n".join(
        f"{{{{ {'if' if i == 0 else 'else if'} eq $lang \"{lang}\" }}}}{body(lang, kind)}"
        for i, lang in enumerate(["ar", "es"])
    )
    return f"""<!-- Built by supabase/templates/build.py. Edit that, not this file. -->
{{{{ $lang := "en" }}}}{{{{ with .Data }}}}{{{{ with .locale }}}}{{{{ $lang = printf "%v" . }}}}{{{{ end }}}}{{{{ end }}}}
{{{{ $admin := false }}}}{{{{ with .RedirectTo }}}}{{{{ if eq (printf "%v" .) "{ADMIN}" }}}}{{{{ $admin = true }}}}{{{{ end }}}}{{{{ end }}}}
<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light only"><meta name="supported-color-schemes" content="light"></head>
<body style="margin:0;padding:0;background:#f4f5ef;">
{branches}
{{{{ else }}}}{body("en", kind)}
{{{{ end }}}}
</body></html>
"""


if __name__ == "__main__":
    (HERE / "confirmation.html").write_text(page("signup"), encoding="utf-8")
    (HERE / "magic_link.html").write_text(page("signin"), encoding="utf-8")
    print("wrote confirmation.html and magic_link.html")
