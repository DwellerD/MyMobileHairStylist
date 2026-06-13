begin;

alter table public.appointments
add column if not exists stylist_preference_type text
  not null
  default 'any'
  check (stylist_preference_type in ('any', 'specific'));

comment on column public.appointments.stylist_preference_type is
  'Customer stylist preference mode: any (first available) or specific (requested stylist).';

update public.appointments
set stylist_preference_type = case
  when requested_stylist_profile_id is null then 'any'
  else 'specific'
end
where stylist_preference_type is distinct from case
  when requested_stylist_profile_id is null then 'any'
  else 'specific'
end;

commit;
