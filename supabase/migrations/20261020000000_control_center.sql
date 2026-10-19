-- Gymco Control Center: every table the dashboard and the published app
-- config need. None holds diary data. All have row-level security on and no
-- client policies unless stated, so only the service role (edge functions)
-- reads or writes them.

-- People ---------------------------------------------------------------

create table public.admins (
  user_id uuid primary key references auth.users on delete cascade,
  email text not null,
  role text not null check (role in ('viewer', 'support', 'editor', 'owner')),
  invited_by text,
  created_at timestamptz not null default now()
);

-- Append-only: the service role may read and add, never change or remove.
create table public.audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  admin_id uuid,
  admin_email text not null,
  section text not null,
  action text not null,
  object_id text,
  before jsonb,
  after jsonb,
  reason text
);
create index audit_log_at on public.audit_log (at desc);

create table public.account_notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,
  admin_email text not null,
  note text not null check (length(note) between 1 and 2000),
  at timestamptz not null default now()
);

-- Pro or Lifetime, from a store or granted by hand. The app reads its own row.
create table public.entitlements (
  user_id uuid primary key references auth.users on delete cascade,
  plan text not null check (plan in ('pro', 'lifetime')),
  source text not null check (source in ('store', 'manual')),
  expires_at timestamptz,
  granted_by text,
  at timestamptz not null default now()
);

-- Extra AI scans for one account on one UTC day.
create table public.ai_grants (
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  extra int not null check (extra between 1 and 100),
  primary key (user_id, day)
);

-- What the phone reports with its backup, so the dashboard can show the mix
-- without reading the backup.
alter table public.backups
  add column platform text check (platform in ('ios', 'android')),
  add column locale text check (locale in ('en', 'ar', 'es')),
  add column app_version text check (length(app_version) <= 32);

-- App: config, content, messaging ----------------------------------------

create table public.remote_config (
  id bigint generated always as identity primary key,
  version int not null unique,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  body jsonb not null,
  note text,
  created_by text not null,
  created_at timestamptz not null default now(),
  submitted_by text,
  published_by text,
  published_at timestamptz
);
create unique index remote_config_one_published on public.remote_config (status) where status = 'published';

create table public.content_packs (
  id bigint generated always as identity primary key,
  kind text not null check (kind in ('foods', 'vocabulary', 'eating_out', 'exercises', 'templates', 'awards', 'challenges', 'copy')),
  version int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  body jsonb not null,
  checksum text not null,
  note text,
  created_by text not null,
  created_at timestamptz not null default now(),
  submitted_by text,
  published_by text,
  published_at timestamptz,
  unique (kind, version)
);
create unique index content_packs_one_published on public.content_packs (kind) where status = 'published';

create table public.announcements (
  id bigint generated always as identity primary key,
  title jsonb not null,
  body jsonb not null,
  cta jsonb,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  targeting jsonb not null default '{}',
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  created_by text not null,
  created_at timestamptz not null default now(),
  published_by text,
  check (ends_at > starts_at)
);

