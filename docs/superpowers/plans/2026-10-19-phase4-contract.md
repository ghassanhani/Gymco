# Phase 4: messaging, support, releases, website, health — the shared contract

Server (`supabase/`), dashboard (`site/admin/`) and app (`lib/`) are built
against this file at the same time. Formats here don't change; if one can't
be built as written, stop and report.

Conventions carried over: admin routes are `POST /functions/v1/admin` with
`{ action, ...fields }`; `T3 = { en, ar, es }` (each non-empty, trimmed;
titles ≤ 80, bodies ≤ 500 characters); errors are `{ error: code, ... }`;
capabilities are read / support / destroy / draft / publish / owner_keys /
team / audit_export (see `admin/access.ts`). Every write is audited with
`section` as named below. Server days are UTC; "local" means the device's
UTC offset.

## Database (one new migration, `20261020000300_phase4.sql`)

Existing: `announcements`, `push_campaigns`, `push_tokens`,
`support_tickets` (+ `deadline_at`), `ticket_messages`, `fn_calls`,
`admin_stats_range(range_days)` (gives `mix.app_version`, `db_bytes`,
`backups`), `note_fn_call(fn, ok)`.

New:
- `website_pages (id, page, version, status, body jsonb, note, created_by,
  created_at, submitted_by, published_by, published_at, unique(page, version))`
  — same shape and statuses as `content_packs` minus checksum/kind. `page`
  ∈ `home, support, privacy, terms, delete-account`. `body` is
  `{ title: T3, markdown: T3, updated: "YYYY-MM-DD" }`.
- `publish_page(page_name, v, by_email)` mirroring `publish_pack`.
- `release_notes (build int primary key, version text, body jsonb T3 (one
  bullet per line), published boolean default false, created_by, created_at,
  published_at)`.
- `fn_calls_24h()` → rows `{ fn, calls, errors }` summed over today and
  yesterday (UTC).
- `support_ticket_counts()` → `{ new, waiting, solved, deletion_open,
  overdue }`.
- `push_token_count()` → int.
- Service-role only, like the rest. Tests in `supabase/tests/phase4.sql`
  (DO block raising `ALL_OK`).

## Admin routes

### Announcements (section `messaging`)
- `announce.list` (read) → `{ items: [Announcement] }`, newest first, all
  statuses.
  `Announcement = { id, title: T3, body: T3, cta: { label: T3, url } | null,
  starts_at, ends_at, targeting: { platform?, locale?, min_build?,
  max_build? }, status: draft|in_review|published|archived, created_by,
  published_by }`.
