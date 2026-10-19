-- Phase 4: website pages as versions, release notes, and the counts the
-- support inbox and health page read. Service-role only, like the rest.

-- Website -----------------------------------------------------------------

-- Same shape and statuses as content_packs, minus checksum and kind; the
-- body is { title: T3, markdown: T3, updated: "YYYY-MM-DD" }.
create table public.website_pages (
  id bigint generated always as identity primary key,
  page text not null check (page in ('home', 'support', 'privacy', 'terms', 'delete-account')),
  version int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  body jsonb not null,
  note text,
  created_by text not null,
  created_at timestamptz not null default now(),
  submitted_by text,
  published_by text,
  published_at timestamptz,
  unique (page, version)
);
create unique index website_pages_one_published on public.website_pages (page) where status = 'published';

-- Mirrors publish_pack: archive the live version and publish the chosen one in one step.
create function public.publish_page(page_name text, v int, by_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.website_pages where page = page_name and version = v and status in ('draft', 'in_review')) then
    raise exception 'not_publishable';
  end if;
  update public.website_pages set status = 'archived' where page = page_name and status = 'published';
  update public.website_pages set status = 'published', published_by = by_email, published_at = now()
  where page = page_name and version = v;
end;
$$;

-- Releases ----------------------------------------------------------------

-- One note per build; body is T3 with one bullet per line. Phones get the
-- note for their build through app-config once it is published.
create table public.release_notes (
  build int primary key,
  version text not null check (length(version) between 1 and 32),
  body jsonb not null,
  published boolean not null default false,
  created_by text not null,
  created_at timestamptz not null default now(),
  published_at timestamptz
);

-- Counts ------------------------------------------------------------------

-- Calls and errors per function over today and yesterday (UTC).
create function public.fn_calls_24h()
returns table (fn text, calls int, errors int)
language sql
stable
security definer
set search_path = ''
as $$
  select fn, sum(calls)::int, sum(errors)::int from public.fn_calls
  where day >= current_date - 1 group by fn order by fn;
$$;

create function public.support_ticket_counts()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'new', (select count(*)::int from public.support_tickets where status = 'new'),
    'waiting', (select count(*)::int from public.support_tickets where status = 'waiting'),
    'solved', (select count(*)::int from public.support_tickets where status = 'solved'),
    'deletion_open', (select count(*)::int from public.support_tickets where kind = 'deletion' and status <> 'solved'),
    'overdue', (select count(*)::int from public.support_tickets
                where kind = 'deletion' and status <> 'solved' and deadline_at < now()));
$$;

create function public.push_token_count()
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int from public.push_tokens;
$$;

-- Row-level security and grants ---------------------------------------------

alter table public.website_pages enable row level security;
alter table public.release_notes enable row level security;
revoke all on public.website_pages from anon, authenticated;
revoke all on public.release_notes from anon, authenticated;

revoke execute on function public.publish_page(text, int, text) from public, anon, authenticated;
revoke execute on function public.fn_calls_24h() from public, anon, authenticated;
revoke execute on function public.support_ticket_counts() from public, anon, authenticated;
revoke execute on function public.push_token_count() from public, anon, authenticated;
grant execute on function public.publish_page(text, int, text) to service_role;
grant execute on function public.fn_calls_24h() to service_role;
grant execute on function public.support_ticket_counts() to service_role;
grant execute on function public.push_token_count() to service_role;
