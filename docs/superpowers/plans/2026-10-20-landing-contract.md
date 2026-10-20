# Landing page controlled from the Control Center: the shared contract

gymcoapp.com/ becomes the landing page from the design in
`docs/superpowers/designs/landing/` (`Landing.dc.html` desktop,
`Landing-Phone.dc.html` phone, `landing.css`). Its images are already in
`site/img/landing/`. The page ships with its own copy in English, Arabic
(right-to-left) and Spanish, and works with no network beyond fonts. When the
Control Center has published landing settings, the page applies them on load:
which sections show, editable copy, prices, store links, the FAQ, the email
sign-up. Server, dashboard and page are built against this file at the same
time; formats here don't change.

## The landing body (one versioned document, like the remote config)

```json
{
  "sections": { "proof": true, "food": true, "train": true, "coaching": true,
                "streak": true, "privacy": true, "plans": true, "faq": true, "join": true },
  "beta": true,
  "copy": { "<key>": { "en": "…", "ar": "…", "es": "…" } },
  "prices": { "pro_month": "€4.99", "pro_year": "€39.99", "lifetime": "€89", "year_save": "−33%" },
  "stores": { "ios_url": "", "android_url": "" },
  "faq": [ { "q": { "en", "ar", "es" }, "a": { "en", "ar", "es" } } ],
  "notify": true
}
```

- Every field is optional; a missing one keeps the page's built-in value.
  `faq` empty or missing = the built-in seven questions.
- `beta: false` hides the "Beta · free while in testing" tag, the testing
  banner over Plans and the "Unlocked in beta" badge, and the Join buttons
  read "Download" (still pointing at `#join`).
- `stores.*_url`: `""` = the badge links to `#join` (as in the design);
  otherwise must be `https://apps.apple.com/…` / `https://play.google.com/…`.
- `prices.*`: free text ≤ 12 characters (a currency sign and number).
- `copy`: only keys in `LANDING_KEYS` below; each value all three languages,
  trimmed, ≤ 300 characters (titles ≤ 80). In titles, `*word*` marks the
  italic serif accent (the design's `<em>`); nothing else is markup — the
  page renders copy as text, never HTML.
- `notify: false` hides the email box and its consent line.

### LANDING_KEYS (copy the page can take from the Control Center)

`hero.title`, `hero.lede`, `hero.cta`, `hero.cta2`,
`food.eyebrow`, `food.title`, `food.sub`,
`train.title`, `train.sub`, `train.cta`,
`coaching.eyebrow`, `coaching.title`, `coaching.sub`,
`streak.eyebrow`, `streak.title`, `streak.sub`,
`privacy.eyebrow`, `privacy.title`, `privacy.sub`,
`plans.eyebrow`, `plans.title`, `plans.banner`,
`faq.eyebrow`, `faq.title`,
`join.title`, `join.sub`, `join.consent`,
`footer.tagline`

Their built-in English is the design's text (e.g. `hero.title` = `Diet and
training for *lifters*`, `join.title` = `Start your *streak*`). The page's own
copy table (`site/landing-copy.js`) holds every string of the page in all
three languages under these keys and others; only the keys above are
editable. `supabase/functions/_shared/landing.ts` exports the same
`LANDING_KEYS` and `LANDING_DEFAULTS` (English only, for the dashboard's
hints); a node test checks the two lists match.

## Serving

- `GET /functions/v1/app-config?site=landing` (public, CORS `*`,
  `Cache-Control: public, max-age=60`) →
  `200 { version, body }` for the published landing document, or
  `200 { version: 0, body: null }` when nothing is published.
- The page calls it once on load with a 4 s timeout; any failure leaves the
  built-in page as it is. The page never shows a broken or half-applied
  state: it validates what it gets (unknown keys ignored, wrong types
  ignored, store URLs must match the allowed prefixes).

## Email sign-up (the design's "Notify me")

- Public function `waitlist`: `POST { email, locale }` → `201 { ok: true }`
  (also 201 when the email is already on the list, so the page can't be used
  to test addresses); `400 { error: "invalid" }`; `429 { error: "too_many" }`
  past 500 sign-ups a UTC day in total. CORS `*`, `verify_jwt` off,
  counted with `note_fn_call('waitlist', ok)`.
- Table `landing_waitlist (email text primary key check (length(email) <= 320),
  locale text check (locale in ('en','ar','es')), created_at timestamptz
  default now())`, RLS on, no grants to anon/authenticated.
- The page shows "You're on the list. One email at launch." (in the page's
  language) on 201, a plain retry message otherwise.

## Database (migration `20261020000400_landing.sql`)

- `site_landing (id, version int unique, status, body jsonb, note,
  created_by, created_at, submitted_by, published_by, published_at)` with a
  partial unique index for one published row — same shape as
  `remote_config`.
- `publish_landing(v int, by_email text)` mirroring `publish_config`.
- `waitlist` as above; `waitlist_stats()` → `{ count, last_7d }`.
- Service-role only.

## Admin routes (section `website`)

- `landing.get|save_draft|submit|discard|publish|rollback` through
  `versionedRoutes("landing", { table: "site_landing", … })`, no kind.
  `landing.get` also returns `defaults` (the full default body, English copy
  from `LANDING_DEFAULTS` as `{en}` hints), `keys` (`LANDING_KEYS`) and
  `waitlist: { count, last_7d }`.
- Validation errors as elsewhere: `400 invalid` with `errors[{key, message}]`,
  keys like `copy.hero.title.ar`, `stores.ios_url`, `prices.pro_month`,
  `faq.2.a.es`.
- `waitlist.export` (cap `audit_export`, Owner) → `{ csv }` with
  `email,locale,created_at`; audited.
- Capabilities: get = read, save/submit/discard = draft, publish/rollback =
  publish (Owner), as for the config.

## Website page in the dashboard

- The old `home` page goes away from the Website page list and from the
  server's `PAGES` for committing (gymcoapp.com/ is the landing page now and
  must never be overwritten by the Markdown publisher). The other pages stay.
- A "Landing page" entry comes first in the Website page list and opens the
  landing editor: section switches, beta switch, sign-up switch, prices,
  store links, copy per key (EN/AR/ES fields, the built-in English shown as
  the hint), FAQ editor (add, remove, reorder), "Open gymcoapp.com ↗", the
  waitlist count with an Owner-only CSV export, and the usual draft →
  review → publish with a diff and version history with rollback.
