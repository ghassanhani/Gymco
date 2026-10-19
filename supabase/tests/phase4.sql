-- Checks for the Phase 4 schema. Every check raises with its name when it
-- fails; the block ends with ALL_OK, which also rolls back every write here.

do $$
declare
  r record;
  n int;
  before_calls int;
  counts jsonb;
begin
  -- Locked down like the rest.
  if not (select relrowsecurity from pg_class where oid = 'public.website_pages'::regclass) then raise exception 'rls website_pages'; end if;
  if not (select relrowsecurity from pg_class where oid = 'public.release_notes'::regclass) then raise exception 'rls release_notes'; end if;
  if has_table_privilege('anon', 'public.website_pages', 'select') then raise exception 'anon reads website_pages'; end if;
  if has_table_privilege('authenticated', 'public.release_notes', 'select') then raise exception 'users read release_notes'; end if;
  if has_function_privilege('authenticated', 'public.publish_page(text, int, text)', 'execute') then raise exception 'users publish pages'; end if;
  if has_function_privilege('anon', 'public.fn_calls_24h()', 'execute') then raise exception 'anon reads fn_calls_24h'; end if;
  if has_function_privilege('anon', 'public.support_ticket_counts()', 'execute') then raise exception 'anon reads ticket counts'; end if;
  if has_function_privilege('anon', 'public.push_token_count()', 'execute') then raise exception 'anon reads token count'; end if;
  if not has_function_privilege('service_role', 'public.publish_page(text, int, text)', 'execute') then raise exception 'service cannot publish pages'; end if;

  -- publish_page: v1 goes live, v2 replaces it and archives v1, a missing version is refused.
  insert into public.website_pages (page, version, status, body, created_by)
    values ('support', 1, 'draft', '{"title":{"en":"Support","ar":"الدعم","es":"Soporte"},"markdown":{"en":"# Help","ar":"# مساعدة","es":"# Ayuda"},"updated":"2026-10-20"}', 't@gymco.test');
  perform public.publish_page('support', 1, 'o@gymco.test');
  select * into r from public.website_pages where page = 'support' and version = 1;
  if r.status <> 'published' or r.published_by <> 'o@gymco.test' or r.published_at is null then raise exception 'v1 not published'; end if;
  insert into public.website_pages (page, version, status, body, created_by) values ('support', 2, 'in_review', '{}', 't@gymco.test');
  perform public.publish_page('support', 2, 'o@gymco.test');
  if (select status from public.website_pages where page = 'support' and version = 1) <> 'archived' then raise exception 'v1 not archived'; end if;
  if (select status from public.website_pages where page = 'support' and version = 2) <> 'published' then raise exception 'v2 not published'; end if;
  if (select count(*) from public.website_pages where page = 'support' and status = 'published') <> 1 then raise exception 'two published'; end if;
  begin
    perform public.publish_page('support', 9, 'o@gymco.test');
    raise exception 'published a missing version';
  exception when others then
    if sqlerrm <> 'not_publishable' then raise; end if;
  end;
  begin
    insert into public.website_pages (page, version, status, body, created_by) values ('admin', 1, 'draft', '{}', 't');
    raise exception 'unknown page accepted';
  exception when check_violation then null;
  end;

  -- release_notes: one per build, unpublished by default.
  insert into public.release_notes (build, version, body, created_by) values (104, '1.2.0', '{"en":"Faster","ar":"أسرع","es":"Más rápido"}', 't@gymco.test');
  if (select published from public.release_notes where build = 104) then raise exception 'note published by default'; end if;
  begin
    insert into public.release_notes (build, version, body, created_by) values (104, '1.2.1', '{}', 't');
    raise exception 'duplicate build accepted';
  exception when unique_violation then null;
  end;

  -- fn_calls_24h sums today and yesterday only.
  select coalesce(calls, 0) into before_calls from public.fn_calls_24h() where fn = 't_phase4';
  insert into public.fn_calls (day, fn, calls, errors) values
    (current_date, 't_phase4', 3, 0), (current_date - 1, 't_phase4', 2, 1), (current_date - 2, 't_phase4', 9, 9);
  select calls, errors into r from public.fn_calls_24h() where fn = 't_phase4';
  if r.calls <> coalesce(before_calls, 0) + 5 or r.errors <> 1 then raise exception 'fn_calls_24h sums wrong: % %', r.calls, r.errors; end if;

  -- support_ticket_counts: a fresh, an overdue open deletion and a solved deletion.
  insert into public.support_tickets (email, subject, body, kind, status, deadline_at) values
    ('t1@example.com', 's', 'b', 'general', 'new', null),
    ('t2@example.com', 's', 'b', 'deletion', 'waiting', now() - interval '1 day'),
    ('t3@example.com', 's', 'b', 'deletion', 'new', now() + interval '29 days'),
    ('t4@example.com', 's', 'b', 'deletion', 'solved', now() - interval '5 days');
  select public.support_ticket_counts() into counts;
  if (counts->>'new')::int < 2 or (counts->>'waiting')::int < 1 or (counts->>'solved')::int < 1
     or (counts->>'deletion_open')::int < 2 or (counts->>'overdue')::int < 1 then
    raise exception 'ticket counts wrong: %', counts;
  end if;
  if (counts->>'deletion_open')::int <> (select count(*) from public.support_tickets where kind = 'deletion' and status <> 'solved') then
    raise exception 'deletion_open mismatch';
  end if;

  -- push_token_count counts rows.
  select public.push_token_count() into n;
  insert into public.push_tokens (token, platform, locale, utc_offset_min) values ('t_phase4_token', 'ios', 'en', 60);
  if public.push_token_count() <> n + 1 then raise exception 'push_token_count did not grow'; end if;

  raise exception 'ALL_OK';
end $$;
