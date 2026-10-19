// Made-up answers from the admin function, for the screenshot harness.
// None of this is real user data.

const days = (n) => Array.from({ length: n }, (_, i) => new Date(Date.UTC(2026, 9, 19 - (n - 1) + i)).toISOString().slice(0, 10));
const wave = (base, i, amp = 0.5) => Math.max(0, Math.round(base * (1 + amp * Math.sin(i / 5)) + i * base * 0.01));

export function stats(empty) {
  const d = days(90);
  return {
    range: 90,
    accounts: empty ? 0 : 1284,
    signups_today: empty ? 0 : 21,
    signups_7d: empty ? 0 : 148,
    signups_30d: empty ? 0 : 560,
    active_7d: empty ? 0 : 412,
    active_30d: empty ? 0 : 903,
    scans_today: empty ? 0 : 162,
    cost_today: empty ? 0 : 0.081,
    cost_month: empty ? 0 : 1.37,
    at_cap_today: empty ? 0 : 4,
    deletions_30d: empty ? 0 : 6,
    signups: d.map((day, i) => ({ day, n: empty ? 0 : wave(12 + i / 4, i) })),
    scans: d.map((day, i) => { const n = empty ? 0 : wave(110, i, 0.4); return { day, n, cost: +(n * 0.0005).toFixed(4) }; }),
    deletions: d.map((day, i) => ({ day, n: empty ? 0 : i % 13 === 0 ? 1 : 0 })),
    ai_failure_rate_today: 0,
    backups: { count: empty ? 0 : 1190, bytes: empty ? 0 : 38_400_000 },
    db_bytes: empty ? 9_100_000 : 61_700_000,
    mix: empty ? { locale: {}, platform: {}, app_version: {} } : { locale: { en: 610, ar: 330, es: 120, unknown: 130 }, platform: { ios: 700, android: 360, unknown: 130 }, app_version: { "1.0.2": 900, "1.0.1": 160, unknown: 130 } },
    generated_at: "2026-10-19T14:05:00Z",
  };
}

const card = {
  user_id: "u-1",
  email: "user@example.com",
  created_at: "2026-03-12T10:00:00Z",
  last_sign_in_at: "2026-10-18T20:00:00Z",
  backup: { updated_at: "2026-10-19T12:14:00Z", bytes: 4_200_000, platform: "ios", locale: "ar", app_version: "1.0.2" },
  scans_today: 10,
  scans_30d: 142,
  cap_today: 10,
  grant_today: null,
  entitlement: null,
  notes: [{ note: "Emailed about restore issue, asked for app version.", by: "owner@gymco.test", at: "2026-10-17T09:00:00Z" }],
  is_admin: false,
};

const audit = [
  { id: 5, at: "2026-10-19T09:42:00Z", admin_email: "owner@gymco.test", section: "accounts", action: "reset_cap", object_id: "u-1", reason: "support_ticket", before: null, after: { scans_today: 0 } },
  { id: 4, at: "2026-10-18T16:00:00Z", admin_email: "owner@gymco.test", section: "team", action: "invite", object_id: "helper@gymco.test", reason: null, before: null, after: { email: "helper@gymco.test", role: "support" } },
  { id: 3, at: "2026-10-17T11:00:00Z", admin_email: "owner@gymco.test", section: "accounts", action: "delete_account", object_id: "u-9", reason: "deletion_request", before: { account: true }, after: { account: false } },
];

const admins = [
  { user_id: "u-owner", email: "owner@gymco.test", role: "owner", mfa: true, last_sign_in_at: "2026-10-19T08:00:00Z" },
  { user_id: "u-help", email: "helper@gymco.test", role: "support", mfa: false, last_sign_in_at: null },
];

// The real schema, so the form is drawn exactly as the server describes it.
const { SCHEMA, defaults } = await import("../../supabase/functions/_shared/config_schema.ts");

