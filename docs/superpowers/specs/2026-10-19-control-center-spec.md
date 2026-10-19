# Gymco Control Center — Admin Dashboard Spec

Oct 19, 2026 · @Ghassan

## Summary

The Gymco Control Center replaces today's totals-only page at gymcoapp.com/admin with one place to run the app: remote config, content, accounts, AI spend, plans, messaging, releases and system health. Everything changes on the server and reaches phones on next launch, with no app update.

**Goals**

1. Change app behaviour without shipping a build (flags, limits, copy, prices, force-update).
2. Edit the content the app ships with (foods, exercises, templates, awards, challenges) and push it as versioned packs.
3. See health and cost at a glance: sign-ups, active accounts, AI scans and spend, backups, errors.
4. Handle support safely: find an account by email, reset its scan cap, restore or delete its backup.
5. Keep Gymco's privacy promise intact while doing all of the above.

**The privacy boundary.** The diary lives on the phone, so the dashboard can never read or edit a user's food log, workouts, weigh-ins, measurements, photos or Health data. This is a design rule, not a gap.

| Admin CAN | Admin CANNOT |
| --- | --- |
| See counts and totals (accounts, sign-ups, scans, backups, deletions) | Open or read any diary, backup content or photo |
| Look up an account by email; see created date, last backup time and size, scans today | See what someone ate, lifted or weighed |
| Reset a scan cap, delete an account and its backup | Edit a user's targets, streak or awards |
| Change flags, limits, copy, prices and content packs for everyone or a cohort | Track individual usage (no analytics, no trackers) |
| Send announcements and push campaigns to all devices or a locale | Target a person by behaviour |

The dashboard never opens a backup: it shows size and date only. Any new metric must be a count the server already has, never an event sent from the phone.

## Architecture

The dashboard is a static web app that talks only to role-checked Supabase edge functions; the phone app reads published config through one public function.

&#91;embedded content: architecture · dashboard, Supabase, app, external services\]

The optional account backup is the only diary copy on the server, and no admin function reads its contents. Config and content packs flow one way, from the dashboard through `app-config` to phones.

## Navigation

A left sidebar with 11 sections in four groups, a top bar with environment switch (Production / Staging), global search by email or content name, and the admin's avatar. On phones the sidebar collapses to a menu.

| Group | Section | What lives there |
| --- | --- | --- |
| Monitor | **Overview** | KPI tiles, sign-up and scan trends, alerts |
| Monitor | **System health** | Crash-free rate, edge function errors, DB size, build status |
| People | **Accounts** | Email lookup, account card, cap reset, backup and delete actions |
| People | **Support inbox** | Tickets from support@gymcoapp.com and the in-app help form |
| App | **Remote config** | Feature flags, limits, safety values, force-update, maintenance |
| App | **Content** | Foods, exercises, routine templates, awards, monthly challenges, onboarding slides |
| App | **Plans & pricing** | Free / Pro / Lifetime, prices per store, testing mode, promo codes |
| App | **Messaging** | In-app announcements, push campaigns, email templates |
| Ship | **Releases** | App versions, minimum version, CI builds, store tracks, release notes |
| Ship | **Website** | gymcoapp.com pages: home, support, privacy, terms, account deletion |
| Admin | **Team & audit log** | Admin users, roles, every change with who, when, before and after |

Every list page shares one pattern: search, filters, a table, a side panel to edit, and Save draft / Publish. Anything that reaches phones goes through **draft → review → publish**, with one-click rollback to the previous version.

## Modules

Each module lists what it shows, what an admin can change, and the rule that keeps it safe.

### 1. Overview

**Shows**

- KPI tiles: total accounts, sign-ups (today / 7 d / 30 d), active accounts (backup in last 7 d), AI scans today and estimated cost, accounts at scan cap today, deletions (30 d), DB size.
- Trend charts: daily sign-ups and daily AI scans over 90 days; cost per day in EUR.
- Mix: accounts by app language (EN / AR / ES) and platform (iOS / Android), taken from the backup row's metadata.
- Alerts strip: scan cost over daily budget, edge function error rate over 2%, crash-free sessions under 99%, a build failed, a ticket waiting over 24 h.

**Rule:** every tile is a server-side count. "Active" means a backup arrived, not app opens, because Gymco sends no usage analytics.

### 2. Accounts

**Shows** a search by exact email (no browse-all list, to discourage snooping). The account card holds: email, created date, platform, app version, language, last backup time and size, AI scans today and last 30 days, consent records.

**Actions**

- Reset today's scan cap, or grant extra scans for one day.
- Resend the sign-in code.
- Delete the backup only, or delete the account and backup (same path as the `delete-account` function).
- Grant Pro or Lifetime manually (comp for testers, refunds, press).
- Add an internal note ("emailed about restore issue").

