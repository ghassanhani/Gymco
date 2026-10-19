-- Checks for the Control Center schema. Every row must say ok = true.
-- Writes happen only inside the rolled-back block at the end.

with tables(t) as (values
  ('admins'), ('audit_log'), ('account_notes'), ('entitlements'), ('ai_grants'), ('remote_config'),
  ('content_packs'), ('announcements'), ('push_campaigns'), ('push_tokens'), ('support_tickets'),
  ('ticket_messages'), ('ai_usage_daily'), ('fn_calls'))
select 'rls on ' || t as name,
  coalesce((select relrowsecurity from pg_class where oid = ('public.' || t)::regclass), false) as ok
from tables
union all
select 'anon cannot read ' || t, not has_table_privilege('anon', 'public.' || t, 'select') from tables
  where t <> 'entitlements'
union all
select 'audit log is append-only', not has_table_privilege('service_role', 'public.audit_log', 'update')
  and not has_table_privilege('service_role', 'public.audit_log', 'delete')
union all select 'owner seeded', exists (select 1 from public.admins where role = 'owner')
union all select 'backups carry metadata', (select count(*) = 3 from information_schema.columns
  where table_schema = 'public' and table_name = 'backups' and column_name in ('platform', 'locale', 'app_version'))
union all select 'stats range 90', jsonb_array_length(public.admin_stats_range(90)->'signups') = 90
union all select 'stats range 7', jsonb_array_length(public.admin_stats_range(7)->'scans') = 7
union all select 'stats has mix', public.admin_stats_range(30) ? 'mix'
union all select 'no emails in stats', position('@' in public.admin_stats_range(90)::text) = 0
union all select 'users cannot read stats', not has_function_privilege('authenticated', 'public.admin_stats_range(int)', 'execute')
union all select 'default cap is 10', public.ai_cap(gen_random_uuid()) = 10;

-- A one-day grant raises that account's cap (rolled back):
begin;
insert into public.ai_grants (user_id, day, extra)
  select user_id, current_date, 5 from public.admins limit 1;
select public.ai_cap(user_id) = 15 as grant_raises_cap from public.admins limit 1;
rollback;
