-- Feature requests sent from the app are support tickets of their own kind,
-- listed on their own tab and kept out of New / Waiting / Solved.
alter table public.support_tickets drop constraint if exists support_tickets_kind_check;
alter table public.support_tickets
  add constraint support_tickets_kind_check check (kind in ('general', 'deletion', 'feature'));

-- The tab counts: New / Waiting / Solved leave feature requests out, as their
-- tabs do, and feature_open counts the ones not marked solved.
create or replace function public.support_ticket_counts()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'new', (select count(*)::int from public.support_tickets where status = 'new' and kind <> 'feature'),
    'waiting', (select count(*)::int from public.support_tickets where status = 'waiting' and kind <> 'feature'),
    'solved', (select count(*)::int from public.support_tickets where status = 'solved' and kind <> 'feature'),
    'deletion_open', (select count(*)::int from public.support_tickets where kind = 'deletion' and status <> 'solved'),
    'overdue', (select count(*)::int from public.support_tickets
                where kind = 'deletion' and status <> 'solved' and deadline_at < now()),
    'feature_open', (select count(*)::int from public.support_tickets where kind = 'feature' and status <> 'solved'));
$$;

revoke execute on function public.support_ticket_counts() from public, anon, authenticated;
grant execute on function public.support_ticket_counts() to service_role;
