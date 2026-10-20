-- Checks for the landing schema. Every check raises with its name when it
-- fails; the block ends with ALL_OK, which also rolls back every write here.

do $$
declare
  r record;
  stats jsonb;
  before_count int;
  before_7d int;
  b int;
begin
  -- Locked down like the rest.
  if not (select relrowsecurity from pg_class where oid = 'public.site_landing'::regclass) then raise exception 'rls site_landing'; end if;
  if not (select relrowsecurity from pg_class where oid = 'public.landing_waitlist'::regclass) then raise exception 'rls waitlist'; end if;
  if has_table_privilege('anon', 'public.site_landing', 'select') then raise exception 'anon reads site_landing'; end if;
  if has_table_privilege('authenticated', 'public.site_landing', 'insert') then raise exception 'users write site_landing'; end if;
  if has_table_privilege('anon', 'public.landing_waitlist', 'insert') then raise exception 'anon writes waitlist'; end if;
  if has_table_privilege('anon', 'public.landing_waitlist', 'select') then raise exception 'anon reads waitlist'; end if;
  if has_table_privilege('authenticated', 'public.landing_waitlist', 'select') then raise exception 'users read waitlist'; end if;
  if has_function_privilege('authenticated', 'public.publish_landing(int, text)', 'execute') then raise exception 'users publish landing'; end if;
  if has_function_privilege('anon', 'public.publish_landing(int, text)', 'execute') then raise exception 'anon publishes landing'; end if;
  if has_function_privilege('anon', 'public.waitlist_stats()', 'execute') then raise exception 'anon reads waitlist_stats'; end if;
  if has_function_privilege('authenticated', 'public.waitlist_stats()', 'execute') then raise exception 'users read waitlist_stats'; end if;
  if not has_function_privilege('service_role', 'public.publish_landing(int, text)', 'execute') then raise exception 'service cannot publish landing'; end if;
  if not has_function_privilege('service_role', 'public.waitlist_stats()', 'execute') then raise exception 'service cannot read waitlist_stats'; end if;
  if not has_table_privilege('service_role', 'public.landing_waitlist', 'insert') then raise exception 'service cannot write waitlist'; end if;

  -- Versions above any already there, so this runs on a live database too.
  select coalesce(max(version), 0) into b from public.site_landing;

  -- publish_landing: v1 goes live, v2 replaces it and archives v1, a missing or live version is refused.
  insert into public.site_landing (version, status, body, created_by) values (b + 1, 'draft', '{"beta": false}', 't@gymco.test');
  perform public.publish_landing(b + 1, 'o@gymco.test');
  select * into r from public.site_landing where version = b + 1;
  if r.status <> 'published' or r.published_by <> 'o@gymco.test' or r.published_at is null then raise exception 'v1 not published'; end if;
  insert into public.site_landing (version, status, body, created_by) values (b + 2, 'in_review', '{}', 't@gymco.test');
  perform public.publish_landing(b + 2, 'o@gymco.test');
  if (select status from public.site_landing where version = b + 1) <> 'archived' then raise exception 'v1 not archived'; end if;
  if (select status from public.site_landing where version = b + 2) <> 'published' then raise exception 'v2 not published'; end if;
  if (select count(*) from public.site_landing where status = 'published') <> 1 then raise exception 'two published'; end if;
  begin
    perform public.publish_landing(b + 9, 'o@gymco.test');
    raise exception 'published a missing version';
  exception when others then
    if sqlerrm <> 'not_publishable' then raise; end if;
  end;
  begin
    perform public.publish_landing(b + 2, 'o@gymco.test');
    raise exception 'republished the live version';
  exception when others then
    if sqlerrm <> 'not_publishable' then raise; end if;
  end;
  begin
    insert into public.site_landing (version, status, body, created_by) values (b + 3, 'published', '{}', 't');
    raise exception 'second published row accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.site_landing (version, status, body, created_by) values (b + 2, 'draft', '{}', 't');
    raise exception 'duplicate version accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.site_landing (version, status, body, created_by) values (b + 4, 'live', '{}', 't');
    raise exception 'unknown status accepted';
  exception when check_violation then null;
  end;

  -- waitlist: one row per email, known locales, bounded length.
  stats := public.waitlist_stats();
  before_count := (stats->>'count')::int;
  before_7d := (stats->>'last_7d')::int;
  insert into public.landing_waitlist (email, locale) values ('t_landing_1@example.com', 'en'), ('t_landing_2@example.com', 'ar');
  insert into public.landing_waitlist (email, locale, created_at) values ('t_landing_3@example.com', 'es', now() - interval '8 days');
  insert into public.landing_waitlist (email, locale) values ('t_landing_1@example.com', 'es') on conflict (email) do nothing;
  if (select locale from public.landing_waitlist where email = 't_landing_1@example.com') <> 'en' then raise exception 'repeat changed the row'; end if;
  begin
    insert into public.landing_waitlist (email, locale) values ('t_landing_1@example.com', 'en');
    raise exception 'duplicate email accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.landing_waitlist (email, locale) values ('t_landing_4@example.com', 'fr');
    raise exception 'unknown locale accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.landing_waitlist (email, locale) values (repeat('a', 310) || '@example.com', 'en');
    raise exception 'long email accepted';
  exception when check_violation then null;
  end;

  -- waitlist_stats counts every row and the last 7 days.
  select public.waitlist_stats() into stats;
  if not (stats ? 'count' and stats ? 'last_7d') then raise exception 'waitlist_stats shape: %', stats; end if;
  if (stats->>'count')::int <> before_count + 3 or (stats->>'last_7d')::int <> before_7d + 2 then
    raise exception 'waitlist_stats wrong: %', stats;
  end if;

  raise exception 'ALL_OK';
end $$;
