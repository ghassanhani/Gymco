# Gymco Control Center Implementation Plan

> Executed inline (all phases back to back, user's choice). Steps are RED → GREEN per task.

**Goal:** Replace gymcoapp.com/admin with the Control Center from the spec. It covers 11 sections, admin roles with a second factor, an audit log, remote config, content packs, messaging, support, releases, website editing and system health. The app gains matching changes so that what the dashboard publishes reaches phones without a new build.

**Spec:** `docs/superpowers/specs/2026-10-19-control-center-spec.md`
**Designs:** `docs/superpowers/designs/control-center/*.dc.html` (20 artboards: 11 screens + 8 edge-state boards + phone width)

**Architecture:**
- **Dashboard:** a static single-page app in `site/admin/` (plain ES modules, no build step, hash routes). It talks to one role-checked edge function, `admin`.
- **Phones:** read published state through a public `app-config` function, plus small public endpoints `support-ticket` and `push-register`.
- **Database:** all state lives in new Supabase tables with row-level security on and no client policies, so only the service role reads or writes them.

**Tech:**
- Postgres (Supabase) and Deno edge functions using `npm:@supabase/supabase-js@2.117.2`.
- Dashboard: vanilla JS; supabase-js 2.117.2 UMD from jsDelivr.
- App: Flutter / Riverpod.
- Tests: Deno test for function logic, `node --test` for dashboard logic, Playwright shots for every page and state, Flutter tests for the app.

## Global constraints (from the spec)

**Privacy**
- No function or screen ever returns diary content, backup content, photos or Health data. Backups show size and dates only.
- No browse-all account list: lookup is by exact email, and every lookup writes an audit entry with a reason.

**Access**
- Roles are viewer < support < editor < owner, per the spec's matrix.
- Admin status lives in `admins`, never in user metadata.
- Every admin request needs an `aal2` session, meaning email code plus TOTP.

**Changes and publishing**
- Every write appends to `audit_log` (admin, time, section, object, before, after, reason). The log is append-only: no update or delete grants.
- Anything that reaches phones goes draft → in review → published, with a diff before publishing and one-click rollback to the previous version.
- Editors can only submit for review; the owner publishes.
- Safety values have hard bounds in code:
  - calorie floor ≥ 1200, default 1700 (the app's `defaultKcalFloor`)
  - max rate ≤ 1% per week
  - max weekly target change ≤ 120 kcal
- Text that reaches users needs EN, AR and ES before it can publish, with an RTL preview for Arabic.
- An award tied to weight loss or eating less is rejected.
- A pack can't remove an exercise that a template uses.

**App behaviour**
- The app works offline on built-in defaults; `app-config` being down never blocks it.
- Pushes go to device tokens with no user link, at most one campaign a week, with quiet hours 22:00–08:00 local time.
- Reminders stay local on the phone.

**Look**
- Volt, dark by default with a **light-mode toggle** in the top bar (user request), remembered per browser.
- Lime only for actions and the active item; Critical `#FF5C5C`.
- Text 4.5:1 in both themes; no white text on lime.

**Staging:** the switch is shown but disabled. Supabase's 2-free-project limit is reached (user chose to skip staging for now).

## Rulings taken up front
1. **One `admin` function routes every admin action** (`{action, ...}`), instead of the spec's 6 separate admin functions. It does the same role checks with one deploy and one place for auth. `app-config` stays public and separate, as in the spec.
2. **Push sending needs FCM/APNs, which isn't set up.** Campaigns, tokens and the editor are built. `push-send` returns `not_configured` until an `FCM_SERVICE_ACCOUNT` secret exists.
3. **Support email intake:** ImprovMX only forwards mail. Tickets come from the in-app Help form and from "Add ticket" in the inbox. Replies are sent through Resend when `RESEND_API_KEY` is set; otherwise they open the admin's mail client with the template filled in.
4. **Releases and Website editing use the GitHub API** through a `GITHUB_TOKEN` secret (fine-grained, Gymco repo, contents + actions). Without it they show read-only links.
5. **Crash data:** Crashlytics has no simple read API, so System health links out. Edge function call and error counts come from a `fn_calls` counter that our own functions increment.
6. **Copy packs override a whitelisted set of app texts:** welcome slides, goal descriptions, empty states, reminder texts. Overrides are looked up by key, with the built-in translation as fallback.

## Phase 1 — Foundation
- **Task 1.1 · Database:** a migration adding `admins` (owner seeded by email), `audit_log`, `account_notes`, `entitlements` and `ai_grants`. `backups` gains `platform`, `locale` and `app_version` columns. `take_ai_credit` reads the cap from published config plus today's grants. `admin_stats(range_days)` adds 7/30/90-day ranges, the language and platform mix, at-cap today, and 30-day deletions.
  - *Tests (SQL):* privileges for anon and authenticated are false; the owner is seeded; the series length equals the range; a grant raises the cap; no `@` in the output.
- **Task 1.2 · `admin` function core:** auth (JWT, then the admins row, then aal2), the role matrix `can(role, capability)`, an audit helper, CORS, `fn_calls` counting. Actions: `me`, `stats`, `account.lookup`, `account.action` (reset_cap, grant_scans, resend_code, delete_backup, delete_account, grant_plan, revoke_plan), `note.add`, `team.list`, `team.invite`, `team.set_role`, `team.remove`, `audit.list`, `audit.export`.
  - *Tests (Deno):* the role matrix row by row; aal1 refused; lookup without a reason refused; delete without the typed email refused; viewer cannot write.
- **Task 1.3 · Dashboard shell:**
  - router, sidebar, top bar (disabled env switch, search, theme toggle, avatar menu)
  - sign-in: email code, then TOTP enrol or challenge
  - shared UI kit: KPI tile with sparkline, table, side sheet, chips, confirm-by-email dialog, alert strip, three-language field, diff viewer, phone preview, loading / empty / error states
  - Volt dark and light tokens with a contrast check
  - *Tests:* node unit tests for helpers and the router; Playwright shots for sign-in, enrol and challenge.
- **Task 1.4 · Overview, Accounts, Team & audit pages.**
  - *Tests:* shots for both themes at 1280 and 390, plus every edge-state board for these sections.
- **Task 1.5 · App: backup metadata.** Send platform, locale and app version with each backup.
  - *Tests (Flutter):* the backup upsert carries the three fields.

## Phase 2 — Remote control
- **Task 2.1 · Database:** `remote_config` (versioned; draft, in review, published, archived), `flag_rules`, and `ai_usage_daily` with per-feature scans, tokens, cost, failures and latency.
- **Task 2.2 · Shared config schema `config_schema.ts`**, used by both functions: keys, defaults, bounds, validation and `resolve(config, rules, {platform, locale, version, bucket})`.
  - *Tests (Deno):* bounds are rejected; targeting by platform, locale, version range and percentage bucket; defaults fill missing keys.
- **Task 2.3 · Functions:**
  - `admin` gains `config.*` (get, draft, submit, publish, rollback, history, diff) and `flags.*`.
  - New `app-config` function (public).
  - `food-photo` reads the cap, global budget, kill switches and model/prompt rollout from published config, and writes `ai_usage_daily`.
- **Task 2.4 · Pages:** Remote config, with the AI operations section, the app gate and maintenance mode, plus the EdgeConfig and EdgeAI boards.
- **Task 2.5 · App:**
  - a `RemoteConfig` model with defaults equal to today's constants, fetched on launch and every 6 h, cached
  - flags hide their features; limits, safety, water and streak values are wired
  - min-version gate (soft prompt or hard block) and maintenance screen
  - *Tests (Flutter):* parsing and defaults; flag off hides photo mode; hard block shows the update screen; offline uses the cache.

## Phase 3 — Content
- **Task 3.1 · Database:** `content_packs` (kind, version, status, body, checksum).
- **Task 3.2 · Pack validation `packs.ts`:**
  - per kind: three-language text, the award rule, exercises used by templates, macro sanity
  - *Tests (Deno):* each rule.
- **Task 3.3 · Functions:** `admin` gains `packs.*`; `app-config` lists pack versions and serves a pack body with its checksum.
- **Task 3.4 · Pages:** Content (foods, Write vocabulary with a test box, eating out, exercises, templates with volume, awards, challenges, onboarding & copy), the EdgeContent board, and Plans & pricing with entitlements.
- **Task 3.5 · App:**
  - download packs when their version changes and verify the checksum
  - merge foods, exercises and templates; awards and challenge copy; copy overrides
  - entitlements read for manual grants
  - *Tests (Flutter):* a bad checksum is ignored; merges keep built-ins; an override falls back.

## Phase 4 — Comms & ship
- **Task 4.1 · Database:** `announcements`, `push_campaigns`, `push_tokens`, `support_tickets`, `ticket_messages`, `fn_calls`.
- **Task 4.2 · Functions:**
  - `admin` gains `announce.*`, `push.*`, `tickets.*`, `releases.*`, `website.*`, `health`
  - new public functions `support-ticket` and `push-register`
  - *Tests (Deno):* push quiet hours and the weekly cap; the deletion-request countdown; website path whitelist.
- **Task 4.3 · Pages:** Messaging, Support inbox, Releases, Website, System health, plus the EdgeAccounts, EdgeMessaging and EdgeSystem boards.
- **Task 4.4 · App:**
  - the announcement card on Today
  - an in-app Help form posting to `support-ticket`
  - What's New notes
  - *Tests (Flutter).*

## Finish
- Full suite runs: Flutter, Deno, node, and the shots.
- Independent whole-branch review, then a fix pass.
- Deploy: migrations, functions, Pages.
- The user signs in and enrols TOTP.

## Review focus
- **A support admin opening an account:** an audit row is written even if the lookup finds nothing.
- **An owner who loses their authenticator:** the README documents recovery by removing the factor in the Supabase dashboard.
- **Config publish while the app runs an older build:** unknown keys are ignored, and missing keys use built-in defaults.
- **A pack upload that is truncated:** the checksum fails, and the app keeps the previous pack.
- **Timezones:** pushes respect the user's local quiet hours; days are UTC everywhere on the server.
