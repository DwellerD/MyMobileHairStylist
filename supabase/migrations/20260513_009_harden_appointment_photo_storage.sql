begin;

drop policy if exists "authenticated users can read appointment photos" on storage.objects;
drop policy if exists "authenticated users can upload appointment photos" on storage.objects;
drop policy if exists "authenticated users can update appointment photos" on storage.objects;
drop policy if exists "authenticated users can delete appointment photos" on storage.objects;

create policy "users read only their own uploaded appointment photos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'appointment-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "users upload only to their own appointment photo folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'appointment-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "users update only their own appointment photos"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'appointment-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'appointment-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "users delete only their own appointment photos"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'appointment-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- TODO: When admins and assigned stylists need image previews, expose signed
-- URLs through a trusted backend function instead of broadening raw Storage
-- read access for all authenticated users.

commit;