# Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A private page at gymcoapp.com/admin showing Gymco's growth and AI cost from Supabase totals.

**Architecture:** One migration adds a deletion counter and a service-role-only `admin_stats()` that returns totals as JSON. A new `admin-stats` edge function checks the caller's email against `ADMIN_EMAILS` and returns that JSON. A static page in `site/admin/` logs in with the email code and renders it.

**Tech Stack:** Postgres (Supabase), Deno edge functions, plain HTML/CSS/JS, supabase-js 2.117.2 from jsDelivr, Node's built-in test runner, Playwright (Chromium at /opt/pw-browsers).

**Spec:** `docs/superpowers/specs/2026-10-19-admin-dashboard-design.md`

## Global Constraints

- Supabase project ref `vncadogzpeoawikgafaj`; functions use `npm:@supabase/supabase-js@2.117.2` like the existing ones.
- Only counts and sums leave the database; no email, user id or payload in any response.
- `admin_stats()` and `note_account_deletion()`: `security definer`, `set search_path = ''`, execute revoked from `public, anon, authenticated`, granted to `service_role`.
- Days are UTC (`current_date`), 30-day series are zero-filled, oldest first.
- `ADMIN_EMAILS` secret, comma-separated, compared lower-cased; initial value `ghassanhani0@gmail.com`.
- CORS origins: `https://gymcoapp.com`, `http://localhost:8765`.
- Login: `signInWithOtp({email, options: {shouldCreateUser: false}})`, `verifyOtp({email, token, type: 'email'})`.
- AI cost = `scans_month × 0.0005` USD, shown with "≈ estimate".
- Free database limit shown as 500 MB.
- Untitled UI Foundations tokens only (no Untitled icons or bundle); brand ramp replaced by a lime ramp around `#C6F432`; text on `bg-brand-solid` is dark; text pairs ≥ 4.5:1 in light and dark.
- `site/admin/` is `noindex` and disallowed in `site/robots.txt`; nothing in the public pages links to it.

## Review Focus

- A brand-new database (no rows anywhere): every number renders as 0 and the charts draw empty axes, no error banner.
- An expired or revoked session: `admin-stats` returns 401 → the page signs out locally and shows the login form, not an error loop.
- A signed-in non-admin: 403 → "This account doesn't have access" with Sign out, and no numbers are fetched again on refresh.
- The email code typed with spaces or pasted with a trailing newline: trimmed before `verifyOtp`.
- `delete-account` when `note_account_deletion()` fails: the delete still returns 204.

---

### Task 1: Database — deletion counter and `admin_stats()`

**Files:**
- Create: `supabase/migrations/20261019000000_admin_stats.sql`
- Test: `supabase/tests/admin_stats.sql` (queries run with the Supabase MCP `execute_sql`)

**Interfaces:**
- Produces: `public.note_account_deletion() returns void`; `public.admin_stats() returns jsonb` with keys `accounts:int, signups:[{day:'YYYY-MM-DD', n:int}]×30, active_7d:int, active_30d:int, scans:[{day, n:int, capped:int}]×30, scans_today:int, scans_month:int, backups:{count:int, bytes:bigint}, db_bytes:bigint, deletions:[{day, n:int}]×30, generated_at:timestamptz`.

- [ ] **Step 1: Write the checks** in `supabase/tests/admin_stats.sql`:
  - `jsonb_array_length(s->'signups') = 30`, same for `scans` and `deletions`
  - `(s->'signups'->29->>'day')::date = current_date`
  - `(s->>'accounts')::int = (select count(*) from auth.users)`
  - `has_function_privilege('anon', 'public.admin_stats()', 'execute') = false`, same for `authenticated` and for `note_account_deletion()`
  - after `select public.note_account_deletion()` inside `begin … rollback`, today's `deletions` entry is one higher.
- [ ] **Step 2: Run them before the migration.** Expected: fail with `function public.admin_stats() does not exist`.
- [ ] **Step 3: Write the migration.** `month` in `scans_month` = from `date_trunc('month', current_date)`. Active = distinct `user_id` from `backups where updated_at >= now() - interval 'N days'` union `ai_usage where day > current_date - N`. `capped` = rows with `count >= 10`. Series via `generate_series(current_date - 29, current_date, '1 day')` left-joined.
- [ ] **Step 4: Apply it** with Supabase MCP `apply_migration` (name `admin_stats`) after the user confirms, then run the checks. Expected: all true.
- [ ] **Step 5: Commit** `feat(db): admin_stats and account deletion counter`.

### Task 2: Edge functions — `admin-stats`, deletion count

**Files:**
- Create: `supabase/functions/admin-stats/index.ts`, `supabase/functions/admin-stats/access.ts`
- Modify: `supabase/functions/delete-account/index.ts`
- Test: `supabase/functions/admin-stats/access_test.ts`

**Interfaces:**
- Consumes: `admin_stats()`, `note_account_deletion()` (Task 1).
- Produces: `POST {SUPABASE_URL}/functions/v1/admin-stats`, header `Authorization: Bearer <user JWT>` → `200` admin_stats JSON | `401` no/invalid token | `403` not an admin | `405` other method; `OPTIONS` preflight → `204`. `access.ts` exports `isAdmin(email: string | undefined, list: string | undefined): boolean` and `corsHeaders(origin: string | null): Record<string, string>`.

