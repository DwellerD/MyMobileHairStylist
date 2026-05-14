begin;

alter table public.household_members
add column if not exists hair_notes text;

comment on column public.household_members.hair_notes is 'Customer-provided hair context such as texture, past cuts, or styling concerns.';

alter table public.appointments
add column if not exists preferred_date date,
add column if not exists preferred_time_window text,
add column if not exists estimated_total_cents integer check (estimated_total_cents is null or estimated_total_cents >= 0),
add column if not exists estimated_duration_minutes integer check (estimated_duration_minutes is null or estimated_duration_minutes >= 0);

comment on column public.appointments.preferred_date is 'Customer-requested preferred service date before an admin confirms the schedule.';
comment on column public.appointments.preferred_time_window is 'Human-readable preferred arrival window such as Morning, Midday, or Afternoon.';
comment on column public.appointments.estimated_total_cents is 'Starting estimate shown to the customer before admin review and final confirmation.';
comment on column public.appointments.estimated_duration_minutes is 'Estimated total appointment duration based on selected services.';

create index if not exists appointments_preferred_date_idx
on public.appointments (preferred_date);

commit;