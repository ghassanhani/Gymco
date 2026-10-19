-- Account card for the dashboard: found by exact email, and only sizes,
-- dates and counts. The backup's payload is never read, only measured.
create function public.admin_account_card(lookup_email text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'user_id', u.id,
    'email', u.email,
    'created_at', u.created_at,
    'last_sign_in_at', u.last_sign_in_at,
    'backup', (select jsonb_build_object('updated_at', b.updated_at, 'bytes', pg_column_size(b.payload),
                 'platform', b.platform, 'locale', b.locale, 'app_version', b.app_version)
               from public.backups b where b.user_id = u.id),
    'scans_today', coalesce((select count from public.ai_usage where user_id = u.id and day = current_date), 0),
    'scans_30d', coalesce((select sum(count)::int from public.ai_usage where user_id = u.id and day > current_date - 30), 0),
    'cap_today', public.ai_cap(u.id),
    'grant_today', (select extra from public.ai_grants where user_id = u.id and day = current_date),
    'entitlement', (select jsonb_build_object('plan', e.plan, 'source', e.source, 'expires_at', e.expires_at,
                      'granted_by', e.granted_by) from public.entitlements e where e.user_id = u.id),
    'notes', coalesce((select jsonb_agg(jsonb_build_object('note', n.note, 'by', n.admin_email, 'at', n.at) order by n.at desc)
                       from public.account_notes n where n.user_id = u.id), '[]'),
    'is_admin', exists (select 1 from public.admins a where a.user_id = u.id)
  )
  from auth.users u
  where lower(u.email) = lower(trim(lookup_email))
  limit 1;
$$;

-- Admins with their last sign-in, for Team.
create function public.admin_team()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('user_id', a.user_id, 'email', a.email, 'role', a.role,
    'invited_by', a.invited_by, 'created_at', a.created_at, 'last_sign_in_at', u.last_sign_in_at,
    'mfa', exists (select 1 from auth.mfa_factors f where f.user_id = a.user_id and f.status = 'verified'))
    order by a.created_at), '[]')
  from public.admins a join auth.users u on u.id = a.user_id;
$$;

-- An auth user's id by exact email, for inviting an admin.
create function public.admin_user_id(lookup_email text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from auth.users where lower(email) = lower(trim(lookup_email)) limit 1;
$$;

revoke execute on function public.admin_account_card(text) from public, anon, authenticated;
revoke execute on function public.admin_team() from public, anon, authenticated;
revoke execute on function public.admin_user_id(text) from public, anon, authenticated;
grant execute on function public.admin_account_card(text) to service_role;
grant execute on function public.admin_team() to service_role;
grant execute on function public.admin_user_id(text) to service_role;
