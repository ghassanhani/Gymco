-- Checks for admin_stats() and the deletion counter. Read-only: the one write
-- runs inside a transaction that is rolled back. Every row must say true.
with s as (select public.admin_stats() as s)
select 'signups is 30 days' as check, jsonb_array_length(s->'signups') = 30 as ok from s
union all select 'scans is 30 days', jsonb_array_length(s->'scans') = 30 from s
union all select 'deletions is 30 days', jsonb_array_length(s->'deletions') = 30 from s
union all select 'series ends today', (s->'signups'->29->>'day')::date = current_date from s
union all select 'accounts match', (s->>'accounts')::int = (select count(*) from auth.users) from s
union all select 'no emails leak', position('@' in s::text) = 0 from s
union all select 'anon cannot read', not has_function_privilege('anon', 'public.admin_stats()', 'execute')
union all select 'users cannot read', not has_function_privilege('authenticated', 'public.admin_stats()', 'execute')
union all select 'anon cannot count', not has_function_privilege('anon', 'public.note_account_deletion()', 'execute')
union all select 'users cannot count', not has_function_privilege('authenticated', 'public.note_account_deletion()', 'execute');

-- Counting a deletion adds one to today (rolled back, nothing is kept):
begin;
create temp table t_before as
  select coalesce((select count from public.account_deletions where day = current_date), 0) as n;
select public.note_account_deletion();
select (public.admin_stats()->'deletions'->29->>'n')::int - (select n from t_before) = 1 as added_one;
rollback;