- `announce.save` (draft) `{ id?, title, body, cta?, starts_at, ends_at,
  targeting? }` → `{ id, warnings }`. Errors (400 `invalid`, `errors[{key,
  message}]`): missing language, `ends_at <= starts_at` ("End date is
  before the start date."), cta url not https. Warnings: overlap with a
  live published announcement for the same audience ("Overlaps 1 live
  announcement · only the newest shows"); voice check hits (below).
- `announce.publish` (publish) `{ id }`, `announce.archive` (draft) `{ id }`.
- Voice check, exported from `_shared/voice.ts` as `voiceIssues(text,
  lang) → [{ phrase, hint }]`: flags phrases that tie exercise to food or
  shame ("burn off", "earn your", "guilt", "cheat day" is allowed as the app
  uses it, "lose weight", "fat" as an adjective about people) in EN/AR/ES;
  short lists, whole-word, case-insensitive. Hint for "burn off": "ties
  exercise to food. Try “Start the week strong”."

### Push campaigns (section `messaging`)
- `push.list` (read) → `{ items: [Campaign], configured: boolean, tokens:
  int }`. `Campaign = { id, title: T3, body: T3, send_at_local
  ("YYYY-MM-DDTHH:MM"), targeting, status: draft|scheduled|sent|cancelled,
  sent_count, created_by }`. `configured` is true only when the
  `FCM_SERVICE_ACCOUNT` secret exists.
- `push.save` (draft) `{ id?, title, body, send_at_local, targeting? }` →
  `{ id, send_at_local, moved: boolean }`. If the time is inside quiet hours
  (22:00–07:59 local) it is moved to 08:00 the same day (next day when it
  was ≥ 22:00) and `moved` is true.
- `push.schedule` (publish) `{ id }` → `{ ok }` or 409 `week_taken` with
  `{ taken_by: Campaign, next_free: "YYYY-MM-DD" }` when another campaign
  is scheduled or sent in the same ISO week; 503 `not_configured` when FCM
  isn't set up (the campaign stays a draft).
- `push.cancel` (draft) `{ id }`.
- Sending itself is not built (no FCM); `push.schedule` only sets status.

### Support (section `support`)
- `tickets.list` (support) `{ tab: new|waiting|solved|deletion, q? }` →
  `{ items: [Ticket], counts: { new, waiting, solved, deletion_open,
  overdue } }`. `Ticket = { id, email, subject, locale, app_version,
  platform, kind, status, tags, source, created_at, updated_at,
  deadline_at, has_account: boolean }`. Deletion tab = kind `deletion`, any
  status, overdue first. Lists never include `body`.
- `tickets.get` (support) `{ id }` → `{ ticket (with body), messages:
  [{ id, from_admin, author, body, at }], days_left: int | null }`
  (`days_left` from `deadline_at`, negative when overdue).
- `tickets.add` (support) `{ email, subject, body, locale?, kind? }` →
  `{ id }` with `source: 'admin'`; a deletion ticket gets `deadline_at =
  now + 30 days`.
- `tickets.reply` (support) `{ id, body, status?: waiting|solved }` →
  `{ sent: true }` when `RESEND_API_KEY` is set (From
  `support@gymcoapp.com`, Subject `Re: <subject>`), else `{ sent: false,
  mailto: "mailto:...?subject=...&body=..." }`. The message is stored
  either way and the status updated.
- `tickets.set_status` (support) `{ id, status }`, `tickets.tag` (support)
  `{ id, tags: string[] }` (≤ 5 tags, each ≤ 20 chars).
- Templates are a constant in `_shared/support_templates.ts`:
  `TEMPLATES = { deletion_confirmed, restore_help, cap_reset, nothing_stored }`
  each `T3` with `{email}` placeholder; returned by `tickets.templates`
  (support).

### Releases (section `releases`)
- `releases.get` (read) → `{ runs: [{ id, name, sha7, status:
  passed|failed|running|queued, when, url }], versions: [{ build, pct }],
  gate: { min_build_ios, min_build_android, recommended_build }, notes:
  [{ build, version, body: T3, published }], github: boolean, mirror:
  "iFynx/Gymco" }`. `runs` come from the GitHub Actions API (workflows
  Release, iOS test build, CI, Website, Mirror to iFynx; latest run each)
  when the `GITHUB_TOKEN` secret exists, else `[]` and `github: false`.
  `versions` is `stats.mix.app_version` from `admin_stats_range(30)`.
- `releases.rerun` (publish) `{ run_id }` → `{ ok }` or 503
  `not_configured`.
- `releases.notes_save` (draft) `{ build, version, body }`,
  `releases.notes_publish` (publish) `{ build }`.
- The version gate is edited through `config.*` (the dashboard does what
  the Plans page does: save_draft + publish with a diff).

### Website (section `website`)
- `website.get|save_draft|submit|discard|publish|rollback` through
  `versionedRoutes("website", { table: "website_pages", kinds: PAGES,
  base(page) })`, field `page` instead of `kind` (extend `versionedRoutes`
  with an optional `kindField` name). `website.get` also returns `live:
  { en_url, ar_url, es_url }` and `summary` for every page.
- Publishing also writes the site when `GITHUB_TOKEN` exists: render
  Markdown (use `npm:marked@15.0.12`, sanitised: no raw HTML) into the
  existing page shell (`_shared/site_shell.ts`: header, nav, `<main>`,
  footer, same `/style.css`) and PUT via the GitHub contents API to
  `site/<path>/index.html` (EN), `site/<path>/ar/index.html` (`dir="rtl"`,
  `lang="ar"`) and `site/<path>/es/index.html`; `home` is `site/index.html`
  and `site/ar/`, `site/es/`. Commit message `Website: <page> v<version>`.
  Without the token the version is published in the table and the
  response carries `{ committed: false }`.
- `base(page)` = `{ title: {en: <page name>, ar: "", es: ""}, markdown:
  {en: "", ar: "", es: ""}, updated: today }`; the live HTML is never read
  back. The dashboard
  shows "Nothing drafted yet: the live page stays as it is until a version
  is published."

### Health (section none, read only)
- `health` (read) → `{ functions: [{ fn, calls, errors, rate }], db_bytes,
  backups: { count, bytes }, tokens: int, tickets: counts, crashlytics:
  false, services: [{ name, note, state: ok|warn|bad|unknown }], ci:
  { name, status, when, url } | null, generated_at }`. Services: "Auth
  email delivery" (unknown · "Not tracked yet"), "ImprovMX forwarding"
  (ok · "support@gymcoapp.com → inbox"), "GitHub Pages" (from the Website
  workflow's latest run when available), "Push (FCM)" (configured or not).

## Public functions (deploy with `verify_jwt` false)

- `support-ticket`: `POST { email, subject, body, locale?, app_version?,
  platform?, kind?: general|deletion }` → 201 `{ id }`. Validates lengths
  per the table, email shape; at most 5 tickets per email per UTC day (429
  `too_many`). Counted with `note_fn_call('support-ticket', ok)`. CORS `*`.
- `push-register`: `POST { token, platform, locale, utc_offset_min,
  app_version? }` → 200 `{ ok }`; upserts `push_tokens`. `DELETE { token }`
  removes it. No auth, no user link.
- `app-config` additionally returns `whats_new: { build, version, body:
  T3 } | null` for the device's build when a published note exists for it.

## App

- **Announcement card on Today**, under the catch-up card: title, body and
  CTA in the app's language from `app-config`'s `announcements` (already
  cached with the config). Dismiss per id in prefs `rc.dismissed_ann`
  (phone-only). Only the newest live announcement shows.
- **Help form**: Me → "Help & support" opens an in-app form (email
  prefilled from the account when signed in, subject, message, a "Delete my
  account and data" switch that sets kind `deletion`), posting to
  `support-ticket` with locale, app version and platform; success toast,
  offline error. The existing website link stays as a second row.
- **What's New**: when `app-config` carries `whats_new` for this build and
  it hasn't been shown (`rc.whats_new_shown` = build), show a sheet once
  with the bullets.
- **Push registration is not built** (no firebase_messaging in the app and
  no FCM project); `push-register` exists for later.
