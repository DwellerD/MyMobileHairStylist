begin;

create table if not exists public.appointment_dispatch_events (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  market_id uuid references public.markets(id) on delete set null,
  territory_id uuid references public.territories(id) on delete set null,
  actor_user_profile_id uuid references public.user_profiles(id) on delete set null,
  event_type text not null check (
    event_type in (
      'status_changed',
      'stylist_assigned',
      'stylist_reassigned',
      'stylist_claimed'
    )
  ),
  previous_status text,
  next_status text,
  previous_stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  next_stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.appointment_dispatch_events is
  'Audit history for appointment dispatch and lifecycle changes.';

create index if not exists appointment_dispatch_events_appointment_idx
  on public.appointment_dispatch_events (appointment_id, created_at desc);

alter table public.appointment_dispatch_events enable row level security;

drop policy if exists "dispatch events are visible to scoped admins and assigned stylists"
  on public.appointment_dispatch_events;

create policy "dispatch events are visible to scoped admins and assigned stylists"
on public.appointment_dispatch_events
for select
to authenticated
using (
  public.has_scoped_admin_access(market_id, territory_id)
  or public.is_assigned_stylist_for_appointment(appointment_id)
);

grant select on public.appointment_dispatch_events to authenticated;

create or replace function public.current_stylist_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select sp.id
  from public.stylist_profiles sp
  where sp.user_profile_id = public.current_user_profile_id()
    and sp.status = 'active'
  order by sp.updated_at desc
  limit 1;
$$;

comment on function public.current_stylist_profile_id() is
  'Resolves the current authenticated app user into the active stylist_profiles id when available.';

create or replace function public.can_claim_local_appointment(target_appointment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.appointments a
    join public.stylist_profiles sp on sp.id = public.current_stylist_profile_id()
    where a.id = target_appointment_id
      and a.assigned_stylist_profile_id is null
      and a.status in ('requested', 'approved')
      and sp.status = 'active'
      and sp.is_accepting_bookings = true
      and a.market_id = sp.market_id
      and (
        a.territory_id is null
        or sp.territory_id is null
        or a.territory_id = sp.territory_id
      )
      and (
        a.requested_stylist_profile_id is null
        or a.requested_stylist_profile_id = sp.id
      )
  );
$$;

comment on function public.can_claim_local_appointment(uuid) is
  'Checks whether the current stylist may claim an unassigned local appointment request.';

grant execute on function public.current_stylist_profile_id() to authenticated;
grant execute on function public.can_claim_local_appointment(uuid) to authenticated;

drop policy if exists "stylists can read claimable local appointments"
  on public.appointments;

create policy "stylists can read claimable local appointments"
on public.appointments
for select
to authenticated
using (public.can_claim_local_appointment(id));

create or replace function public.log_appointment_dispatch_event(
  p_appointment_id uuid,
  p_event_type text,
  p_previous_status text default null,
  p_next_status text default null,
  p_previous_stylist_profile_id uuid default null,
  p_next_stylist_profile_id uuid default null,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_scope record;
begin
  select market_id, territory_id
  into appointment_scope
  from public.appointments
  where id = p_appointment_id;

  insert into public.appointment_dispatch_events (
    appointment_id,
    market_id,
    territory_id,
    actor_user_profile_id,
    event_type,
    previous_status,
    next_status,
    previous_stylist_profile_id,
    next_stylist_profile_id,
    notes
  )
  values (
    p_appointment_id,
    appointment_scope.market_id,
    appointment_scope.territory_id,
    public.current_user_profile_id(),
    p_event_type,
    p_previous_status,
    p_next_status,
    p_previous_stylist_profile_id,
    p_next_stylist_profile_id,
    nullif(trim(p_notes), '')
  );
end;
$$;

create or replace function public.update_appointment_status_admin(
  p_appointment_id uuid,
  p_status public.appointment_status,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_row public.appointments%rowtype;
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
    raise exception 'You do not have access to update this appointment.';
  end if;

  if appointment_row.status = p_status::text then
    return;
  end if;

  update public.appointments
  set status = p_status
  where id = p_appointment_id;

  perform public.log_appointment_dispatch_event(
    p_appointment_id,
    'status_changed',
    appointment_row.status,
    p_status::text,
    appointment_row.assigned_stylist_profile_id,
    appointment_row.assigned_stylist_profile_id,
    p_notes
  );
end;
$$;

comment on function public.update_appointment_status_admin(uuid, public.appointment_status, text) is
  'Admin-scoped appointment status mutation with audit logging.';

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

  select *
  into stylist_row
  from public.stylist_profiles
  where id = p_stylist_profile_id;

  if not found then
    raise exception 'Stylist profile not found.';
  end if;

  if stylist_row.market_id is distinct from appointment_row.market_id then
    raise exception 'The selected stylist is outside this appointment market.';
  end if;

  if appointment_row.territory_id is not null
     and stylist_row.territory_id is not null
     and appointment_row.territory_id is distinct from stylist_row.territory_id then
    raise exception 'The selected stylist is outside this appointment territory.';
  end if;

  resolved_status := case
    when appointment_row.status in ('requested', 'approved') then 'assigned'::public.appointment_status
    else appointment_row.status
  end;

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
  'Admin-scoped stylist assignment with scope checks and audit logging.';

create or replace function public.claim_appointment_request(
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
  stylist_profile_id uuid;
  resolved_status public.appointment_status;
begin
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

  if not public.can_claim_local_appointment(p_appointment_id) then
    raise exception 'This appointment is not available for your local queue.';
  end if;

  resolved_status := case
    when appointment_row.status in ('requested', 'approved') then 'assigned'::public.appointment_status
    else appointment_row.status
  end;

  update public.appointments
  set
    assigned_stylist_profile_id = stylist_profile_id,
    status = resolved_status
  where id = p_appointment_id;

  perform public.log_appointment_dispatch_event(
    p_appointment_id,
    'stylist_claimed',
    appointment_row.status,
    resolved_status::text,
    appointment_row.assigned_stylist_profile_id,
    stylist_profile_id,
    p_notes
  );

  return stylist_profile_id;
end;
$$;

comment on function public.claim_appointment_request(uuid, text) is
  'Lets an eligible stylist claim an unassigned local appointment request.';

grant execute on function public.update_appointment_status_admin(uuid, public.appointment_status, text) to authenticated;
grant execute on function public.assign_appointment_stylist(uuid, uuid, text) to authenticated;
grant execute on function public.claim_appointment_request(uuid, text) to authenticated;

commit;