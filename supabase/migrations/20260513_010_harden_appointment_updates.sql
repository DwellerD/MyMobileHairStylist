begin;

drop policy if exists "appointments are updatable by owner customer assigned stylist and scoped admins"
on public.appointments;

create policy "appointments are updatable by assigned stylist and scoped admins"
on public.appointments
for update
to authenticated
using (
  public.is_assigned_stylist_for_appointment(id)
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  public.is_assigned_stylist_for_appointment(id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

-- TODO: If customer-driven reschedule or cancellation flows are added later,
-- use dedicated RPCs or tightly scoped policies instead of restoring broad
-- customer update rights on the appointments table.

commit;