**Rule:** opening an account card writes an audit entry with a reason picked from a list (support ticket, deletion request, abuse, test).

### 3. Support inbox

**Shows** tickets from support@gymcoapp.com (forwarded by ImprovMX into a Supabase table through an inbound webhook) and from an in-app Help form. Columns: subject, email, language, app version, status, age.

**Actions:** reply with saved templates in EN / AR / ES, set status (New, Waiting, Solved), link to the account card, tag (bug, billing, deletion, feature idea).

**Rule:** deletion requests have a 30-day legal deadline and show a countdown.

### 4. AI operations

Lives inside Overview and Remote config, with its own page for detail.

**Shows** scans per day by type (photo, Write fallback, Eating out "Something else"), tokens in and out, estimated cost from the Claude Haiku price table, failure rate, median latency, and accounts hitting the cap.

**Controls**

- Daily scan cap per account (today 10).
- Global daily budget in EUR: when reached, photo logging pauses and the app shows "Photo logging is resting until tomorrow. Write or search still work."
- Kill switch per AI feature.
- Model and prompt version for `food-photo`, with a staged rollout percentage.

**Rule:** photos and text are never stored; the page shows counts and costs only.

### 5. Remote config & feature flags

One JSON config per environment, edited through forms, never raw JSON for non-developers. The app fetches it on launch and every 6 hours, caches it, and falls back to the built-in defaults when offline.

| Group | Keys (examples) | Default today |
| --- | --- | --- |
| Features | `photo_log`, `eating_out`, `dictate`, `barcode_contribute`, `cheat_meals`, `catch_up`, `monthly_challenge` | all on |
| Limits | `ai_scans_per_day`, `photo_note_max_chars`, `backup_interval_min` | 10, 140, 0 (on background) |
| Safety | `calorie_floor_female`, `calorie_floor_male`, `max_rate_pct_week`, `max_weekly_target_change_kcal`, `banked_slice_warn_kcal` | open: confirm floors, 1%, 120, 300 |
| Water | `ml_per_kg`, `training_day_bonus_l`, `min_l`, `max_l` | 35, 0.5, 1.5, 5 |
| Streak | `freeze_every_days`, `freeze_max`, `repair_until` | 7, 3, 23:59 next day |
| App gate | `min_version_ios`, `min_version_android`, `recommended_version`, `maintenance_mode` | build 102 |
| Plans | `paywall_enabled`, `testing_unlock_all` | off, on |

**Targeting:** a flag can apply to all, a platform, a language, an app version range, or a percentage rollout keyed on a random install ID that never leaves the device.

**Rule:** safety values have hard bounds in the schema. A calorie floor can't be saved below the medical minimum set in code, and the max rate can't exceed 1% a week.

### 6. Content library

The app ships content inside the build; the dashboard publishes **content packs** (versioned JSON) that the app downloads and swaps in. Each pack has draft, published and archived versions.

| Library | What can be edited | Notes |
| --- | --- | --- |
| Foods (built-in staples) | Name in EN / AR / ES, aliases for Write parsing, kcal and macros per 100 g, serving sizes, category | Open Food Facts items are not edited here |
| Write parser vocabulary | Units (scoop, slice, tbsp), number words in three languages, food synonyms | Test box: type a meal and see the parse |
| Eating out | Restaurant types, dishes, rough estimates per dish | Same three languages |
| Exercises | Name, main and helper muscles, equipment, level, movement pattern, suggested rest, two photos, swap alternatives | 870+ from free-exercise-db; flag broken photos |
| Routine templates | Upper / Lower, PPL, Full body, plus new ones: days, exercises, sets, reps, rest, level | Shows weekly volume per muscle vs 10–20 sets |
| Awards | Name, description, threshold, medal art, category, share text | Rule check blocks any award tied to weight loss or eating less |
| Monthly challenges | Month, title, target (train N times), badge | Schedule ahead |
| Onboarding & copy | Welcome slides, goal descriptions, empty states, reminder texts | Edits per language; RTL preview for Arabic |

**Rules:** every text field requires EN, AR and ES before publish; a preview renders the item in the Volt phone frame in all three languages; a pack can't be published if it removes an exercise used in a template.

### 7. Plans & pricing

**Shows** the three plans with store product IDs (App Store, Google Play), prices per region, and the plan-card glow colours.

**Controls:** testing mode on or off (today every Pro feature is unlocked), which features sit behind Pro, introductory offers, promo codes, manual grants (from Accounts).

