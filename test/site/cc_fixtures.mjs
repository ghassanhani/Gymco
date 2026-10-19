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
  if (empty) return { base, published: null, draft: null, diff: [], history: [], schema: SCHEMA, defaults: base };
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

/** [status, body] for one admin request. */
export function fixtures(body, { role, empty, review }) {
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
    default: return [400, { error: "unknown_action" }];
  }
}
