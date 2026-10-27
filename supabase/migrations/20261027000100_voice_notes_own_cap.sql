-- Voice notes no longer take one of the day's AI requests: writing a note
-- down costs a fraction of a cent. They keep a cap of their own, so a stuck
-- button or a script can't run up the bill.
create table public.voice_usage (
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  count int not null default 0,
  primary key (user_id, day)
);

alter table public.voice_usage enable row level security;

-- Notes left today after this one, or -1 when the cap is reached.
create function public.take_voice_note(uid uuid, cap int)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  insert into public.voice_usage (user_id, day, count)
  values (uid, current_date, 1)
  on conflict (user_id, day) do update
    set count = public.voice_usage.count + 1
    where public.voice_usage.count < cap
  returning count into n;
  if n is null then
    return -1;
  end if;
  return cap - n;
end;
$$;

-- A note that failed or said nothing doesn't count.
create function public.give_back_voice_note(uid uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.voice_usage set count = greatest(count - 1, 0)
  where user_id = uid and day = current_date;
$$;

revoke execute on function public.take_voice_note(uuid, int) from public, anon, authenticated;
revoke execute on function public.give_back_voice_note(uuid) from public, anon, authenticated;
grant execute on function public.take_voice_note(uuid, int) to service_role;
grant execute on function public.give_back_voice_note(uuid) to service_role;