**Rule:** store prices are set in App Store Connect and Play Console; the dashboard mirrors them and edits only display copy and which features are Pro. Revenue figures come later from the store APIs or RevenueCat, if added.

### 8. Messaging

| Channel | Use | Controls |
| --- | --- | --- |
| In-app announcement | A card on Today (new feature, maintenance, testing note) | Title and body in 3 languages, CTA, start and end date, targeting by platform, language, version |
| Push campaign | A one-off notification | Text in 3 languages, schedule in the user's local time, quiet hours 22:00–08:00, preview |
| Email templates | Sign-in code, deletion confirmed, support replies | Edit copy per language |

**Rules:** pushes go to device tokens only, with no user profile behind them; one campaign a week at most; the voice checklist (plain, calm, no shaming) shows beside the editor. Meal, water and workout reminders stay local on the phone and aren't controlled here.

### 9. Releases

**Shows** the latest GitHub Actions runs (Android test APK, unsigned iOS, signed release), the build on TestFlight and Google Play internal testing, versions in use (share of backups by app version), and the mirror to `iFynx/Gymco`.

**Controls:** minimum and recommended version (soft prompt or hard block), What's New notes per language, a trigger to re-run a workflow.

### 10. Website

Edit gymcoapp.com pages (home, support, privacy, terms, account deletion) as Markdown per language. Publishing commits to `site/` and GitHub Pages deploys it. Privacy and terms keep a dated version history, and the app links to the current one.

### 11. System health

**Shows** crash-free sessions and top crashes from Firebase Crashlytics (once configured), edge function invocations and error rates (`food-photo`, `delete-account`, `admin-stats`), DB and storage size against plan limits, auth email delivery failures, and ImprovMX forwarding status.

**Rule:** links out to Supabase, Firebase and GitHub for depth instead of copying their consoles.

## Roles, security and audit

Four roles, each a superset of the one below it. Ghassan is the only Owner.

| Capability | Viewer | Support | Editor | Owner |
| --- | --- | --- | --- | --- |
| Overview, health, releases (read) | Yes | Yes | Yes | Yes |
| Account lookup, notes, cap reset, support inbox | — | Yes | Yes | Yes |
| Delete account or backup, manual Pro grant | — | With reason | With reason | Yes |
| Draft content, copy, announcements | — | — | Yes | Yes |
| Publish content packs and remote config | — | — | Needs Owner review | Yes |
| Safety values, AI budget, force-update, pricing | — | — | — | Yes |
| Manage admins, export audit log | — | — | — | Yes |

**Security**

- Admins sign in with the same Supabase email code plus a TOTP second factor; admin status lives in an `admins` table, never in the app's user metadata.
- Every admin request goes through edge functions that check the role server-side. The browser never holds the service-role key.
- Row-level security on all admin tables; the public app's anon key can read only published config and content packs.
- Sessions expire after 12 hours of inactivity; destructive actions ask to type the account email to confirm.
- Staging and Production are separate Supabase projects, so tests can't touch real accounts.

**Audit log.** Every write records admin, time, section, object, before and after values, and reason. It is append-only, kept for 2 years, filterable and exportable as CSV. Publishing a config or pack shows a diff first and keeps the previous version for one-click rollback.

## Data model and functions

New Supabase tables sit beside the existing auth, backup and scan-cap tables. None holds diary data.

| Table | Key columns | Read by |
| --- | --- | --- |
| `admins` | user\_id, role, totp\_enabled, created\_at | Admin functions |
| `audit_log` | id, admin\_id, at, section, object\_id, before jsonb, after jsonb, reason | Owner |
| `remote_config` | env, version, status (draft / published / archived), body jsonb, published\_by, published\_at | App (published only) |
| `flag_rules` | key, target (platform, locale, version range, percent), value | App via config |
| `content_packs` | kind (foods, exercises, templates, awards, challenges, copy), version, status, body jsonb, checksum | App (published only) |
| `announcements` | id, title/body per locale, cta, starts\_at, ends\_at, targeting | App |
| `push_campaigns` | id, text per locale, send\_at\_local, targeting, status, sent\_count | Admin |
| `push_tokens` | token, platform, locale, app\_version, updated\_at (no user link) | Push sender |
| `support_tickets` | id, email, subject, body, locale, app\_version, status, tags, created\_at | Support |
| `account_notes` | user\_id, admin\_id, note, at | Support |
| `entitlements` | user\_id, plan (pro / lifetime), source (store / manual), expires\_at | App, Admin |
| `ai_usage_daily` | day, feature, scans, tokens\_in, tokens\_out, cost\_eur, failures | Admin |

**Edge functions**

