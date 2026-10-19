# Admin dashboard — design

Date: 19 October 2026 · Status: awaiting review

## Goal

One private page that answers "is Gymco growing, and what is the AI costing us?"
from data the backend already has, for free. It is for the owner (and anyone
added to an admin list later), not for users.

Out of scope: downloads and revenue (App Store Connect / Play Console), exact AI
spend (Anthropic console), crashes (Firebase). The page links to each.

## What the backend can and cannot see

Diaries stay on the phone, so the server only knows about people who create an
account: `auth.users`, `public.backups` (one row per account, refreshed when
the app goes to the background) and `public.ai_usage` (scans per account per
UTC day). Phone-only users are invisible. "Active" therefore means *an account
that backed up or used an AI scan in the period*; the page says so next to the
number.

## Where it lives

`https://gymcoapp.com/admin/` — a folder in `site/`, deployed by the existing
Website workflow. Not linked from the public pages, `noindex`, and excluded in
`robots.txt`. The code is public (the repo is public); that is fine because the
page holds no secrets and the data is only returned to admins.

## Architecture

```
browser (site/admin)  ──email code──▶  Supabase Auth (existing, no new accounts)
        │
        └─ POST /functions/v1/admin-stats  (user's JWT)
                 │  1. verify JWT → email
                 │  2. email ∈ ADMIN_EMAILS secret?  else 403
                 └─ 3. rpc admin_stats()  (service role)  → JSON of totals
```

### 1. Database (one migration)

- `public.account_deletions (day date primary key, count int)` — how many
  accounts were deleted per UTC day. No user id, no email.
- `public.note_account_deletion()` — adds one to today's row. Service role only.
- `public.admin_stats()` — `security definer`, `search_path = ''`, execute
  granted to `service_role` only. Returns one `jsonb`:
  - `accounts` — total rows in `auth.users`
  - `signups` — `[{day, n}]` for the last 30 UTC days, zero-filled
  - `active_7d`, `active_30d` — distinct accounts with a backup updated or an
    `ai_usage` row in the window
  - `scans` — `[{day, n, capped}]` for 30 days; `capped` = accounts that hit
    the 10-scan limit that day
  - `scans_today`, `scans_month` — sums
  - `backups` — `{count, bytes}` (`pg_column_size` of payloads)
  - `db_bytes` — `pg_database_size(current_database())`, shown against the
    free plan's 500 MB
  - `deletions` — `[{day, n}]` for 30 days
  - `generated_at`

  Only counts and sums leave the database.

### 2. Edge functions

- **`admin-stats`** (new): POST only; reads the bearer token, resolves the
  user with the service client, lower-cases the email and checks it against
  `ADMIN_EMAILS` (comma-separated secret, starting with
  `ghassanhani0@gmail.com`). Not an admin → `403` with no body detail. Admin →
  `200` with `admin_stats()`. CORS allows `https://gymcoapp.com` and
  `http://localhost:8765` (local testing) only.
- **`delete-account`** (changed): after a successful delete, calls
  `note_account_deletion()`. A failure to count never fails the delete.

### 3. The page (`site/admin/`)

`index.html`, `admin.css`, `admin.js`. supabase-js from jsDelivr pinned to an
exact version. No build step, no framework.

- **Log in:** email field → "Send code" (`signInWithOtp`,
  `shouldCreateUser: false`) → 6-digit code → `verifyOtp`. Session persists in
  the browser. "Sign out" in the header. A non-admin who signs in sees "This
  account doesn't have access" and nothing else.
- **Header:** Gymco mark, "Dashboard", last updated time, Refresh, Sign out.
- **Metric row:** Accounts · New this week (with change vs the week before) ·
  Active 7 days · Active 30 days · AI scans today · AI cost this month (≈).
- **Charts** (inline SVG, drawn by the page): sign-ups per day and AI scans per
  day, 30 days, bars with a hover readout and a visually hidden table for
  screen readers.
- **Health card:** database size vs 500 MB (meter), backups stored and their
  size, accounts that hit the daily scan cap this week, deletions this week.
- **Links card:** App Store Connect, Play Console, Supabase, Anthropic usage,
  Firebase Crashlytics.
- **States:** loading skeletons, an error banner with Retry, an empty state
  for a brand-new database (all zeros is a valid answer, not an error).

AI cost = `scans_month × 0.0005` USD, labelled "≈ estimate" with a link to the
Anthropic console. The per-scan figure is a constant at the top of `admin.js`.

## Look: Untitled UI Foundations tokens, Gymco lime

- Tokens copied as CSS custom properties from the Untitled UI Foundations
  design system: the semantic `text-*`, `bg-*`, `fg-*`, `border-*` colours
  for light and dark, Inter, the 4px spacing scale, the radius scale and
  `box-shadow-xs/sm`. Components use semantic tokens only.
- **Not copied:** the Untitled UI icons and component bundle. Their licence
  forbids redistribution and this repo is public. The few icons needed
  (refresh, sign out, external link) are drawn here.
- **Brand ramp replaced** with an 11-step lime ramp built around Gymco's
  `#C6F432`. Lime is light, so the solid brand surface takes dark text
  (`text-primary` on `bg-brand-solid`), the reverse of the stock purple's
  white text. Brand text on white uses the dark end of the ramp
  (`brand-700`/`800`) to keep 4.5:1. Every text pair is checked in both themes.
- Theme follows the system setting.

## Security

- The service-role key stays inside Supabase functions.
- The page gets totals only, and only after the email check on the server.
- `shouldCreateUser: false` stops the login form from creating accounts.
- `admin_stats` and `note_account_deletion` cannot be called by `anon` or
  `authenticated`.

## Testing

- Migration applied, then `select public.admin_stats()` run read-only against
  the live database and the JSON checked by hand.
- `admin-stats`: no token → 401; a non-admin token → 403; admin → 200.
- Page: rendered locally with Playwright against a stubbed response — light
  and dark, desktop and 390px — plus the locked-out and error states.
- Contrast of every text-on-surface pair in both themes.

## Cost

$0: GitHub Pages, Supabase free tier (one extra function, a few queries a day).
