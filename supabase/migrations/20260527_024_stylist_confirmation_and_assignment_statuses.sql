begin;

alter type public.appointment_status add value if not exists 'pending_assignment';
alter type public.appointment_status add value if not exists 'pending_stylist_confirmation';
alter type public.appointment_status add value if not exists 'declined_by_stylist';

create or replace function public.assign_appointment_stylist(
  p_appointment_id uuid,
  p_stylist_profile_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_row public.appointments%rowtype;
  stylist_row public.stylist_profiles%rowtype;
  resolved_status public.appointment_status;
begin
  select *
  into appointment_row
  from public.appointments
  where id = p_appointment_id
  for update;

  if not found then
    raise exception 'Appointment not found.';
  end if;

  if not public.has_scoped_admin_access(appointment_row.market_id, appointment_row.territory_id) then
    raise exception 'You do not have access to assign this appointment.';
  end if;

  if appointment_row.status in ('completed', 'cancelled') then
    raise exception 'This appointment can no longer be assigned.';
  end if;

  select *
  into stylist_row
  from public.stylist_profiles
  where id = p_stylist_profile_id;

  if not found then
    raise exception 'Stylist profile not found.';
  end if;

  if stylist_row.status <> 'active' or stylist_row.is_accepting_bookings is not true then
    raise exception 'The selected stylist is not currently accepting appointments.';
  end if;

  if stylist_row.market_id is distinct from appointment_row.market_id then
    raise exception 'The selected stylist is outside this appointment market.';
  end if;

  if appointment_row.territory_id is not null
     and stylist_row.territory_id is not null
     and appointment_row.territory_id is distinct from stylist_row.territory_id then
    raise exception 'The selected stylist is outside this appointment territory.';
  end if;

  resolved_status := 'pending_stylist_confirmation'::public.appointment_status;

  update public.appointments
  set
    assigned_stylist_profile_id = p_stylist_profile_id,
    status = resolved_status
  where id = p_appointment_id;

  perform public.log_appointment_dispatch_event(
    p_appointment_id,
    case
      when appointment_row.assigned_stylist_profile_id is null then 'stylist_assigned'
      else 'stylist_reassigned'
    end,
    appointment_row.status,
    resolved_status::text,
    appointment_row.assigned_stylist_profile_id,
    p_stylist_profile_id,
    p_notes
  );
end;
$$;

comment on function public.assign_appointment_stylist(uuid, uuid, text) is
  'Admin-scoped stylist assignment with scope checks. Assigned appointments require stylist confirmation.';

create or replace function public.stylist_respond_to_assigned_appointment(
  p_appointment_id uuid,
  p_response text,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_row public.appointments%rowtype;
  stylist_profile_id uuid;
  normalized_response text;
  previous_status text;
begin
  normalized_response := lower(trim(p_response));
  if normalized_response not in ('accept', 'decline') then
    raise exception 'Invalid response. Use accept or decline.';
  end if;

  stylist_profile_id := public.current_stylist_profile_id();
  if stylist_profile_id is null then
    raise exception 'No active stylist profile is linked to this account.';
  end if;

  select *
  into appointment_row
  from public.appointments
  where id = p_appointment_id
  for update;

  if not found then
    raise exception 'Appointment not found.';
  end if;

  if appointment_row.assigned_stylist_profile_id is distinct from stylist_profile_id then
    raise exception 'This appointment is not assigned to your profile.';
  end if;

  if normalized_response = 'accept' then
    if appointment_row.status not in ('pending_stylist_confirmation', 'assigned') then
      raise exception 'This appointment is not waiting for stylist confirmation.';
    end if;

    previous_status := appointment_row.status;

    update public.appointments
    set status = 'confirmed'
    where id = p_appointment_id;

    perform public.log_appointment_dispatch_event(
      p_appointment_id,
      'status_changed',
      previous_status,
      'confirmed',
      stylist_profile_id,
      stylist_profile_id,
      p_notes
    );

    return;
  end if;

  if appointment_row.status not in ('pending_stylist_confirmation', 'assigned') then
    raise exception 'This appointment is not waiting for stylist confirmation.';
  end if;

  previous_status := appointment_row.status;

  update public.appointments
  set
    assigned_stylist_profile_id = null,
    status = 'pending_assignment'
  where id = p_appointment_id;

  perform public.log_appointment_dispatch_event(
    p_appointment_id,
    'status_changed',
    previous_status,
    'pending_assignment',
    stylist_profile_id,
    null,
    coalesce(nullif(trim(p_notes), ''), 'Declined by stylist.')
  );
end;
$$;

comment on function public.stylist_respond_to_assigned_appointment(uuid, text, text) is
  'Stylist accepts or declines an assigned appointment. Declines clear assignment and return to pending_assignment.';

grant execute on function public.assign_appointment_stylist(uuid, uuid, text) to authenticated;
grant execute on function public.stylist_respond_to_assigned_appointment(uuid, text, text) to authenticated;

commit;
