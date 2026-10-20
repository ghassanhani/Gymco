-- The landing page at gymcoapp.com/ as one versioned document, and the
-- waitlist its "Notify me" fills. Service-role only, like the rest.

-- Landing ------------------------------------------------------------------

-- Same shape and statuses as remote_config; the body is checked by the admin
-- function (_shared/landing.ts) and served by app-config?site=landing.
create table public.site_landing (
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
create unique index site_landing_one_published on public.site_landing (status) where status = 'published';

-- Mirrors publish_config: archive the live version and publish the chosen one in one step.
create function public.publish_landing(v int, by_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.site_landing where version = v and status in ('draft', 'in_review')) then
    raise exception 'not_publishable';
  end if;
  update public.site_landing set status = 'archived' where status = 'published';
  update public.site_landing set status = 'published', published_by = by_email, published_at = now() where version = v;
end;
$$;

-- Waitlist -----------------------------------------------------------------

-- One row per address; a repeat sign-up keeps the first row. Named for the
-- landing page: this project already holds another site's `waitlist` table.
create table public.landing_waitlist (
  email text primary key check (length(email) <= 320),
  locale text check (locale in ('en', 'ar', 'es')),
  created_at timestamptz not null default now()
);
create index landing_waitlist_created_at on public.landing_waitlist (created_at);

create function public.waitlist_stats()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'count', (select count(*)::int from public.landing_waitlist),
    'last_7d', (select count(*)::int from public.landing_waitlist where created_at >= now() - interval '7 days'));
$$;

-- Row-level security and grants ---------------------------------------------

alter table public.site_landing enable row level security;
alter table public.landing_waitlist enable row level security;
revoke all on public.site_landing from anon, authenticated;
revoke all on public.landing_waitlist from anon, authenticated;
grant select, insert, update on public.site_landing to service_role;
grant select, insert, update, delete on public.landing_waitlist to service_role;

revoke execute on function public.publish_landing(int, text) from public, anon, authenticated;
revoke execute on function public.waitlist_stats() from public, anon, authenticated;
grant execute on function public.publish_landing(int, text) to service_role;
grant execute on function public.waitlist_stats() to service_role;
