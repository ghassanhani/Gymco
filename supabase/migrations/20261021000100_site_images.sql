-- Pictures the Control Center puts on gymcoapp.com (the hero phones). Public
-- to read, so the page can show them; only the admin function writes, with
-- the service role, so no upload policies are needed.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site', 'site', true, 2000000, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;
