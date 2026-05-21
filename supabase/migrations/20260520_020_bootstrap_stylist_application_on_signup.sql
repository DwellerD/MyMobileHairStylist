begin;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_market_id uuid;
  resolved_territory_id uuid;
  new_user_profile_id uuid;
  stylist_specialties text[];
  wants_stylist_application boolean;
begin
  resolved_market_id := nullif(new.raw_user_meta_data ->> 'default_market_id', '')::uuid;
  resolved_territory_id := nullif(new.raw_user_meta_data ->> 'default_territory_id', '')::uuid;
  wants_stylist_application := coalesce(
    nullif(new.raw_user_meta_data ->> 'pending_stylist_application', '')::boolean,
    false
  );

  if resolved_market_id is null then
    select m.id
    into resolved_market_id
    from public.markets m
    where m.status in ('active', 'launching')
    order by case when m.status = 'active' then 0 else 1 end, m.created_at
    limit 1;
  end if;

  if resolved_market_id is null then
    raise exception 'No market is available for new signups. Seed at least one market before customer registration.';
  end if;

  insert into public.user_profiles (
    auth_user_id,
    email,
    first_name,
    last_name,
    default_market_id,
    default_territory_id,
    status
  )
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', ''),
    resolved_market_id,
    resolved_territory_id,
    'active'
  )
  returning id into new_user_profile_id;

  insert into public.user_roles (
    user_profile_id,
    role,
    market_id,
    status,
    is_primary
  )
  values (
    new_user_profile_id,
    'customer',
    resolved_market_id,
    'active',
    true
  );

  insert into public.customer_profiles (
    user_profile_id,
    market_id,
    territory_id,
    status
  )
  values (
    new_user_profile_id,
    resolved_market_id,
    resolved_territory_id,
    'active'
  );

  if wants_stylist_application then
    select coalesce(array_agg(value), '{}'::text[])
    into stylist_specialties
    from jsonb_array_elements_text(
      coalesce(new.raw_user_meta_data -> 'stylist_specialties', '[]'::jsonb)
    ) as value;

    insert into public.stylist_applications (
      user_profile_id,
      market_id,
      territory_id,
      phone,
      city,
      state,
      license_number,
      years_experience,
      specialties,
      portfolio_url,
      motivation,
      status
    )
    values (
      new_user_profile_id,
      resolved_market_id,
      resolved_territory_id,
      nullif(new.raw_user_meta_data ->> 'stylist_phone', ''),
      nullif(new.raw_user_meta_data ->> 'stylist_city', ''),
      nullif(new.raw_user_meta_data ->> 'stylist_state', ''),
      nullif(new.raw_user_meta_data ->> 'stylist_license_number', ''),
      nullif(new.raw_user_meta_data ->> 'stylist_years_experience', '')::integer,
      stylist_specialties,
      nullif(new.raw_user_meta_data ->> 'stylist_portfolio_url', ''),
      coalesce(
        nullif(new.raw_user_meta_data ->> 'stylist_motivation', ''),
        'Stylist application submitted during signup.'
      ),
      'pending'
    )
    on conflict (user_profile_id) do nothing;
  end if;

  return new;
end;
$$;

comment on function public.handle_new_auth_user() is 'Automatically provisions app profile rows for new auth users and optionally creates a pending stylist application from signup metadata.';

commit;