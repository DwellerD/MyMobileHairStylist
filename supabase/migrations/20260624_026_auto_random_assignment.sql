begin;

create or replace function public.try_auto_assign_appointment(
  p_appointment_id uuid,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_row public.appointments%rowtype;
  requested_window_start timestamptz;
  requested_window_end timestamptz;
  chosen_stylist_id uuid;
  previous_status text;
begin
  select *
  into appointment_row
  from public.appointments
  where id = p_appointment_id
  for update;

  if not found then
    return null;
  end if;

  if appointment_row.status in ('completed', 'cancelled') then
    return null;
  end if;

  if appointment_row.assigned_stylist_profile_id is not null then
    return appointment_row.assigned_stylist_profile_id;
  end if;

  requested_window_start := coalesce(
    appointment_row.scheduled_start_at,
    appointment_row.requested_start_at
  );

  requested_window_end := coalesce(
    appointment_row.scheduled_end_at,
    appointment_row.requested_end_at,
    requested_window_start + make_interval(mins => coalesce(appointment_row.estimated_duration_minutes, 60))
  );

  if requested_window_end <= requested_window_start then
    return null;
  end if;

  if coalesce(appointment_row.stylist_preference_type, 'any') = 'specific'
     and appointment_row.requested_stylist_profile_id is not null then
    select sp.id
    into chosen_stylist_id
    from public.stylist_profiles sp
    where sp.id = appointment_row.requested_stylist_profile_id
      and sp.status = 'active'
      and sp.is_accepting_bookings = true
      and sp.market_id = appointment_row.market_id
      and (
        appointment_row.territory_id is null
        or sp.territory_id is null
        or sp.territory_id = appointment_row.territory_id
      )
      and exists (
        select 1
        from public.availability_blocks ab
        where ab.stylist_profile_id = sp.id
          and ab.block_type = 'available'
          and ab.start_at <= requested_window_start
          and ab.end_at >= requested_window_end
      )
      and not exists (
        select 1
        from public.appointments conflict
        where conflict.assigned_stylist_profile_id = sp.id
          and conflict.id <> appointment_row.id
          and conflict.status not in ('cancelled', 'declined', 'declined_by_stylist', 'pending_assignment')
          and coalesce(
                conflict.scheduled_end_at,
                conflict.requested_end_at,
                coalesce(conflict.scheduled_start_at, conflict.requested_start_at)
                  + make_interval(mins => coalesce(conflict.estimated_duration_minutes, 60))
              ) > requested_window_start
          and coalesce(conflict.scheduled_start_at, conflict.requested_start_at) < requested_window_end
      )
    limit 1;
  else
    select candidate.id
    into chosen_stylist_id
    from (
      select sp.id
      from public.stylist_profiles sp
      where sp.status = 'active'
        and sp.is_accepting_bookings = true
        and sp.market_id = appointment_row.market_id
        and (
          appointment_row.territory_id is null
          or sp.territory_id is null
          or sp.territory_id = appointment_row.territory_id
        )
        and exists (
          select 1
          from public.availability_blocks ab
          where ab.stylist_profile_id = sp.id
            and ab.block_type = 'available'
            and ab.start_at <= requested_window_start
            and ab.end_at >= requested_window_end
        )
        and not exists (
          select 1
          from public.appointments conflict
          where conflict.assigned_stylist_profile_id = sp.id
            and conflict.id <> appointment_row.id
            and conflict.status not in ('cancelled', 'declined', 'declined_by_stylist', 'pending_assignment')
            and coalesce(
                  conflict.scheduled_end_at,
                  conflict.requested_end_at,
                  coalesce(conflict.scheduled_start_at, conflict.requested_start_at)
                    + make_interval(mins => coalesce(conflict.estimated_duration_minutes, 60))
                ) > requested_window_start
            and coalesce(conflict.scheduled_start_at, conflict.requested_start_at) < requested_window_end
        )
        and not exists (
          select 1
          from public.appointment_dispatch_events ade
          where ade.appointment_id = appointment_row.id
            and ade.previous_stylist_profile_id = sp.id
            and ade.next_status = 'pending_assignment'
        )
      order by random()
      limit 1
    ) candidate;
  end if;

  if chosen_stylist_id is null then
    return null;
  end if;

  previous_status := appointment_row.status;

  update public.appointments
  set
    assigned_stylist_profile_id = chosen_stylist_id,
    status = 'pending_stylist_confirmation'
  where id = appointment_row.id;

  perform public.log_appointment_dispatch_event(
    appointment_row.id,
    case
      when appointment_row.assigned_stylist_profile_id is null then 'stylist_assigned'
      else 'stylist_reassigned'
    end,
    previous_status,
    'pending_stylist_confirmation',
    appointment_row.assigned_stylist_profile_id,
    chosen_stylist_id,
    coalesce(
      nullif(trim(p_notes), ''),
      'Auto-assigned to an available stylist.'
    )
  );

  return chosen_stylist_id;
end;
$$;

comment on function public.try_auto_assign_appointment(uuid, text) is
  'Attempts to auto-assign an appointment to an eligible stylist. For specific preference, assigns only requested stylist when available. For any preference, assigns a random eligible stylist and avoids previously declined stylists for that appointment.';

create or replace function public.auto_assign_new_pending_appointment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'pending_assignment' and new.assigned_stylist_profile_id is null then
    perform public.try_auto_assign_appointment(
      new.id,
      'Auto-assigned on booking creation.'
    );
  end if;

  return new;
end;
$$;

comment on function public.auto_assign_new_pending_appointment() is
  'Trigger helper that auto-assigns newly created pending_assignment appointments when an eligible stylist exists.';

drop trigger if exists appointments_auto_assign_on_insert
  on public.appointments;

create trigger appointments_auto_assign_on_insert
after insert on public.appointments
for each row
execute function public.auto_assign_new_pending_appointment();

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

  perform public.try_auto_assign_appointment(
    p_appointment_id,
    'Auto-reassigned after stylist decline.'
  );
end;
$$;

comment on function public.stylist_respond_to_assigned_appointment(uuid, text, text) is
  'Stylist accepts or declines an assigned appointment. Declines clear assignment, return to pending_assignment, then auto-attempt reassignment.';

grant execute on function public.try_auto_assign_appointment(uuid, text) to authenticated;

grant execute on function public.auto_assign_new_pending_appointment() to authenticated;

grant execute on function public.stylist_respond_to_assigned_appointment(uuid, text, text) to authenticated;

commit;
