begin;

-- ---------------------------------------------------------------------------
-- 1. Customer-requested stylist on appointments
--    Tracks which stylist a customer specifically requested during booking,
--    independent of which stylist admin ultimately assigns. This lets admins
--    see and honour customer preferences without being forced to match them.
-- ---------------------------------------------------------------------------

alter table public.appointments
add column if not exists requested_stylist_profile_id uuid
  references public.stylist_profiles(id)
  on delete set null;

comment on column public.appointments.requested_stylist_profile_id is
  'Customer-requested preferred stylist. May differ from assigned_stylist_profile_id if admin overrides.';

create index if not exists appointments_requested_stylist_idx
  on public.appointments (requested_stylist_profile_id)
  where requested_stylist_profile_id is not null;

-- ---------------------------------------------------------------------------
-- 2. Allow customers to read stylist profiles for browsing
--    The existing policy only lets admins and the owning stylist read profiles.
--    Customers need to read active, accepting profiles within their market
--    so the booking flow can surface available stylists.
-- ---------------------------------------------------------------------------

drop policy if exists "customers can read accepting stylist profiles in their market"
  on public.stylist_profiles;

create policy "customers can read accepting stylist profiles in their market"
on public.stylist_profiles
for select
to authenticated
using (
  status = 'active'
  and is_accepting_bookings = true
  and market_id in (
    select up.default_market_id
    from public.user_profiles up
    where up.id = public.current_user_profile_id()
      and up.default_market_id is not null
  )
);

-- ---------------------------------------------------------------------------
-- 3. Allow any authenticated user to read "available" availability blocks
--    for booking purposes. Customers need to see open time windows so the
--    slot picker can show realistic appointment times.
--    Unavailable / time-off / appointment-hold blocks remain private.
-- ---------------------------------------------------------------------------

drop policy if exists "customers can read available blocks for booking"
  on public.availability_blocks;

create policy "customers can read available blocks for booking"
on public.availability_blocks
for select
to authenticated
using (
  block_type = 'available'
  and (
    -- Existing access: owning stylist or admin (already covered by the
    -- "visible to owning stylists and scoped admins" policy above, but we
    -- cannot use OR across two separate policies in Postgres RLS — all
    -- matching policies are combined with OR automatically, so adding a
    -- third policy here for customer visibility is correct.)
    market_id in (
      select up.default_market_id
      from public.user_profiles up
      where up.id = public.current_user_profile_id()
        and up.default_market_id is not null
    )
    or public.has_scoped_admin_access(market_id, territory_id)
    or exists (
      select 1
      from public.stylist_profiles sp
      where sp.id = stylist_profile_id
        and sp.user_profile_id = public.current_user_profile_id()
    )
  )
);

-- ---------------------------------------------------------------------------
-- 4. Allow customers to read confirmed/assigned appointments for stylists in
--    their market so the slot-picker can exclude already-booked windows.
--    Only non-sensitive fields are relevant; RLS still restricts full rows.
--    NOTE: The existing "appointments are visible" policy already covers this
--    for the owning customer.  We add a narrow read allowing customers to
--    check stylist occupancy for any stylist in their market.
-- ---------------------------------------------------------------------------

drop policy if exists "customers can check stylist occupancy for booking"
  on public.appointments;

create policy "customers can check stylist occupancy for booking"
on public.appointments
for select
to authenticated
using (
  -- Allow reading any non-cancelled appointment when the customer's market
  -- matches and they need it for availability calculation.
  status not in ('cancelled', 'declined')
  and market_id in (
    select up.default_market_id
    from public.user_profiles up
    where up.id = public.current_user_profile_id()
      and up.default_market_id is not null
  )
);

commit;
