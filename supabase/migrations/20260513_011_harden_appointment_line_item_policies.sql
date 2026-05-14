begin;

create or replace function public.can_manage_appointment_operational_data(target_appointment_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.appointments a
    where a.id = target_appointment_id
      and (
        public.is_assigned_stylist_for_appointment(target_appointment_id)
        or public.has_scoped_admin_access(a.market_id, a.territory_id)
      )
  );
$$;

comment on function public.can_manage_appointment_operational_data(uuid) is 'Allows operational updates on appointment child records for assigned stylists and scoped admins, but not owning customers.';

drop policy if exists "appointment participants are managed by appointment owners stylists and admins"
on public.appointment_participants;

create policy "appointment participants are insertable by appointment owners stylists and admins"
on public.appointment_participants
for insert
to authenticated
with check (public.can_access_appointment(appointment_id));

create policy "appointment participants are updatable by assigned stylists and scoped admins"
on public.appointment_participants
for update
to authenticated
using (public.can_manage_appointment_operational_data(appointment_id))
with check (public.can_manage_appointment_operational_data(appointment_id));

create policy "appointment participants are deletable by assigned stylists and scoped admins"
on public.appointment_participants
for delete
to authenticated
using (public.can_manage_appointment_operational_data(appointment_id));

drop policy if exists "appointment service lines are managed by appointment owners stylists and admins"
on public.appointment_services;

create policy "appointment service lines are insertable by appointment owners stylists and admins"
on public.appointment_services
for insert
to authenticated
with check (public.can_access_appointment(appointment_id));

create policy "appointment service lines are updatable by assigned stylists and scoped admins"
on public.appointment_services
for update
to authenticated
using (public.can_manage_appointment_operational_data(appointment_id))
with check (public.can_manage_appointment_operational_data(appointment_id));

create policy "appointment service lines are deletable by assigned stylists and scoped admins"
on public.appointment_services
for delete
to authenticated
using (public.can_manage_appointment_operational_data(appointment_id));

commit;