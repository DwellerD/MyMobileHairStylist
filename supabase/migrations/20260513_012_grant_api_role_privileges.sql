begin;

grant usage on schema public to anon, authenticated;

grant select on public.markets to anon;

grant select on public.markets,
public.territories,
public.user_profiles,
public.user_roles,
public.customer_profiles,
public.stylist_profiles,
public.households,
public.household_members,
public.addresses,
public.service_categories,
public.services,
public.service_addons,
public.appointments,
public.appointment_participants,
public.appointment_services,
public.appointment_photos,
public.internal_notes,
public.check_ins,
public.safety_events,
public.availability_blocks,
public.policy_acceptances,
public.payments_placeholder,
public.reviews_placeholder
to authenticated;

grant insert on public.user_profiles,
public.user_roles,
public.customer_profiles,
public.stylist_profiles,
public.households,
public.household_members,
public.addresses,
public.appointments,
public.appointment_participants,
public.appointment_services,
public.appointment_photos,
public.internal_notes,
public.check_ins,
public.safety_events,
public.availability_blocks,
public.policy_acceptances,
public.payments_placeholder,
public.reviews_placeholder
to authenticated;

grant update on public.user_profiles,
public.user_roles,
public.customer_profiles,
public.stylist_profiles,
public.households,
public.household_members,
public.addresses,
public.service_categories,
public.services,
public.service_addons,
public.appointments,
public.appointment_participants,
public.appointment_services,
public.appointment_photos,
public.internal_notes,
public.check_ins,
public.safety_events,
public.availability_blocks,
public.reviews_placeholder,
public.payments_placeholder
to authenticated;

grant delete on public.households,
public.household_members,
public.addresses,
public.appointments,
public.appointment_participants,
public.appointment_services,
public.appointment_photos,
public.internal_notes,
public.check_ins,
public.safety_events,
public.availability_blocks,
public.reviews_placeholder,
public.payments_placeholder
to authenticated;

grant execute on function public.current_user_profile_id() to authenticated;
grant execute on function public.is_corporate_admin() to authenticated;
grant execute on function public.has_scoped_admin_access(uuid, uuid) to authenticated;
grant execute on function public.owns_customer_profile(uuid) to authenticated;
grant execute on function public.owns_household(uuid) to authenticated;
grant execute on function public.is_assigned_stylist_for_appointment(uuid) to authenticated;
grant execute on function public.can_access_appointment(uuid) to authenticated;
grant execute on function public.can_access_household(uuid) to authenticated;
grant execute on function public.can_manage_appointment_operational_data(uuid) to authenticated;

grant execute on function public.current_user_profile_id() to anon;
grant execute on function public.is_corporate_admin() to anon;
grant execute on function public.has_scoped_admin_access(uuid, uuid) to anon;
grant execute on function public.owns_customer_profile(uuid) to anon;
grant execute on function public.owns_household(uuid) to anon;
grant execute on function public.is_assigned_stylist_for_appointment(uuid) to anon;
grant execute on function public.can_access_appointment(uuid) to anon;
grant execute on function public.can_access_household(uuid) to anon;

commit;