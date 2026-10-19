-- admin_stats() gains capped_7d: accounts (not account-days) that hit the
-- daily scan cap in the last 7 days. Grants are unchanged by create or replace.

-- Everything the dashboard shows, as one JSON object. Days are UTC; each
-- series is the last 30 days, oldest first, with empty days as zero.
create or replace function public.admin_stats()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with days as (
    select d::date as day from generate_series(current_date - 29, current_date, interval '1 day') d
  ),
  signups as (
    select created_at::date as day, count(*)::int as n
    from auth.users where created_at >= current_date - 29 group by 1
  ),
  scans as (
    select day, sum(count)::int as n, count(*) filter (where count >= 10)::int as capped
    from public.ai_usage where day >= current_date - 29 group by 1
  ),
  active as (
    select user_id, updated_at::date as day from public.backups where updated_at >= current_date - 29
    union all
    select user_id, day from public.ai_usage where day >= current_date - 29
  )
  select jsonb_build_object(
    'accounts', (select count(*)::int from auth.users),
    'signups', (select jsonb_agg(jsonb_build_object('day', d.day, 'n', coalesce(s.n, 0)) order by d.day)
                from days d left join signups s using (day)),
    'active_7d', (select count(distinct user_id)::int from active where day > current_date - 7),
    'active_30d', (select count(distinct user_id)::int from active),
    'scans', (select jsonb_agg(jsonb_build_object('day', d.day, 'n', coalesce(s.n, 0), 'capped', coalesce(s.capped, 0))
                order by d.day)
              from days d left join scans s using (day)),
    'capped_7d', (select count(distinct user_id)::int from public.ai_usage
                  where day > current_date - 7 and count >= 10),
    'scans_today', (select coalesce(sum(count), 0)::int from public.ai_usage where day = current_date),
    'scans_month', (select coalesce(sum(count), 0)::int from public.ai_usage
                    where day >= date_trunc('month', current_date)::date),
    'backups', (select jsonb_build_object('count', count(*)::int, 'bytes', coalesce(sum(pg_column_size(payload)), 0)::bigint)
                from public.backups),
    'db_bytes', pg_database_size(current_database()),
    'deletions', (select jsonb_agg(jsonb_build_object('day', d.day, 'n', coalesce(a.count, 0)) order by d.day)
                  from days d left join public.account_deletions a using (day)),
    'generated_at', now()
  );
$$;