create table public.push_campaigns (
  id bigint generated always as identity primary key,
  title jsonb not null,
  body jsonb not null,
  send_at_local timestamp not null,
  targeting jsonb not null default '{}',
  status text not null check (status in ('draft', 'scheduled', 'sent', 'cancelled')),
  sent_count int not null default 0,
  created_by text not null,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

-- Device tokens only: no user link, by design.
create table public.push_tokens (
  token text primary key check (length(token) <= 4096),
  platform text not null check (platform in ('ios', 'android')),
  locale text not null check (locale in ('en', 'ar', 'es')),
  utc_offset_min int not null default 0 check (utc_offset_min between -840 and 840),
  app_version text,
  updated_at timestamptz not null default now()
);

-- Support ----------------------------------------------------------------

create table public.support_tickets (
  id bigint generated always as identity primary key,
  email text not null check (length(email) <= 320),
  subject text not null check (length(subject) between 1 and 200),
  body text not null check (length(body) between 1 and 5000),
  locale text,
  app_version text,
  platform text,
  kind text not null default 'general' check (kind in ('general', 'deletion')),
  status text not null default 'new' check (status in ('new', 'waiting', 'solved')),
  tags text[] not null default '{}',
  source text not null default 'app' check (source in ('app', 'email', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Deletion requests must be answered within 30 days.
  deadline_at timestamptz
);
create index support_tickets_open on public.support_tickets (status, created_at);

create table public.ticket_messages (
  id bigint generated always as identity primary key,
  ticket_id bigint not null references public.support_tickets on delete cascade,
  from_admin boolean not null,
  author text not null,
  body text not null check (length(body) between 1 and 5000),
  at timestamptz not null default now()
);

-- Counters ---------------------------------------------------------------

create table public.ai_usage_daily (
  day date not null,
  feature text not null check (feature in ('photo', 'write', 'eating_out')),
  scans int not null default 0,
  tokens_in bigint not null default 0,
  tokens_out bigint not null default 0,
  cost_eur numeric(12, 5) not null default 0,
  failures int not null default 0,
  latency_ms_total bigint not null default 0,
  primary key (day, feature)
);

create table public.fn_calls (
  day date not null,
  fn text not null,
  calls int not null default 0,
  errors int not null default 0,
  primary key (day, fn)
);

-- Row-level security and grants ---------------------------------------------

alter table public.admins enable row level security;
alter table public.audit_log enable row level security;
alter table public.account_notes enable row level security;
alter table public.entitlements enable row level security;
alter table public.ai_grants enable row level security;
alter table public.remote_config enable row level security;
alter table public.content_packs enable row level security;
alter table public.announcements enable row level security;
alter table public.push_campaigns enable row level security;
alter table public.push_tokens enable row level security;
alter table public.support_tickets enable row level security;
alter table public.ticket_messages enable row level security;
alter table public.ai_usage_daily enable row level security;
alter table public.fn_calls enable row level security;

create policy "own entitlement: read" on public.entitlements
  for select to authenticated using ((select auth.uid()) = user_id);

do $$
declare t text;
begin
  foreach t in array array['admins', 'audit_log', 'account_notes', 'entitlements', 'ai_grants', 'remote_config',
    'content_packs', 'announcements', 'push_campaigns', 'push_tokens', 'support_tickets', 'ticket_messages',
    'ai_usage_daily', 'fn_calls']
  loop
    execute format('revoke all on public.%I from anon', t);
    if t <> 'entitlements' then
      execute format('revoke all on public.%I from authenticated', t);
    end if;
  end loop;
end $$;
revoke update, delete, truncate on public.audit_log from service_role;

-- Ghassan is the only owner.
insert into public.admins (user_id, email, role, invited_by)
select id, email, 'owner', 'seed' from auth.users where lower(email) = 'ghassanhani0@gmail.com'
on conflict do nothing;

-- AI cap -----------------------------------------------------------------

-- Today's scan allowance for an account: the published config's limit (10
-- when nothing is published) plus any grant for today.
create function public.ai_cap(uid uuid)
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
      (select (body #>> '{limits,ai_scans_per_day}')::int from public.remote_config
       where status = 'published' order by version desc limit 1), 10)
    + coalesce((select extra from public.ai_grants where user_id = uid and day = current_date), 0);
$$;

create or replace function public.take_ai_credit(uid uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  cap int := public.ai_cap(uid);
  n int;
begin
  insert into public.ai_usage (user_id, day, count)
  values (uid, current_date, 1)
  on conflict (user_id, day) do update
    set count = public.ai_usage.count + 1
    where public.ai_usage.count < cap
  returning count into n;
  if n is null then
    return -1;
  end if;
  return cap - n;
end;
$$;

-- Counters written by the edge functions.
create function public.note_fn_call(fn text, ok boolean)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.fn_calls (day, fn, calls, errors) values (current_date, fn, 1, case when ok then 0 else 1 end)
  on conflict (day, fn) do update set calls = public.fn_calls.calls + 1,
    errors = public.fn_calls.errors + case when ok then 0 else 1 end;
$$;

create function public.note_ai_usage(feature text, tokens_in int, tokens_out int, cost_eur numeric, ok boolean, latency_ms int)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.ai_usage_daily (day, feature, scans, tokens_in, tokens_out, cost_eur, failures, latency_ms_total)
  values (current_date, feature, 1, tokens_in, tokens_out, cost_eur, case when ok then 0 else 1 end, latency_ms)
  on conflict (day, feature) do update set
    scans = public.ai_usage_daily.scans + 1,
    tokens_in = public.ai_usage_daily.tokens_in + excluded.tokens_in,
    tokens_out = public.ai_usage_daily.tokens_out + excluded.tokens_out,
    cost_eur = public.ai_usage_daily.cost_eur + excluded.cost_eur,
    failures = public.ai_usage_daily.failures + excluded.failures,
    latency_ms_total = public.ai_usage_daily.latency_ms_total + excluded.latency_ms_total;
$$;

-- Overview ---------------------------------------------------------------

-- Every number on the Overview for the last [range_days] UTC days (7–90).
-- Counts and sums only. Cost per day is the recorded spend where there is
-- one, else scans × €0.0005 (an estimate, before token logging began).
create function public.admin_stats_range(range_days int)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with r as (select greatest(7, least(90, range_days)) as n),
  days as (
    select d::date as day from r, generate_series(current_date - (r.n - 1), current_date, interval '1 day') d
  ),
  signups as (
    select created_at::date as day, count(*)::int as n from auth.users
    where created_at >= current_date - 89 group by 1
  ),
  scans as (
    select day, sum(count)::int as n from public.ai_usage where day >= current_date - 89 group by 1
  ),
  spend as (
    select day, sum(cost_eur) as eur, sum(scans) as scans, sum(failures) as failures
    from public.ai_usage_daily where day >= current_date - 89 group by 1
  ),
  daily as (
    select d.day, coalesce(s.n, 0) as signups, coalesce(a.n, 0) as scans,
      coalesce(p.eur, coalesce(a.n, 0) * 0.0005) as cost,
      coalesce(x.count, 0) as deletions
    from days d
    left join signups s using (day)
    left join scans a using (day)
    left join spend p using (day)
    left join public.account_deletions x using (day)
  )
  select jsonb_build_object(
    'range', (select n from r),
    'accounts', (select count(*)::int from auth.users),
    'signups_today', (select coalesce(sum(n), 0)::int from signups where day = current_date),
    'signups_7d', (select coalesce(sum(n), 0)::int from signups where day > current_date - 7),
    'signups_30d', (select coalesce(sum(n), 0)::int from signups where day > current_date - 30),
    'active_7d', (select count(*)::int from public.backups where updated_at > now() - interval '7 days'),
    'active_30d', (select count(*)::int from public.backups where updated_at > now() - interval '30 days'),
    'scans_today', (select coalesce(sum(count), 0)::int from public.ai_usage where day = current_date),
    'cost_today', (select cost from daily where day = current_date),
    'cost_month', (select coalesce(sum(cost), 0) from daily where day >= date_trunc('month', current_date)::date),
    'at_cap_today', (select count(*)::int from public.ai_usage u
                     where u.day = current_date and u.count >= public.ai_cap(u.user_id)),
    'deletions_30d', (select coalesce(sum(count), 0)::int from public.account_deletions where day > current_date - 30),
    'signups', (select jsonb_agg(jsonb_build_object('day', day, 'n', signups) order by day) from daily),
    'scans', (select jsonb_agg(jsonb_build_object('day', day, 'n', scans, 'cost', round(cost::numeric, 4)) order by day) from daily),
    'deletions', (select jsonb_agg(jsonb_build_object('day', day, 'n', deletions) order by day) from daily),
    'ai_failure_rate_today', (select case when coalesce(scans, 0) = 0 then 0 else round(failures::numeric / scans, 4) end
                              from spend where day = current_date),
    'backups', (select jsonb_build_object('count', count(*)::int, 'bytes', coalesce(sum(pg_column_size(payload)), 0)::bigint)
                from public.backups),
    'db_bytes', pg_database_size(current_database()),
    'mix', jsonb_build_object(
      'locale', (select coalesce(jsonb_object_agg(k, n), '{}') from
                  (select coalesce(locale, 'unknown') as k, count(*)::int as n from public.backups group by 1) t),
      'platform', (select coalesce(jsonb_object_agg(k, n), '{}') from
                  (select coalesce(platform, 'unknown') as k, count(*)::int as n from public.backups group by 1) t),
      'app_version', (select coalesce(jsonb_object_agg(k, n), '{}') from
                  (select coalesce(app_version, 'unknown') as k, count(*)::int as n from public.backups group by 1) t)),
    'generated_at', now()
  );
$$;

revoke execute on function public.ai_cap(uuid) from public, anon, authenticated;
revoke execute on function public.note_fn_call(text, boolean) from public, anon, authenticated;
revoke execute on function public.note_ai_usage(text, int, int, numeric, boolean, int) from public, anon, authenticated;
revoke execute on function public.admin_stats_range(int) from public, anon, authenticated;
grant execute on function public.ai_cap(uuid) to service_role;
grant execute on function public.note_fn_call(text, boolean) to service_role;
grant execute on function public.note_ai_usage(text, int, int, numeric, boolean, int) to service_role;
grant execute on function public.admin_stats_range(int) to service_role;
