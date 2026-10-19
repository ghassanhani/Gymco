// Saved replies for the support inbox, in the app's three languages.
// {email} is the account the ticket is about.

export interface T3 {
  en: string;
  ar: string;
  es: string;
}

export const TEMPLATES: Record<"deletion_confirmed" | "restore_help" | "cap_reset" | "nothing_stored", T3> = {
  deletion_confirmed: {
    en: "Hi,\n\nThe account {email} and its backup have been deleted. Nothing about you is left on our servers. Your diary on the phone is yours to keep or clear from the app's settings.\n\nThanks for trying Gymco.\n\nGymco Support",
    ar: "مرحبًا،\n\nتم حذف الحساب {email} ونسخته الاحتياطية. لم يبقَ أي شيء يخصك على خوادمنا. مذكراتك على الهاتف ملكك، يمكنك الاحتفاظ بها أو مسحها من إعدادات التطبيق.\n\nشكرًا لتجربتك Gymco.\n\nدعم Gymco",
    es: "Hola:\n\nLa cuenta {email} y su copia de seguridad se han eliminado. No queda nada tuyo en nuestros servidores. El diario de tu teléfono es tuyo: puedes conservarlo o borrarlo desde los ajustes de la app.\n\nGracias por probar Gymco.\n\nSoporte de Gymco",
  },
  restore_help: {
    en: "Hi,\n\nTo get your diary back on a new phone, install Gymco and sign in under Me → Account with {email}. The last backup from your old phone is restored on the first launch after signing in. If the old phone is still around, open the app there once so the backup is fresh.\n\nGymco Support",
    ar: "مرحبًا،\n\nلاستعادة مذكراتك على هاتف جديد، ثبّت Gymco وسجّل الدخول من أنا ← الحساب باستخدام {email}. تُستعاد آخر نسخة احتياطية من هاتفك القديم عند أول فتح بعد تسجيل الدخول. إذا كان الهاتف القديم ما زال معك، افتح التطبيق عليه مرة واحدة لتكون النسخة حديثة.\n\nدعم Gymco",
    es: "Hola:\n\nPara recuperar tu diario en un teléfono nuevo, instala Gymco e inicia sesión en Yo → Cuenta con {email}. La última copia de seguridad de tu teléfono anterior se restaura la primera vez que abres la app tras iniciar sesión. Si aún tienes el teléfono anterior, abre la app ahí una vez para que la copia esté al día.\n\nSoporte de Gymco",
  },
  cap_reset: {
    en: "Hi,\n\nToday's photo scans for {email} have been reset, so you can keep logging. The daily limit keeps the AI costs in check; writing a meal in plain words is always unlimited.\n\nGymco Support",
    ar: "مرحبًا،\n\nتمت إعادة ضبط مسح الصور لهذا اليوم للحساب {email}، فيمكنك متابعة التسجيل. الحد اليومي يبقي تكاليف الذكاء الاصطناعي تحت السيطرة؛ كتابة الوجبة بكلمات عادية غير محدودة دائمًا.\n\nدعم Gymco",
    es: "Hola:\n\nSe han restablecido los escaneos de fotos de hoy para {email}, así que puedes seguir registrando. El límite diario mantiene a raya los costes de IA; escribir una comida con palabras normales siempre es ilimitado.\n\nSoporte de Gymco",
  },
  nothing_stored: {
    en: "Hi,\n\nWe looked, and there is no account or backup under {email}. Gymco keeps your diary on your phone; nothing reaches our servers unless you sign in and turn on backup. So there is nothing of yours to delete on our side.\n\nGymco Support",
    ar: "مرحبًا،\n\nبحثنا ولم نجد أي حساب أو نسخة احتياطية باسم {email}. يحتفظ Gymco بمذكراتك على هاتفك؛ لا يصل شيء إلى خوادمنا ما لم تسجّل الدخول وتفعّل النسخ الاحتياطي. لذلك لا يوجد شيء يخصك لنحذفه من جهتنا.\n\nدعم Gymco",
    es: "Hola:\n\nLo hemos comprobado y no hay ninguna cuenta ni copia de seguridad con {email}. Gymco guarda tu diario en tu teléfono; nada llega a nuestros servidores a menos que inicies sesión y actives la copia de seguridad. Así que no hay nada tuyo que eliminar por nuestra parte.\n\nSoporte de Gymco",
  },
};

export const fillTemplate = (text: string, email: string) => text.replaceAll("{email}", email);
