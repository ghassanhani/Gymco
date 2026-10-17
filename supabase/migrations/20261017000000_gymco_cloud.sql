-- Gymco cloud: one backup per account, and a daily allowance of AI photo scans.
-- Everything else stays on the phone.

create table public.backups (
  user_id uuid primary key references auth.users on delete cascade,
  payload jsonb not null,
  schema_version int not null,
  updated_at timestamptz not null default now()
);

alter table public.backups enable row level security;

create policy "own backup: read" on public.backups
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own backup: insert" on public.backups
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own backup: update" on public.backups
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own backup: delete" on public.backups
  for delete to authenticated using ((select auth.uid()) = user_id);

create table public.ai_usage (
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  count int not null default 0,
  primary key (user_id, day)
);

alter table public.ai_usage enable row level security;

-- Read your own count; writes only through the functions below.
create policy "own usage: read" on public.ai_usage
  for select to authenticated using ((select auth.uid()) = user_id);

-- Takes one scan from today's allowance (UTC days) for a user the
-- food-photo function has already verified. Returns how many are left after
-- this one, or -1 when today's are used up. Only the server can call these:
-- a client that could refund itself would have no cap.
create function public.take_ai_credit(uid uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  cap constant int := 10;
  n int;
begin
  insert into public.ai_usage (user_id, day, count)
  values (uid, current_date, 1)
  on conflict (user_id, day) do update
    set count = public.ai_usage.count + 1
    where public.ai_usage.count < cap
  returning count into n;
  if n is null then
    return -1;
  end if;
  return cap - n;
end;
$$;

-- Gives a scan back when the model call failed.
create function public.refund_ai_credit(uid uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.ai_usage
  set count = greatest(count - 1, 0)
  where user_id = uid and day = current_date;
$$;

revoke execute on function public.take_ai_credit(uuid) from public, anon, authenticated;
revoke execute on function public.refund_ai_credit(uuid) from public, anon, authenticated;
grant execute on function public.take_ai_credit(uuid) to service_role;
grant execute on function public.refund_ai_credit(uuid) to service_role;
