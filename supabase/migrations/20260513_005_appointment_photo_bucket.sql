begin;

insert into storage.buckets (id, name, public)
values ('appointment-photos', 'appointment-photos', false)
on conflict (id) do nothing;

drop policy if exists "authenticated users can read appointment photos" on storage.objects;
drop policy if exists "authenticated users can upload appointment photos" on storage.objects;
drop policy if exists "authenticated users can update appointment photos" on storage.objects;
drop policy if exists "authenticated users can delete appointment photos" on storage.objects;

create policy "authenticated users can read appointment photos"
on storage.objects
for select
to authenticated
using (bucket_id = 'appointment-photos');

create policy "authenticated users can upload appointment photos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'appointment-photos'
  and auth.uid() is not null
);

create policy "authenticated users can update appointment photos"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'appointment-photos'
  and auth.uid() is not null
)
with check (
  bucket_id = 'appointment-photos'
  and auth.uid() is not null
);

create policy "authenticated users can delete appointment photos"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'appointment-photos'
  and auth.uid() is not null
);

-- TODO: Tighten these storage policies before production so uploads and reads are
-- scoped by appointment ownership instead of all authenticated users.

commit;