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
        tag="Sign-in code", or_tap="On your phone? One tap does it.", welcome_note="Your diary lives on your phone. Your account only keeps a backup, so a new phone picks up where you left off.", privacy="Privacy", terms="Terms", support="Help",
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
        tag="رمز الدخول", or_tap="على هاتفك؟ ضغطة واحدة تكفي.", welcome_note="مذكرتك تبقى على هاتفك. الحساب يحفظ نسخة احتياطية فقط، ليكمل أي هاتف جديد من حيث توقفت.", privacy="الخصوصية", terms="الشروط", support="المساعدة",
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
        tag="Código de acceso", or_tap="¿En tu teléfono? Basta un toque.", welcome_note="Tu diario vive en tu teléfono. Tu cuenta solo guarda una copia, para que un teléfono nuevo siga donde lo dejaste.", privacy="Privacidad", terms="Términos", support="Ayuda",
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
    al, rtl = t["align"], t["dir"] == "rtl"
    # A new account also hears where their diary lives.
    welcome = (
        f"""
      <tr><td style="padding:20px 28px 0;font-family:{FONT};text-align:{al};">
        <div style="background:#f4f5ef;border-radius:18px;padding:14px 16px;font-size:14px;line-height:1.5;color:#3b4038;">{t['welcome_note']}</div>
      </td></tr>"""
        if kind == "signup"
        else ""
    )
    return f"""
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" dir="{t['dir']}" style="background:#eef0e8;">
  <tr><td align="center" style="padding:28px 14px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:480px;background:#ffffff;border-radius:28px;overflow:hidden;box-shadow:0 12px 40px rgba(16,18,14,0.08);">
      <tr><td style="background:#0b0d09;background-image:radial-gradient(circle at {'0%' if rtl else '100%'} 0%,rgba(198,244,50,0.35) 0%,rgba(198,244,50,0) 55%),linear-gradient(160deg,#141a0e 0%,#0b0d09 70%);padding:28px 28px 30px;text-align:{al};font-family:{FONT};">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%"><tr>
          <td style="text-align:{al};"><img src="https://gymcoapp.com/icon.png" width="40" height="40" alt="Gymco" style="display:inline-block;vertical-align:middle;border:0;border-radius:12px;"><span style="display:inline-block;vertical-align:middle;{'margin-right' if rtl else 'margin-left'}:10px;font-size:19px;font-weight:800;color:#ffffff;letter-spacing:-0.3px;">Gymco</span></td>
          <td style="text-align:{'left' if rtl else 'right'};"><span style="display:inline-block;background:rgba(198,244,50,0.14);color:#c6f432;font-size:12px;font-weight:700;padding:6px 12px;border-radius:999px;border:1px solid rgba(198,244,50,0.35);">{t['tag']}</span></td>
        </tr></table>
        <h1 style="margin:26px 0 0;font-size:28px;line-height:1.18;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">{{{{ if $admin }}}}{t['h_admin']}{{{{ else }}}}{head}{{{{ end }}}}</h1>
        <p style="margin:10px 0 0;font-size:15.5px;line-height:1.55;color:#b9c1b1;">{{{{ if $admin }}}}{t['body_admin']}{{{{ else }}}}{t['body']}{{{{ end }}}}</p>
      </td></tr>
      <tr><td style="padding:28px 28px 0;font-family:{FONT};text-align:{al};">
        <div style="font-size:12px;font-weight:700;color:#6a7066;text-transform:uppercase;letter-spacing:1.2px;">{t['code']}</div>
        <div dir="ltr" style="margin-top:10px;background:#f6f8f0;border:1.5px solid #dfe8c4;border-radius:20px;padding:20px 12px;text-align:center;">
          <span style="font-family:'SF Mono','SFMono-Regular',Menlo,Consolas,monospace;font-size:40px;line-height:1;font-weight:800;letter-spacing:12px;color:#10120e;padding-left:12px;">{{{{ .Token }}}}</span>
          <div style="width:44px;height:4px;background:#c6f432;border-radius:4px;margin:14px auto 0;"></div>
        </div>
        <p style="margin:10px 0 0;font-size:13.5px;color:#6a7066;">{t['expiry']}</p>
      </td></tr>
      <tr><td style="padding:24px 28px 0;font-family:{FONT};text-align:{al};">
        <p style="margin:0 0 10px;font-size:14px;color:#3b4038;">{{{{ if not $admin }}}}{t['or_tap']}{{{{ end }}}}</p>
        <a href="{{{{ .ConfirmationURL }}}}" style="display:block;text-align:center;background:#c6f432;background-image:linear-gradient(90deg,#e4ff6e 0%,#c6f432 50%,#7fe08a 100%);color:#0a0b09;font-family:{FONT};font-size:16px;font-weight:800;text-decoration:none;padding:16px 24px;border-radius:999px;">{{{{ if $admin }}}}{t['cta_admin']}{{{{ else }}}}{t['cta']}{{{{ end }}}}</a>
      </td></tr>{welcome}
      <tr><td style="padding:26px 28px 28px;font-family:{FONT};text-align:{al};">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="border-top:1px solid #e6e9df;"><tr>
          <td width="28" valign="top" style="padding-top:18px;font-size:16px;line-height:1;color:#8a9085;">&#128274;</td>
          <td style="padding-top:18px;font-size:13px;line-height:1.55;color:#6a7066;">{t['ignore']}</td>
        </tr></table>
      </td></tr>
    </table>
    <p style="margin:20px 0 0;font-family:{FONT};font-size:12.5px;color:#8a9085;">
      <a href="https://gymcoapp.com/privacy/" style="color:#5f8a00;text-decoration:none;">{t['privacy']}</a> &nbsp;·&nbsp;
      <a href="https://gymcoapp.com/terms/" style="color:#5f8a00;text-decoration:none;">{t['terms']}</a> &nbsp;·&nbsp;
      <a href="https://gymcoapp.com/support/" style="color:#5f8a00;text-decoration:none;">{t['support']}</a>
    </p>
    <p style="margin:8px 0 0;font-family:{FONT};font-size:12px;color:#a0a69a;">Gymco · {t['foot']}</p>
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
<body style="margin:0;padding:0;background:#eef0e8;">
{branches}
{{{{ else }}}}{body("en", kind)}
{{{{ end }}}}
</body></html>
"""


if __name__ == "__main__":
    (HERE / "confirmation.html").write_text(page("signup"), encoding="utf-8")
    (HERE / "magic_link.html").write_text(page("signin"), encoding="utf-8")
    print("wrote confirmation.html and magic_link.html")
