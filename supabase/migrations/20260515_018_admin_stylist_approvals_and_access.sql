begin;

drop policy if exists "admins manage user roles" on public.user_roles;

create policy "admins manage non-admin roles and corporate admins manage all roles"
on public.user_roles
for all
to authenticated
using (
  public.is_corporate_admin()
  or (
    role not in ('admin', 'corporate_admin', 'franchisee')
    and public.has_scoped_admin_access(market_id, territory_id)
  )
)
with check (
  public.is_corporate_admin()
  or (
    role not in ('admin', 'corporate_admin', 'franchisee')
    and public.has_scoped_admin_access(market_id, territory_id)
  )
);

create or replace function public.approve_stylist_application(
  p_application_id uuid,
  p_territory_id uuid default null,
  p_reviewer_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  application_row public.stylist_applications%rowtype;
  resolved_territory_id uuid;
  stylist_profile_id uuid;
begin
  select *
  into application_row
  from public.stylist_applications
  where id = p_application_id;

  if not found then
    raise exception 'Stylist application not found.';
  end if;

  resolved_territory_id := coalesce(p_territory_id, application_row.territory_id);

  if not public.has_scoped_admin_access(application_row.market_id, resolved_territory_id) then
    raise exception 'You do not have access to approve this stylist application.';
  end if;

  if application_row.status <> 'pending' then
    raise exception 'Only pending stylist applications can be approved.';
  end if;

  update public.user_roles
  set is_primary = false
  where user_profile_id = application_row.user_profile_id
    and status = 'active'
    and is_primary = true;

  insert into public.user_roles (
    user_profile_id,
    role,
    market_id,
    territory_id,
    status,
    is_primary
  )
  values (
    application_row.user_profile_id,
    'stylist',
    application_row.market_id,
    resolved_territory_id,
    'active',
    true
  );

  insert into public.stylist_profiles (
    user_profile_id,
    market_id,
    territory_id,
    status,
    specialties,
    is_accepting_bookings
  )
  values (
    application_row.user_profile_id,
    application_row.market_id,
    resolved_territory_id,
    'active',
    application_row.specialties,
    true
  )
  on conflict (user_profile_id)
  do update set
    market_id = excluded.market_id,
    territory_id = excluded.territory_id,
    status = 'active',
    specialties = excluded.specialties,
    is_accepting_bookings = true,
    updated_at = timezone('utc', now())
  returning id into stylist_profile_id;

  update public.user_profiles
  set
    default_market_id = application_row.market_id,
    default_territory_id = resolved_territory_id
  where id = application_row.user_profile_id;

  update public.stylist_applications
  set
    status = 'approved',
    territory_id = resolved_territory_id,
    reviewer_notes = nullif(trim(p_reviewer_notes), ''),
    reviewed_by_user_profile_id = public.current_user_profile_id(),
    reviewed_at = timezone('utc', now()),
    approved_stylist_profile_id = stylist_profile_id
  where id = p_application_id;

  return stylist_profile_id;
end;
$$;

create or replace function public.reject_stylist_application(
  p_application_id uuid,
  p_reviewer_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  application_row public.stylist_applications%rowtype;
begin
  select *
  into application_row
  from public.stylist_applications
  where id = p_application_id;

  if not found then
    raise exception 'Stylist application not found.';
  end if;

  if not public.has_scoped_admin_access(application_row.market_id, application_row.territory_id) then
    raise exception 'You do not have access to reject this stylist application.';
  end if;

  if application_row.status <> 'pending' then
    raise exception 'Only pending stylist applications can be rejected.';
  end if;

  update public.stylist_applications
  set
    status = 'rejected',
    reviewer_notes = nullif(trim(p_reviewer_notes), ''),
    reviewed_by_user_profile_id = public.current_user_profile_id(),
    reviewed_at = timezone('utc', now())
  where id = p_application_id;
end;
$$;

create or replace function public.grant_admin_access(
  p_target_user_profile_id uuid,
  p_role public.app_role,
  p_market_id uuid default null,
  p_territory_id uuid default null,
  p_make_primary boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_role_id uuid;
begin
  if not public.is_corporate_admin() then
    raise exception 'Only corporate admins can grant admin access.';
  end if;

  if p_role not in ('admin', 'corporate_admin') then
    raise exception 'Unsupported admin role.';
  end if;

  if p_role = 'admin' and p_market_id is null then
    raise exception 'Scoped admin access requires a market.';
  end if;

  if p_role = 'corporate_admin' and (p_market_id is not null or p_territory_id is not null) then
    raise exception 'Corporate admin access cannot be scoped to a market or territory.';
  end if;

  if p_make_primary then
    update public.user_roles
    set is_primary = false
    where user_profile_id = p_target_user_profile_id
      and status = 'active'
      and is_primary = true;
  end if;

  select ur.id
  into existing_role_id
  from public.user_roles ur
  where ur.user_profile_id = p_target_user_profile_id
    and ur.role = p_role
    and ur.market_id is not distinct from p_market_id
    and ur.territory_id is not distinct from p_territory_id
  order by ur.created_at desc
  limit 1;

  if existing_role_id is null then
    insert into public.user_roles (
      user_profile_id,
      role,
      market_id,
      territory_id,
      status,
      is_primary
    )
    values (
      p_target_user_profile_id,
      p_role,
      p_market_id,
      p_territory_id,
      'active',
      p_make_primary
    )
    returning id into existing_role_id;
  else
    update public.user_roles
    set
      status = 'active',
      is_primary = p_make_primary,
      updated_at = timezone('utc', now())
    where id = existing_role_id;
  end if;

  if p_make_primary then
    update public.user_profiles
    set
      default_market_id = p_market_id,
      default_territory_id = p_territory_id
    where id = p_target_user_profile_id;
  end if;

  return existing_role_id;
end;
$$;

commit;