| Function | Input | Returns | Role |
| --- | --- | --- | --- |
| `app-config` (public) | platform, locale, app\_version, install\_bucket | Resolved config, pack versions, active announcements, min version | Anon |
| `admin-stats` (extend) | range | KPI totals and daily series | Viewer |
| `admin-account` | email, reason | Account card | Support |
| `admin-account-action` | user\_id, action (reset\_cap, delete\_backup, delete\_account, grant\_plan), reason | Result | Support / Owner |
| `admin-publish` | kind, draft version | New published version, diff | Editor (Owner review) / Owner |
| `admin-rollback` | kind, to\_version | Result | Owner |
| `push-send` | campaign\_id | Sent count | Editor |
| `inbound-email` | ImprovMX webhook payload | Ticket id | Service |

**App changes needed:** call `app-config` on launch and every 6 hours, cache the result, honour `min_version` and `maintenance_mode`, download packs when the version changes and verify the checksum, register a push token without an account link, and fall back to built-in defaults when offline.

## Visual design: Volt dark

The dashboard uses the app's Volt identity, dark only, tuned for dense data: lime is kept for actions and the one thing that needs attention, never for decoration.

| Token | Value | Use in the dashboard |
| --- | --- | --- |
| Page | `#0A0B09` | Background |
| Sidebar / sheet | `#111315` | Navigation, side panels |
| Card | `#15171A` | KPI tiles, tables, forms |
| Raised | `#1F2226` | Hover rows, menus, popovers |
| Lines | `#2A2E33` / `#3A3F45` | Table rules / input borders |
| Text | `#F5F7F0`, `#C9CEC4`, `#8D948A`, `#5F665C` | Primary, secondary, labels, disabled |
| Brand lime | `#C6F432` | Primary buttons, active nav item, focus ring |
| Lime ink | `#D9FF5C` | Links, selected tab text |
| Lime wash / edge | `#1A230D` / `#4D6B12` | Selected row, active filter chip |
| Good | `#7CF0B0` | Healthy, published, delta up |
| Warning | `#FFD23F` | Near a limit, draft unpublished |
| Critical | `#FF5C5C` (new) | Errors, delete, over budget |
| Protein / Carbs / Fat | `#4CC9F0` / `#FF9F43` / `#C084FC` | Macro values in the food editor only |

**Type:** Urbanist for UI (14 px body, 12 px labels, 28–32 px KPI numbers, tabular figures), Instrument Serif Italic for one accent word in page titles (*Your* ***accounts***, *Remote* ***config***), IBM Plex Sans Arabic in Arabic previews. Western digits everywhere.

**Shape:** cards radius 24, rows 18, side sheets 30, pill buttons. Glow gradient `#E4FF6A → #B6F02A → #5EE4A0` only on the Publish button.

**Components to build:** KPI tile with sparkline, data table with sticky header, side-sheet editor, three-language field (EN / AR / ES tabs with an RTL preview), JSON diff viewer, phone-frame preview, status chip (Draft, In review, Published, Archived), confirm dialog that asks to type the email, alert banner.

**Charts:** one lime series on grey; a second series in mint; never red unless it means an error. Gridlines `#2A2E33`, axis labels `#8D948A`.

**Accessibility:** text on cards meets 4.5:1 (secondary `#C9CEC4` on `#15171A` passes); lime text on near-black passes; never put white text on lime, use `#0A0B09`. Full keyboard navigation and visible focus ring.

## Rollout and open questions

Build in four phases so the riskiest power (deleting accounts, changing safety values) ships with its audit trail from day one.

&#91;embedded content: rollout · 4 phases, 3 gates\]

Week counts assume one developer working with Claude Code part-time; adjust once Phase 1 shows the real pace.

**Done means**

- [ ] No dashboard screen or function can return diary, backup content or photos
- [ ] Every write appears in the audit log with before, after and reason
- [ ] Safety values can't be saved outside their coded bounds
- [ ] Every user-facing text has EN, AR and ES before it can publish, with an RTL preview
- [ ] The app works fully offline on built-in defaults if `app-config` is down
- [ ] Any published config or pack can be rolled back in one click

**Open questions**

- What calorie floors does the app use today, so the schema bounds match them?
- Is push set up (Firebase Cloud Messaging and APNs)? Push campaigns need it.
- When the paywall turns on: RevenueCat, or store APIs directly, for entitlements and revenue?
- Keep the dashboard as a static page at gymcoapp.com/admin on GitHub Pages, or move it to its own host (for example Vercel)?
- Exercise data: stay on free-exercise-db, or move to RepDB as planned earlier? This changes the exercise editor's fields.
- Will anyone besides you get admin access, and in which role?
- Can ImprovMX forward support mail to a webhook, or does the inbox need another mail route?