- [ ] **Step 1: Write `access_test.ts`:** `isAdmin('GhassanHani0@gmail.com', ' ghassanhani0@gmail.com ,x@y.z')` → true; `isAdmin('a@b.c', 'x@y.z')` → false; `isAdmin(undefined, 'x@y.z')` → false; `isAdmin('a@b.c', '')` → false; `corsHeaders('https://gymcoapp.com')['Access-Control-Allow-Origin']` = `https://gymcoapp.com`; `corsHeaders('https://evil.example')` has no `Access-Control-Allow-Origin`.
- [ ] **Step 2: Run** `deno test supabase/functions/admin-stats/` (or `npx -y deno test` if deno is missing). Expected: fail, module not found.
- [ ] **Step 3: Implement `access.ts`, then `index.ts`** (service client as in `delete-account`; `auth.getUser(jwt)`; `isAdmin(user.email, Deno.env.get('ADMIN_EMAILS'))`; `rpc('admin_stats')`; every response carries `corsHeaders`). In `delete-account`, after a successful delete, `await admin.rpc('note_account_deletion')` inside try/catch, ignoring the result.
- [ ] **Step 4: Run the tests.** Expected: pass.
- [ ] **Step 5: Deploy** both with Supabase MCP `deploy_edge_function`, set `ADMIN_EMAILS` with `create_edge_function_secret`, then check with `get_edge_function` that both are active. Commit `feat(functions): admin-stats and deletion count`.

### Task 3: The page

**Files:**
- Create: `site/admin/index.html`, `site/admin/admin.css`, `site/admin/tokens.css`, `site/admin/admin.js`, `site/admin/view.js`, `site/robots.txt`
- Create: `tools/admin_tokens.py` (writes `tokens.css` from the design system's `tokens.json`)
- Test: `test/site/view.test.mjs` (node --test), `test/site/shots.mjs` (Playwright)

**Interfaces:**
- Consumes: the `admin-stats` response (Task 2).
- Produces: `view.js` (ES module, no DOM access) exports `weekCompare(signups) → {thisWeek:int, lastWeek:int, change:number|null}` (last 7 vs the 7 before; `null` when the earlier week is 0); `aiCost(scansMonth:int) → number` (× 0.0005); `fmtInt(n) → string` (en-US grouping); `fmtBytes(n) → string` (`'0 B'`, `'812 KB'`, `'3.4 MB'`); `barGeometry(series, width, height) → [{x, y, w, h, day, n}]` (max 0 draws zero-height bars); `cleanCode(s) → string` (digits only).

- [ ] **Step 1: Write `view.test.mjs`:**
  - `weekCompare` on 30 zeros → `{0, 0, null}`; 7 days of 2 after 7 days of 1 → `{14, 7, 1}`
  - `aiCost(1000)` → `0.5`
  - `fmtBytes(0)` → `'0 B'`, `fmtBytes(3_400_000)` → `'3.4 MB'`
  - `barGeometry(30 zeros, 300, 100)` → 30 bars with `h` 0
  - `cleanCode(' 12 34 56\n')` → `'123456'`
- [ ] **Step 2: Run** `node --test test/site/`. Expected: fail, module not found.
- [ ] **Step 3: Implement `view.js`; run the tests.** Expected: pass.
- [ ] **Step 4: Generate `tokens.css`.** `tools/admin_tokens.py <tokens.json> site/admin/tokens.css` emits `--name: value` for the semantic `text-*`, `bg-*`, `fg-*`, `border-*` tokens, resolving aliases, in `:root` (light) and `@media (prefers-color-scheme: dark)`, plus spacing, radius and `box-shadow-xs/sm`. `palette-brand-*` is replaced by a lime ramp (50 `#F8FEE7` … 500 `#C6F432` … 950 `#1E2905`). Then it checks the contrast of `text-primary`, `text-secondary`, `text-tertiary`, `text-brand-secondary` on `bg-primary`/`bg-secondary`, and of `text-primary` on `bg-brand-solid`, in both themes, and exits non-zero below 4.5:1.
- [ ] **Step 5: Build `index.html`, `admin.css`, `admin.js`:**
  - **Views:** login (email → code), locked (403), dashboard. Dashboard sections in spec order: header, 6 metrics, 2 charts (inline SVG from `barGeometry`, `<title>` per bar, a visually hidden table), Health, Links.
  - **States:** loading skeletons, error banner with Retry, 401 → `signOut()` and back to login.
  - **Head:** `<meta name="robots" content="noindex">`; Inter from Google Fonts.
  - **robots.txt:** `User-agent: *` / `Disallow: /admin/`.
- [ ] **Step 6: Screenshots.** `shots.mjs` serves `site/` on :8765, stubs `cdn.jsdelivr.net/npm/@supabase/supabase-js` and the function URL with Playwright `route`, and shoots: dashboard light and dark at 1280 and 390, empty database, locked, error. Look at each image. Expected: no overflow, numbers readable, empty state at 0.
- [ ] **Step 7: Commit** `feat(site): admin dashboard`.

### Task 4: Ship and verify live

- [ ] **Step 1:** Push; the Website workflow deploys. Expected: run succeeds.
- [ ] **Step 2:** Ask the user to open https://gymcoapp.com/admin/, log in, and send a screenshot. Expected: real totals matching `select public.admin_stats()`.
- [ ] **Step 3:** Ask for a second test: log in with an email not in `ADMIN_EMAILS` that has a Gymco account. Expected: the locked view.
