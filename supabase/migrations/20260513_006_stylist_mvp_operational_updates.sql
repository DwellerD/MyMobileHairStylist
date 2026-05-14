begin;

create type public.check_in_event_type as enum (
  'check_in',
  'check_out'
);

alter table public.check_ins
drop constraint if exists check_ins_appointment_id_key;

alter table public.check_ins
add column if not exists event_type public.check_in_event_type,
add column if not exists event_notes text;

update public.check_ins
set event_type = case
  when status = 'checked_out' then 'check_out'::public.check_in_event_type
  else 'check_in'::public.check_in_event_type
end
where event_type is null;

alter table public.check_ins
alter column event_type set not null;

comment on column public.check_ins.event_type is 'Each row is now a single operational event so stylists can record separate check-in and check-out actions.';
comment on column public.check_ins.event_notes is 'Freeform operational note attached to a specific check-in or check-out event.';

create index if not exists check_ins_appointment_event_idx
on public.check_ins (appointment_id, created_at desc);

alter table public.appointment_photos
add column if not exists caption text;

comment on column public.appointment_photos.caption is 'Optional staff-facing or customer-facing caption that explains the reference image.';

commit;