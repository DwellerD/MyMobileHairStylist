begin;

create or replace function public.provision_customer_household(
  target_user_profile_id uuid,
  target_market_id uuid,
  target_territory_id uuid default null,
  requested_household_name text default null
)
returns table (household_id uuid, household_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_household_id uuid;
  existing_household_name text;
  resolved_household_name text;
begin
  if not exists (
    select 1
    from public.user_profiles up
    where up.id = target_user_profile_id
      and up.auth_user_id = auth.uid()
  ) and not public.has_scoped_admin_access(target_market_id, target_territory_id) then
    raise exception 'You are not allowed to provision this household.';
  end if;

  select h.id, h.name
  into existing_household_id, existing_household_name
  from public.households h
  where h.created_by_user_profile_id = target_user_profile_id
  order by h.created_at
  limit 1;

  if existing_household_id is not null then
    return query select existing_household_id, existing_household_name;
    return;
  end if;

  if requested_household_name is not null and btrim(requested_household_name) <> '' then
    resolved_household_name := btrim(requested_household_name);
  else
    select case
      when btrim(concat_ws(' ', up.first_name, up.last_name)) <> ''
        then btrim(concat_ws(' ', up.first_name, up.last_name)) || ' Household'
      else split_part(up.email, '@', 1) || ' Household'
    end
    into resolved_household_name
    from public.user_profiles up
    where up.id = target_user_profile_id;
  end if;

  insert into public.households (
    market_id,
    territory_id,
    created_by_user_profile_id,
    name,
    status
  )
  values (
    target_market_id,
    target_territory_id,
    target_user_profile_id,
    resolved_household_name,
    'active'
  )
  returning id, name into existing_household_id, existing_household_name;

  return query select existing_household_id, existing_household_name;
end;
$$;

comment on function public.provision_customer_household(uuid, uuid, uuid, text) is 'Creates or returns the default household for a customer profile without relying on client-side household inserts.';

grant execute on function public.provision_customer_household(uuid, uuid, uuid, text)
to authenticated;

create or replace function public.bootstrap_customer_household()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_household_name text;
begin
  if exists (
    select 1
    from public.households h
    where h.created_by_user_profile_id = new.user_profile_id
  ) then
    return new;
  end if;

  select case
    when btrim(concat_ws(' ', up.first_name, up.last_name)) <> ''
      then btrim(concat_ws(' ', up.first_name, up.last_name)) || ' Household'
    else split_part(up.email, '@', 1) || ' Household'
  end
  into resolved_household_name
  from public.user_profiles up
  where up.id = new.user_profile_id;

  insert into public.households (
    market_id,
    territory_id,
    created_by_user_profile_id,
    name,
    status
  )
  values (
    new.market_id,
    new.territory_id,
    new.user_profile_id,
    resolved_household_name,
    'active'
  );

  return new;
end;
$$;

comment on function public.bootstrap_customer_household() is 'Backstops new customer profiles with a default household row for booking and family flows.';

drop trigger if exists on_customer_profile_created_create_household
on public.customer_profiles;

create trigger on_customer_profile_created_create_household
after insert on public.customer_profiles
for each row
execute function public.bootstrap_customer_household();

insert into public.households (
  market_id,
  territory_id,
  created_by_user_profile_id,
  name,
  status
)
select
  cp.market_id,
  cp.territory_id,
  cp.user_profile_id,
  case
    when btrim(concat_ws(' ', up.first_name, up.last_name)) <> ''
      then btrim(concat_ws(' ', up.first_name, up.last_name)) || ' Household'
    else split_part(up.email, '@', 1) || ' Household'
  end,
  'active'
from public.customer_profiles cp
join public.user_profiles up on up.id = cp.user_profile_id
where not exists (
  select 1
  from public.households h
  where h.created_by_user_profile_id = cp.user_profile_id
);

commit;