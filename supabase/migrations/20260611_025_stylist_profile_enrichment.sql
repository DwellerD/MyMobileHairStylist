begin;

alter table public.stylist_profiles
add column if not exists years_experience integer
  check (years_experience is null or years_experience >= 0);

comment on column public.stylist_profiles.years_experience is
  'Optional stylist years of experience shown in customer-facing profile cards.';

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
  public_bio text;
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

  public_bio := left(trim(coalesce(application_row.motivation, '')), 300);
  if public_bio = '' then
    public_bio := null;
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
    bio,
    specialties,
    years_experience,
    is_accepting_bookings
  )
  values (
    application_row.user_profile_id,
    application_row.market_id,
    resolved_territory_id,
    'active',
    public_bio,
    application_row.specialties,
    application_row.years_experience,
    true
  )
  on conflict (user_profile_id)
  do update set
    market_id = excluded.market_id,
    territory_id = excluded.territory_id,
    status = 'active',
    bio = excluded.bio,
    specialties = excluded.specialties,
    years_experience = excluded.years_experience,
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

commit;
