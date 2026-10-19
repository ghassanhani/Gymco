-- Publishing in one step: the previous published version is archived and
-- the chosen one published, in a single transaction, so phones never see
-- zero or two published versions.

create function public.publish_config(v int, by_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.remote_config where version = v and status in ('draft', 'in_review')) then
    raise exception 'not_publishable';
  end if;
  update public.remote_config set status = 'archived' where status = 'published';
  update public.remote_config set status = 'published', published_by = by_email, published_at = now() where version = v;
end;
$$;

create function public.publish_pack(pack_kind text, v int, by_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.content_packs where kind = pack_kind and version = v and status in ('draft', 'in_review')) then
    raise exception 'not_publishable';
  end if;
  update public.content_packs set status = 'archived' where kind = pack_kind and status = 'published';
  update public.content_packs set status = 'published', published_by = by_email, published_at = now()
  where kind = pack_kind and version = v;
end;
$$;

-- Today's recorded AI spend, for the budget check in food-photo.
create function public.ai_spend_today()
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(cost_eur), 0) from public.ai_usage_daily where day = current_date;
$$;

revoke execute on function public.publish_config(int, text) from public, anon, authenticated;
revoke execute on function public.publish_pack(text, int, text) from public, anon, authenticated;
revoke execute on function public.ai_spend_today() from public, anon, authenticated;
grant execute on function public.publish_config(int, text) to service_role;
grant execute on function public.publish_pack(text, int, text) to service_role;
grant execute on function public.ai_spend_today() to service_role;