function configGet(empty, review) {
  const base = defaults();
  // Settings the server refuses in targeting rules (dotted keys).
  const untargetable = ["limits.ai_scans_per_day"];
  if (empty) return { base, published: null, draft: null, diff: [], history: [], schema: SCHEMA, defaults: base, untargetable };
  const pub = structuredClone(base);
  pub.rules = [
    { key: "features.monthly_challenge", value: true, target: { locale: "ar", percent: 50 } },
    { key: "features.monthly_challenge", value: true, target: { locale: "es", percent: 50 } },
  ];
  pub.app_gate.min_build_ios = 102;
  pub.app_gate.min_build_android = 102;
  pub.app_gate.recommended_build = 102;
  pub.ai.rollout_percent = 20;
  const draft = structuredClone(pub);
  draft.limits.ai_scans_per_day = 12;
  draft.features.cheat_meals = false;
  draft.water.ml_per_kg = 33;
  const at = "2026-10-18T09:00:00Z";
  return {
    base,
    published: { version: 18, status: "published", body: pub, created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: at },
    draft: { version: 19, status: review ? "in_review" : "draft", body: draft, created_by: "editor@gymco.test", submitted_by: review ? "editor@gymco.test" : null },
    diff: [],
    history: [
      { version: 19, status: review ? "in_review" : "draft", created_by: "editor@gymco.test", created_at: "2026-10-19T08:00:00Z", note: "Raise cap for Ramadan" },
      { version: 18, status: "published", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: at, note: "Gate below build 102" },
      { version: 17, status: "archived", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-10-10T09:00:00Z", note: null },
    ],
    schema: SCHEMA,
    defaults: base,
    untargetable,
  };
}


// Content packs: obviously sample content, one realistic draft per kind.
const { checkBody, KINDS } = await import("../../site/admin/lib/packs_form.js");
const T = (en, ar, es) => ({ en, ar, es });
const PACKS = {
  foods: {
    published: { items: [
      { id: "hummus", name: T("Hummus", "حمص", "Hummus"), kcal: 166, protein: 7.9, carbs: 14.3, fat: 9.6, serving_g: 60 },
      { id: "ful_medames", name: T("Ful medames", "فول مدمس", "Ful medames"), kcal: 110, protein: 7.6, carbs: 15, fat: 2.6, serving_g: 200 },
      { id: "khubz", name: T("Arabic bread", "خبز عربي", "Pan árabe"), kcal: 275, protein: 9.1, carbs: 55.7, fat: 1.2, serving_g: 60 },
    ] },
    add: [{ id: "labneh", name: T("Labneh", "لبنة", "Labneh"), kcal: 160, protein: 10, carbs: 4, fat: 17.3, serving_g: 30 }],
  },
  vocabulary: {
    published: { units: [
      { word: "scoop", lang: "en", unit: "scoop" }, { word: "handful", lang: "en", unit: "handful" },
      { word: "كوب", lang: "ar", unit: "cup" }, { word: "ملعقة", lang: "ar", unit: "tbsp" },
      { word: "cacito", lang: "es", unit: "scoop" }, { word: "rebanada", lang: "es", unit: "slice" },
    ] },
    add: [{ word: "puñado", lang: "es", unit: "handful" }],
  },
  eating_out: {
    published: { dishes: [
      { id: "shawarma_wrap", group: "main", name: T("Chicken shawarma wrap", "شاورما دجاج", "Shawarma de pollo"), g: 300, kcal: 620, p: 32, c: 55, f: 28 },
      { id: "falafel_plate", group: "main", name: T("Falafel plate", "صحن فلافل", "Plato de falafel"), g: 350, kcal: 710, p: 22, c: 78, f: 34 },
      { id: "fattoush", group: "side", name: T("Fattoush", "فتوش", "Fattoush"), g: 200, kcal: 180, p: 3, c: 18, f: 11 },
    ] },
    add: [{ id: "fries_small", group: "side", name: T("Fries, small", "بطاطا مقلية صغيرة", "Patatas fritas pequeñas"), g: 110, kcal: 320, p: 4, c: 41, f: 15 }],
  },
  exercises: {
    published: { items: [
      { id: "Landmine_Press", name: T("Landmine press", "ضغط اللاندماين", "Press landmine"), primary: ["shoulders"], secondary: ["triceps", "chest"], equipment: "barbell", level: "intermediate", images: ["Landmine_Press/0.jpg", "Landmine_Press/1.jpg"] },
      { id: "Sissy_Squat", name: T("Sissy squat", "سكوات سيسي", "Sentadilla sissy"), primary: ["quadriceps"], secondary: [], equipment: "body only", level: "expert" },
    ], removed: [] },
    add: [
      { id: "Barbell_Bench_Press_-_Medium_Grip", name: T("Barbell bench press", "ضغط البنش بالبار", "Press de banca con barra"), primary: ["chest"], secondary: ["triceps", "shoulders"], equipment: "barbell", level: "intermediate", images: ["Barbell_Bench_Press_-_Medium_Grip/0.jpg", "Barbell_Bench_Press_-_Medium_Grip/1.jpg"], instructions: ["Lie on the bench with your eyes under the bar.", "Lower the bar to mid-chest, then press up."] },
      { id: "Cable_Face_Pull", name: T("Cable face pull", "سحب الوجه بالكابل", ""), primary: ["shoulders"], secondary: ["traps", "middle back"], equipment: "cable", level: "beginner" },
    ],
    removed: ["Barbell_Hip_Thrust"],
  },
  templates: {
    published: { items: [] },
    add: [{
      id: "ppl_3day", name: T("Push Pull Legs · 3 days", "دفع سحب أرجل · 3 أيام", "Empuje, tirón, pierna · 3 días"), level: "intermediate",
      routines: [
        { name: T("Push", "دفع", "Empuje"), weekday: 0, items: [
          { exercise: "Barbell_Bench_Press_-_Medium_Grip", sets: 4, rep_low: 6, rep_high: 10, rest_s: 150, rir: 2 },
          { exercise: "Standing_Military_Press", sets: 3, rep_low: 6, rep_high: 10, rest_s: 120, rir: 2 },
          { exercise: "Side_Lateral_Raise", sets: 3, rep_low: 12, rep_high: 20, rest_s: 60 },
          { exercise: "Triceps_Pushdown", sets: 3, rep_low: 10, rep_high: 15, rest_s: 60 },
        ] },
        { name: T("Pull", "سحب", "Tirón"), weekday: 2, items: [
          { exercise: "Weighted_Pull_Ups", sets: 4, rep_low: 5, rep_high: 8, rest_s: 150, rir: 2 },
          { exercise: "Bent_Over_Barbell_Row", sets: 3, rep_low: 6, rep_high: 10, rest_s: 120 },
          { exercise: "Face_Pull", sets: 3, rep_low: 12, rep_high: 20, rest_s: 60 },
          { exercise: "Hammer_Curls", sets: 3, rep_low: 10, rep_high: 15, rest_s: 60 },
        ] },
        { name: T("Legs", "أرجل", "Pierna"), weekday: 4, items: [
          { exercise: "Barbell_Squat", sets: 4, rep_low: 5, rep_high: 8, rest_s: 180, rir: 2 },
          { exercise: "Romanian_Deadlift", sets: 3, rep_low: 6, rep_high: 10, rest_s: 150 },
          { exercise: "Leg_Extensions", sets: 3, rep_low: 10, rep_high: 15, rest_s: 60 },
          { exercise: "Standing_Calf_Raises", sets: 3, rep_low: 10, rep_high: 15, rest_s: 60 },
        ] },
      ],
    }],
  },
  awards: {
    published: { items: [
      { id: "logged_30", name: T("Logged 30 days", "30 يوماً من التسجيل", "30 días registrados"), description: T("Thirty full days in the diary.", "ثلاثون يوماً كاملاً في اليوميات.", "Treinta días completos en el diario."), metric: "logged_days", threshold: 30 },
      { id: "trained_12", name: T("Trained 12 times", "تمرنت 12 مرة", "12 entrenos"), description: T("Twelve workouts finished.", "أنهيت اثني عشر تمريناً.", "Doce entrenos terminados."), metric: "workouts", threshold: 12 },
    ] },
    add: [{ id: "lost_5kg", name: T("Lost 5 kg", "خسرت 5 كغ", "Perdiste 5 kg"), description: T("Drop five kilos in a month.", "اخسر خمسة كيلوغرامات في شهر.", "Baja cinco kilos en un mes."), metric: "logged_days", threshold: 30 }],
  },
  challenges: {
    published: { items: [{ month: "2026-10", title: T("Train 12 times in October", "تمرن 12 مرة في أكتوبر", "Entrena 12 veces en octubre"), target: 12 }] },
    add: [{ month: "2026-11", title: T("Train 14 times in November", "تمرن 14 مرة في نوفمبر", "Entrena 14 veces en noviembre"), target: 14 }],
  },
  copy: {
    published: { overrides: { emptyDayTitle: T("A fresh start", "بداية جديدة", "Un nuevo comienzo") } },
    add: { remindMealBody: T("Two seconds: write what you ate.", "", "Dos segundos: escribe lo que comiste.") },
  },
};

function packBody(kind, which) {
  const p = PACKS[kind];
  const body = structuredClone(p.published);
  if (which === "published") return body;
  if (kind === "copy") Object.assign(body.overrides, structuredClone(p.add));
  else body[Object.keys(body).find((k) => Array.isArray(body[k]))].push(...structuredClone(p.add));
  if (p.removed) body.removed = [...p.removed];
  return body;
}

const packBase = (kind) => (kind === "copy" ? { overrides: {} } : { [KINDS.find((k) => k.id === kind).list]: [] });
const packCount = (kind, body) => (kind === "copy" ? Object.keys(body.overrides).length : Object.values(body).find(Array.isArray).length);

/** The server's checks: the contract's, plus the one only it can do (templates use a removed exercise). */
export function packCheck(kind, body) {
  const r = checkBody(kind, body);
  if (kind === "exercises" && body.removed?.includes("Barbell_Hip_Thrust")) {
    r.errors.push({ key: `removed.${body.removed.indexOf("Barbell_Hip_Thrust")}`, message: "Removes “Barbell_Hip_Thrust”, used in 2 templates" });
  }
  return { ok: !r.errors.length, ...r };
}

function packsGet(kind, empty, review) {
  const summary = KINDS.map((k) => ({
    kind: k.id, published_version: empty ? null : 3 + KINDS.indexOf(k) * 2, draft_status: empty ? null : k.id === kind && review ? "in_review" : "draft",
    items: empty ? 0 : packCount(k.id, packBody(k.id, "draft")),
  }));
  if (empty) return { base: packBase(kind), published: null, draft: null, diff: [], history: [], warnings: [], summary };
  const v = summary.find((s) => s.kind === kind).published_version;
  const draft = packBody(kind, "draft");
  return {
    base: packBase(kind),
    published: { version: v, status: "published", body: packBody(kind, "published"), created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-10-12T09:00:00Z" },
    draft: { version: v + 1, status: review ? "in_review" : "draft", body: draft, created_by: "editor@gymco.test", submitted_by: review ? "editor@gymco.test" : null },
    diff: [],
    history: [
      { version: v + 1, status: review ? "in_review" : "draft", created_by: "editor@gymco.test", created_at: "2026-10-19T08:00:00Z", note: "Sample additions" },
      { version: v, status: "published", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-10-12T09:00:00Z", note: null },
      { version: v - 1, status: "archived", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-10-01T09:00:00Z", note: "First pack" },
    ],
    warnings: packCheck(kind, draft).warnings,
    summary,
  };
}

const grants = [
  { user_id: "u-7", email: "tester1@example.com", plan: "pro", expires_at: "2026-12-31T23:59:59Z", granted_at: "2026-10-02T10:00:00Z", granted_by: "owner@gymco.test" },
  { user_id: "u-8", email: "press@example.com", plan: "lifetime", expires_at: null, granted_at: "2026-09-20T15:30:00Z", granted_by: "owner@gymco.test" },
];


// ---- Phase 4: messaging, support, releases, website, health (all made up)
const announcements = [
  { id: "a1", title: T("Monthly challenges are here", "تحديات الشهر وصلت", "Llegaron los retos mensuales"), body: T("Train 12 times in October to earn this month’s badge.", "تمرّن 12 مرة في أكتوبر لتحصل على شارة الشهر.", "Entrena 12 veces en octubre para ganar la insignia del mes."),
    cta: { label: T("See challenge", "شاهد التحدي", "Ver el reto"), url: "https://gymcoapp.com/challenge" }, starts_at: "2026-10-01T00:00:00Z", ends_at: "2026-10-31T23:59:00Z", targeting: {}, status: "published", created_by: "editor@gymco.test", published_by: "owner@gymco.test" },
  { id: "a2", title: T("Backup maintenance Sunday", "صيانة النسخ الاحتياطي الأحد", "Mantenimiento de copias el domingo"), body: T("Burn off the weekend with this challenge! Backups pause for an hour on Sunday 02:00 UTC.", "", "Las copias se pausan una hora el domingo a las 02:00 UTC."),
    cta: null, starts_at: "2026-10-25T00:00:00Z", ends_at: "2026-10-26T12:00:00Z", targeting: { platform: "ios", min_build: 101 }, status: "draft", created_by: "editor@gymco.test", published_by: null },
  { id: "a3", title: T("Welcome to the beta", "مرحباً بك في النسخة التجريبية", "Bienvenido a la beta"), body: T("Thanks for testing. Tell us what breaks.", "شكراً للتجربة. أخبرنا بما يتعطل.", "Gracias por probar. Cuéntanos qué falla."),
    cta: null, starts_at: "2026-08-01T00:00:00Z", ends_at: "2026-09-01T00:00:00Z", targeting: { locale: "en" }, status: "archived", created_by: "owner@gymco.test", published_by: "owner@gymco.test" },
];

const campaigns = [
  { id: "p1", title: T("New: Eating out estimates", "جديد: تقديرات الأكل خارج المنزل", "Nuevo: estimaciones al comer fuera"), body: T("Log a restaurant meal in two taps.", "سجّل وجبة مطعم بنقرتين.", "Registra una comida de restaurante en dos toques."), send_at_local: "2026-10-23T09:30", targeting: {}, status: "scheduled", sent_count: 0, created_by: "owner@gymco.test" },
  { id: "p2", title: T("Challenge starts Monday", "التحدي يبدأ الاثنين", "El reto empieza el lunes"), body: T("Twelve workouts in October. You in?", "اثنا عشر تمريناً في أكتوبر. هل أنت مستعد؟", "Doce entrenos en octubre. ¿Te apuntas?"), send_at_local: "2026-10-05T10:00", targeting: { locale: "en" }, status: "sent", sent_count: 812, created_by: "owner@gymco.test" },
  { id: "p3", title: T("Backup reminder", "تذكير بالنسخ الاحتياطي", "Recordatorio de copia"), body: T("Turn on backup so a new phone keeps your diary.", "فعّل النسخ الاحتياطي ليحتفظ هاتفك الجديد بيومياتك.", "Activa la copia para que un móvil nuevo conserve tu diario."), send_at_local: "2026-11-03T18:00", targeting: { platform: "android" }, status: "draft", sent_count: 0, created_by: "editor@gymco.test" },
];

const tickets = [
  { id: "t1", email: "user@example.com", subject: "Please delete my account", locale: "ar", app_version: "1.0.2", platform: "ios", kind: "deletion", status: "new", tags: ["deletion"], source: "email", created_at: "2026-10-16T09:00:00Z", updated_at: "2026-10-16T09:00:00Z", deadline_at: "2026-11-15T09:00:00Z", has_account: true,
    body: "Hi, I no longer use the app. Please delete my account and any backup you keep. Thanks." },
  { id: "t2", email: "sam@example.com", subject: "Restore failed after new phone", locale: "en", app_version: "1.0.1", platform: "android", kind: "general", status: "new", tags: ["bug"], source: "app", created_at: "2026-10-17T20:10:00Z", updated_at: "2026-10-17T20:10:00Z", deadline_at: null, has_account: true,
    body: "Restore says 'backup not found' but I had backup on. Android 14, Pixel 7." },
  { id: "t3", email: "lee@example.com", subject: "Scan cap reached on day one", locale: "es", app_version: "1.0.2", platform: "ios", kind: "general", status: "new", tags: [], source: "email", created_at: "2026-10-19T11:30:00Z", updated_at: "2026-10-19T11:30:00Z", deadline_at: null, has_account: false,
    body: "Hola, me dice que llegué al límite de escaneos pero solo hice tres." },
  { id: "t4", email: "nina@example.com", subject: "Feature idea: water reminders", locale: "en", app_version: "1.0.2", platform: "android", kind: "general", status: "new", tags: ["feature idea"], source: "app", created_at: "2026-10-19T13:50:00Z", updated_at: "2026-10-19T13:50:00Z", deadline_at: null, has_account: true, body: "Would love a reminder for water every two hours." },
  { id: "t5", email: "omar@example.com", subject: "Delete my data", locale: "ar", app_version: "1.0.0", platform: "ios", kind: "deletion", status: "waiting", tags: ["deletion"], source: "email", created_at: "2026-09-17T10:00:00Z", updated_at: "2026-10-10T10:00:00Z", deadline_at: "2026-10-17T10:00:00Z", has_account: false,
    body: "احذفوا بياناتي من فضلكم." },
  { id: "t6", email: "ana@example.com", subject: "Billing question", locale: "es", app_version: "1.0.2", platform: "ios", kind: "general", status: "waiting", tags: ["billing"], source: "email", created_at: "2026-10-12T08:00:00Z", updated_at: "2026-10-18T08:00:00Z", deadline_at: null, has_account: true, body: "¿Cuándo llega el plan Pro?" },
  { id: "t7", email: "jo@example.com", subject: "Spanish typo on Today", locale: "es", app_version: "1.0.1", platform: "android", kind: "general", status: "waiting", tags: ["bug"], source: "app", created_at: "2026-10-14T08:00:00Z", updated_at: "2026-10-18T08:00:00Z", deadline_at: null, has_account: true, body: "Dice 'calorias' sin tilde." },
  { id: "t8", email: "kim@example.com", subject: "Thanks!", locale: "en", app_version: "1.0.2", platform: "ios", kind: "general", status: "solved", tags: [], source: "email", created_at: "2026-10-02T08:00:00Z", updated_at: "2026-10-02T09:00:00Z", deadline_at: null, has_account: false, body: "Just wanted to say the app is lovely." },
];
const ticketMessages = { t1: [{ id: "m1", from_admin: true, author: "owner@gymco.test", body: "Got it. Deleting your account now; you will get a confirmation.", at: "2026-10-18T09:00:00Z" }], t5: [{ id: "m2", from_admin: true, author: "helper@gymco.test", body: "Could you confirm the email you signed up with?", at: "2026-10-10T10:00:00Z" }] };
const NOW = new Date("2026-10-19T14:05:00Z");
const ticketCounts = (list) => ({
  new: list.filter((t) => t.status === "new").length, waiting: list.filter((t) => t.status === "waiting").length, solved: list.filter((t) => t.status === "solved").length,
  deletion_open: list.filter((t) => t.kind === "deletion" && t.status !== "solved").length,
  overdue: list.filter((t) => t.kind === "deletion" && t.status !== "solved" && t.deadline_at && new Date(t.deadline_at) < NOW).length,
});
function ticketsList(tab, q, empty) {
  const all = empty ? [] : tickets;
  let items = tab === "deletion" ? all.filter((t) => t.kind === "deletion").sort((a, b) => new Date(a.deadline_at) - new Date(b.deadline_at)) : all.filter((t) => t.status === tab);
  if (q) items = items.filter((t) => `${t.subject} ${t.email} ${t.tags.join(" ")}`.toLowerCase().includes(q.toLowerCase()));
  return { items: items.map(({ body, ...t }) => t), counts: ticketCounts(all) };
}
const templates = {
  deletion_confirmed: T("Hi,\n\nYour Gymco account for {email} and its backup have been deleted. Nothing about you remains on our servers. The diary on your phone is yours to keep or remove.\n\nGymco support", "مرحباً،\n\nتم حذف حساب Gymco الخاص بـ {email} ونسخته الاحتياطية. لم يبقَ أي شيء عنك على خوادمنا.\n\nدعم Gymco", "Hola:\n\nTu cuenta de Gymco para {email} y su copia se han eliminado. No queda nada tuyo en nuestros servidores.\n\nSoporte de Gymco"),
  restore_help: T("Hi,\n\nRestore looks for a backup under the email you sign in with ({email}). Please sign in with that exact email, then Me → Backup → Restore. If it still fails, send us the app version.\n\nGymco support", "مرحباً،\n\nتبحث الاستعادة عن نسخة احتياطية تحت البريد الذي تسجّل الدخول به ({email}).\n\nدعم Gymco", "Hola:\n\nLa restauración busca una copia con el correo con el que inicias sesión ({email}).\n\nSoporte de Gymco"),
  cap_reset: T("Hi,\n\nWe reset today’s photo scan allowance for {email}. You can scan again right away.\n\nGymco support", "مرحباً،\n\nأعدنا ضبط حصة مسح الصور لليوم لـ {email}.\n\nدعم Gymco", "Hola:\n\nHemos restablecido el límite de escaneos de hoy para {email}.\n\nSoporte de Gymco"),
  nothing_stored: T("Hi,\n\nThere is no Gymco account for {email}, so nothing about you is stored on our servers. Your diary lives only on your phone.\n\nGymco support", "مرحباً،\n\nلا يوجد حساب Gymco لـ {email}، لذا لا نحتفظ بأي شيء عنك على خوادمنا.\n\nدعم Gymco", "Hola:\n\nNo hay ninguna cuenta de Gymco para {email}, así que no guardamos nada tuyo.\n\nSoporte de Gymco"),
};

const releaseNotes = [
  { build: 103, version: "1.0.3", body: T("Eating out estimates for common restaurant dishes\nFaster photo logging\nFixes for backup restore", "", "Estimaciones al comer fuera para platos comunes\nRegistro de fotos más rápido\nArreglos en la restauración de copias"), published: false },
  { build: 102, version: "1.0.2", body: T("Monthly challenges\nArabic unit words in Write", "تحديات شهرية\nكلمات الوحدات العربية في الكتابة", "Retos mensuales\nUnidades en árabe al escribir"), published: true },
];
const runs = [
  { id: 9101, name: "Release", sha7: "a1b2c3d", status: "failed", when: "2026-10-19T10:12:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9101" },
  { id: 9100, name: "iOS test build", sha7: "a1b2c3d", status: "passed", when: "2026-10-19T09:40:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9100" },
  { id: 9099, name: "CI", sha7: "a1b2c3d", status: "running", when: "2026-10-19T13:58:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9099" },
  { id: 9080, name: "Website", sha7: "f00dcaf", status: "passed", when: "2026-10-18T16:02:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9080" },
  { id: 9079, name: "Mirror to iFynx", sha7: "f00dcaf", status: "queued", when: "2026-10-18T16:03:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9079" },
];
const releasesGet = (empty, github) => ({
  runs: github && !empty ? runs : [],
  versions: empty ? [] : [{ build: 102, pct: 70 }, { build: 101, pct: 18 }, { build: 100, pct: 8 }, { build: "unknown", pct: 4 }],
  gate: { min_build_ios: 102, min_build_android: 102, recommended_build: 102 },
  notes: empty ? [] : releaseNotes,
  github,
  mirror: "iFynx/Gymco",
});

const WEB_PAGES = { home: "Home", support: "Support", privacy: "Privacy policy", terms: "Terms", "delete-account": "Account deletion" };
const webBody = (page, v) => ({
  title: T(WEB_PAGES[page], { home: "الرئيسية", support: "الدعم", privacy: "سياسة الخصوصية", terms: "الشروط", "delete-account": "حذف الحساب" }[page], { home: "Inicio", support: "Soporte", privacy: "Política de privacidad", terms: "Términos", "delete-account": "Eliminar la cuenta" }[page]),
  markdown: T(`# ${WEB_PAGES[page]}\n\nYour diary lives on your phone.\n\n## What we keep\n- Your email, to sign you in\n- An optional encrypted backup\n\n## What we never collect\n- Usage analytics or trackers${v > 4 ? "\n- Photos: they are scanned and discarded" : ""}\n\nQuestions? Write to [support@gymcoapp.com](mailto:support@gymcoapp.com).`,
    `# ${WEB_PAGES[page] === "Privacy policy" ? "سياسة الخصوصية" : WEB_PAGES[page]}\n\nيومياتك تبقى على هاتفك.\n\n## ما نحتفظ به\n- بريدك الإلكتروني لتسجيل الدخول\n- نسخة احتياطية مشفّرة اختيارية`,
    v > 4 ? "" : `# ${WEB_PAGES[page]}\n\nTu diario vive en tu teléfono.\n\n## Lo que guardamos\n- Tu correo, para iniciar sesión\n- Una copia cifrada opcional`),
  updated: v > 4 ? "2026-10-19" : "2026-09-30",
});
function websiteGet(page, empty, review) {
  const summary = Object.keys(WEB_PAGES).map((p, i) => ({ page: p, published_version: empty ? null : 2 + i, draft_status: empty ? null : p === page ? (review ? "in_review" : "draft") : p === "terms" ? "draft" : null }));
  const live = { en_url: `https://gymcoapp.com/${page === "home" ? "" : `${page}/`}`, ar_url: `https://gymcoapp.com/${page === "home" ? "" : `${page}/`}ar/`, es_url: `https://gymcoapp.com/${page === "home" ? "" : `${page}/`}es/` };
  const base = { title: { en: WEB_PAGES[page], ar: "", es: "" }, markdown: { en: "", ar: "", es: "" }, updated: "2026-10-19" };
  if (empty) return { base, published: null, draft: null, diff: [], history: [], live, summary };
  const v = summary.find((s) => s.page === page).published_version;
  return {
    base, live, summary,
    published: { version: v, status: "published", body: webBody(page, v), created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-09-30T09:00:00Z", note: null },
    draft: { version: v + 1, status: review ? "in_review" : "draft", body: webBody(page, v + 1), created_by: "editor@gymco.test", submitted_by: review ? "editor@gymco.test" : null, note: "Mention photo handling" },
    diff: [],
    history: [
      { version: v + 1, status: review ? "in_review" : "draft", created_by: "editor@gymco.test", created_at: "2026-10-19T08:00:00Z", note: "Mention photo handling" },
      { version: v, status: "published", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-09-30T09:00:00Z", note: null },
      { version: v - 1, status: "archived", created_by: "owner@gymco.test", published_by: "owner@gymco.test", published_at: "2026-08-12T09:00:00Z", note: "First version" },
    ],
  };
}

const health = (empty) => ({
  functions: empty ? [] : [
    { fn: "food-photo", calls: 1842, errors: 11, rate: 0.006 }, { fn: "admin", calls: 412, errors: 0, rate: 0 }, { fn: "app-config", calls: 6210, errors: 3, rate: 0.0005 },
    { fn: "delete-account", calls: 6, errors: 1, rate: 0.167 }, { fn: "support-ticket", calls: 19, errors: 0, rate: 0 }, { fn: "admin-stats", calls: 96, errors: 0, rate: 0 },
  ],
  db_bytes: empty ? 9_100_000 : 61_700_000,
  backups: { count: empty ? 0 : 1190, bytes: empty ? 0 : 38_400_000 },
  tokens: empty ? 0 : 1240,
  tickets: ticketCounts(empty ? [] : tickets),
  crashlytics: false,
  services: [
    { name: "Auth email delivery", note: "Not tracked yet", state: "unknown" },
    { name: "ImprovMX forwarding", note: "support@gymcoapp.com → inbox", state: "ok" },
    { name: "GitHub Pages", note: empty ? "No deploy seen yet" : "Website workflow passed · 18 Oct", state: empty ? "unknown" : "ok" },
    { name: "Push (FCM)", note: "Not configured", state: "warn" },
  ],
  ci: empty ? null : { name: "Website", status: "passed", when: "2026-10-18T16:02:00Z", url: "https://github.com/ghassanhani/Gymco/actions/runs/9080" },
  generated_at: "2026-10-19T14:05:00Z",
});

/** [status, body] for one admin request. Flags: push_off (FCM missing), week_taken (push.schedule → 409), no_github. */
export function fixtures(body, { role, empty, review, flags = {} }) {
  switch (body.action) {
    case "me": return [200, { email: "owner@gymco.test", role }];
    case "stats": return [200, stats(empty)];
    case "audit.list": return [200, { entries: empty ? [] : audit }];
    case "audit.export": return [200, { csv: "at,admin\n" }];
    case "team.list": return [200, { admins }];
    case "account.lookup": return body.email === card.email ? [200, card] : [404, { error: "no_account" }];
    case "config.get": return [200, configGet(empty, review)];
    case "config.save_draft": return [200, { diff: [] }];
    case "config.publish": return [200, { version: 19, diff: [] }];
    case "packs.get": return [200, packsGet(body.kind, empty, review)];
    case "packs.check": return [200, packCheck(body.kind, body.body)];
    case "packs.save_draft": return [200, { diff: [] }];
    case "packs.submit": case "packs.discard": return [200, {}];
    case "packs.publish": case "packs.rollback": return [200, { version: 1, diff: [] }];
    case "plans.grants": return role === "viewer" ? [403, { error: "forbidden" }] : [200, { grants: empty ? [] : grants }];
    case "announce.list": return [200, { items: empty ? [] : announcements }];
    case "announce.save": return [200, { id: body.id ?? "a9", warnings: /burn off/i.test(body.body?.en ?? "") ? ["Voice check: “burn off” ties exercise to food. Try “Start the week strong”.", "Overlaps 1 live announcement · only the newest shows"] : [] }];
    case "announce.publish": case "announce.archive": case "push.cancel": return [200, { ok: true }];
    case "push.list": return [200, { items: empty ? [] : campaigns, configured: !flags.push_off, tokens: empty ? 0 : 1240 }];
    case "push.save": { const local = String(body.send_at_local ?? ""); const hh = Number(local.slice(11, 13)); const moved = hh >= 22 || hh < 8; const day = new Date(`${local.slice(0, 10)}T00:00:00Z`); if (hh >= 22) day.setUTCDate(day.getUTCDate() + 1); return [200, { id: body.id ?? "p9", send_at_local: moved ? `${day.toISOString().slice(0, 10)}T08:00` : local, moved }]; }
    case "push.schedule": return flags.push_off ? [503, { error: "not_configured" }] : flags.week_taken ? [409, { error: "week_taken", taken_by: campaigns[0], next_free: "2026-10-30" }] : [200, { ok: true }];
    case "tickets.list": return [200, ticketsList(body.tab, body.q, empty)];
    case "tickets.get": { const t = tickets.find((x) => x.id === body.id); return t ? [200, { ticket: t, messages: ticketMessages[t.id] ?? [], days_left: t.deadline_at ? Math.ceil((new Date(t.deadline_at) - NOW) / 86400000) : null }] : [404, { error: "not_found" }]; }
    case "tickets.add": return [200, { id: "t9" }];
    case "tickets.reply": return flags.resend ? [200, { sent: true }] : [200, { sent: false, mailto: `mailto:${body.id}@example.com?subject=Re%3A%20ticket&body=${encodeURIComponent(body.body ?? "")}` }];
    case "tickets.set_status": case "tickets.tag": return [200, { ok: true }];
    case "tickets.templates": return [200, { templates }];
    case "releases.get": return [200, releasesGet(empty, !flags.no_github)];
    case "releases.rerun": return flags.no_github ? [503, { error: "not_configured" }] : [200, { ok: true }];
    case "releases.notes_save": case "releases.notes_publish": return [200, { ok: true }];
    case "website.get": return [200, websiteGet(body.page ?? "home", empty, review)];
    case "website.save_draft": return [200, { diff: [] }];
    case "website.submit": case "website.discard": return [200, {}];
    case "website.publish": case "website.rollback": return [200, { version: 6, diff: [], committed: !!flags.github_token }];
    case "health": return [200, health(empty)];
    default: return [400, { error: "unknown_action" }];
  }
}
