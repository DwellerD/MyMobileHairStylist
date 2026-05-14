begin;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_market_id uuid;
  new_user_profile_id uuid;
begin
  resolved_market_id := nullif(new.raw_user_meta_data ->> 'default_market_id', '')::uuid;

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
    status
  )
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', ''),
    resolved_market_id,
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
    status
  )
  values (
    new_user_profile_id,
    resolved_market_id,
    'active'
  );

  return new;
end;
$$;

comment on function public.handle_new_auth_user() is 'Automatically provisions app profile and default customer role rows for new auth users.';

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

commit;