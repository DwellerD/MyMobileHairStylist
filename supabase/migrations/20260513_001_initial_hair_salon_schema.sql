begin;

create extension if not exists pgcrypto;
create extension if not exists citext;

create type public.app_role as enum (
  'customer',
  'stylist',
  'admin',
  'franchisee',
  'corporate_admin'
);

create type public.market_status as enum (
  'launching',
  'active',
  'inactive'
);

create type public.territory_status as enum (
  'planned',
  'active',
  'inactive'
);

create type public.profile_status as enum (
  'invited',
  'active',
  'inactive'
);

create type public.household_status as enum (
  'active',
  'inactive'
);

create type public.address_status as enum (
  'pending_review',
  'serviceable',
  'out_of_area',
  'inactive'
);

create type public.service_status as enum (
  'draft',
  'active',
  'inactive'
);

create type public.appointment_status as enum (
  'requested',
  'approved',
  'declined',
  'assigned',
  'in_progress',
  'completed',
  'cancelled',
  'reschedule_requested'
);

create type public.participant_status as enum (
  'planned',
  'confirmed',
  'cancelled'
);

create type public.relationship_type as enum (
  'self',
  'spouse_partner',
  'child',
  'other'
);

create type public.photo_type as enum (
  'reference',
  'before',
  'after',
  'other'
);

create type public.note_type as enum (
  'booking',
  'service',
  'safety',
  'admin'
);

create type public.check_in_status as enum (
  'not_started',
  'checked_in',
  'checked_out'
);

create type public.safety_event_type as enum (
  'check_in_missed',
  'check_out_missed',
  'incident',
  'sos_placeholder',
  'general'
);

create type public.safety_event_status as enum (
  'open',
  'reviewing',
  'resolved',
  'dismissed'
);

create type public.availability_block_type as enum (
  'available',
  'unavailable',
  'appointment_hold',
  'time_off'
);

create type public.policy_type as enum (
  'terms',
  'privacy',
  'cancellation',
  'photo_release',
  'safety'
);

create type public.payment_placeholder_status as enum (
  'not_started',
  'pending',
  'authorized',
  'captured',
  'refunded',
  'failed'
);

create type public.review_placeholder_status as enum (
  'draft',
  'submitted',
  'hidden'
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table public.markets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status public.market_status not null default 'launching',
  timezone text not null default 'America/New_York',
  country_code text not null default 'US',
  launch_date date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.markets is 'Top-level operating markets. MVP can launch with one market while remaining ready for expansion.';
comment on column public.markets.slug is 'Stable routing and admin identifier for a market.';

create table public.territories (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete cascade,
  name text not null,
  slug text not null,
  status public.territory_status not null default 'planned',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (market_id, slug)
);

comment on table public.territories is 'Sub-regions inside a market. Useful for franchise or local operating boundaries.';
comment on column public.territories.market_id is 'Parent market for territory-level operations and reporting.';

create table public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  email citext not null unique,
  first_name text,
  last_name text,
  phone text,
  default_market_id uuid references public.markets(id) on delete set null,
  default_territory_id uuid references public.territories(id) on delete set null,
  status public.profile_status not null default 'active',
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.user_profiles is 'Application-facing profile row for every authenticated user.';
comment on column public.user_profiles.auth_user_id is 'Direct link to Supabase auth.users.';
comment on column public.user_profiles.default_market_id is 'Default operating market used for UX routing and scoped queries.';

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_profile_id uuid not null references public.user_profiles(id) on delete cascade,
  role public.app_role not null,
  market_id uuid references public.markets(id) on delete cascade,
  territory_id uuid references public.territories(id) on delete cascade,
  status public.profile_status not null default 'active',
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (
    not (role = 'corporate_admin' and market_id is not null)
  )
);

comment on table public.user_roles is 'Role assignments scoped to a market or territory when needed.';
comment on column public.user_roles.role is 'Supports current roles and future franchise or corporate access models.';

create table public.customer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_profile_id uuid not null unique references public.user_profiles(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  status public.profile_status not null default 'active',
  preferred_contact_method text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.customer_profiles is 'Customer-specific profile details. The company owns this relationship, not the stylist.';

create table public.stylist_profiles (
  id uuid primary key default gen_random_uuid(),
  user_profile_id uuid not null unique references public.user_profiles(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  status public.profile_status not null default 'active',
  bio text,
  specialties text[] not null default '{}',
  is_accepting_bookings boolean not null default true,
  emergency_contact_name text,
  emergency_contact_phone text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.stylist_profiles is 'Stylist operational and profile information used for scheduling and safety workflows.';

create table public.households (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  created_by_user_profile_id uuid not null references public.user_profiles(id) on delete restrict,
  name text not null,
  status public.household_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.households is 'Customer-managed household grouping for family bookings and shared addresses.';
comment on column public.households.created_by_user_profile_id is 'Primary app account that manages the household.';

create table public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  first_name text not null,
  last_name text,
  relationship_to_household public.relationship_type not null default 'other',
  date_of_birth date,
  is_booking_contact boolean not null default false,
  sensory_notes text,
  general_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.household_members is 'People within a household who may receive services during an appointment.';
comment on column public.household_members.sensory_notes is 'Supports sensory-friendly service experiences for children or other family members.';

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  label text not null,
  line1 text not null,
  line2 text,
  city text not null,
  state text not null,
  postal_code text not null,
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  service_area_status public.address_status not null default 'pending_review',
  access_notes text,
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.addresses is 'Service addresses attached to a household.';
comment on column public.addresses.service_area_status is 'Operational check used to decide whether a booking location is currently serviceable.';

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  market_id uuid references public.markets(id) on delete cascade,
  territory_id uuid references public.territories(id) on delete cascade,
  name text not null,
  description text,
  sort_order integer not null default 0,
  status public.service_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.service_categories is 'Top-level service groups such as women, men, kids, color, or family.';

create table public.services (
  id uuid primary key default gen_random_uuid(),
  service_category_id uuid not null references public.service_categories(id) on delete restrict,
  market_id uuid references public.markets(id) on delete cascade,
  territory_id uuid references public.territories(id) on delete cascade,
  name text not null,
  description text,
  duration_minutes integer not null check (duration_minutes > 0),
  buffer_minutes integer not null default 0 check (buffer_minutes >= 0),
  base_price_cents integer check (base_price_cents is null or base_price_cents >= 0),
  currency_code text not null default 'USD',
  status public.service_status not null default 'active',
  requires_consultation boolean not null default false,
  allows_multiple_participants boolean not null default false,
  is_mobile_service boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.services is 'Bookable service definitions. Price may be optional during MVP if pricing is handled manually.';
comment on column public.services.allows_multiple_participants is 'Useful for future bundled or family-oriented service products.';

create table public.service_addons (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  market_id uuid references public.markets(id) on delete cascade,
  territory_id uuid references public.territories(id) on delete cascade,
  name text not null,
  description text,
  duration_minutes integer not null default 0 check (duration_minutes >= 0),
  addon_price_cents integer check (addon_price_cents is null or addon_price_cents >= 0),
  status public.service_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.service_addons is 'Optional add-ons that can extend a base service.';

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  customer_profile_id uuid not null references public.customer_profiles(id) on delete restrict,
  household_id uuid not null references public.households(id) on delete restrict,
  address_id uuid not null references public.addresses(id) on delete restrict,
  requested_by_user_profile_id uuid not null references public.user_profiles(id) on delete restrict,
  assigned_stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  status public.appointment_status not null default 'requested',
  requested_start_at timestamptz not null,
  requested_end_at timestamptz,
  scheduled_start_at timestamptz,
  scheduled_end_at timestamptz,
  customer_notes text,
  cancellation_reason text,
  reschedule_reason text,
  source text not null default 'mobile_app',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (requested_end_at is null or requested_end_at > requested_start_at),
  check (scheduled_end_at is null or scheduled_start_at is null or scheduled_end_at > scheduled_start_at)
);

comment on table public.appointments is 'Central operational record for a booking request and service visit.';
comment on column public.appointments.assigned_stylist_profile_id is 'Only one stylist is assigned in MVP, but participant and line-item tables support grouped family bookings.';

create table public.appointment_participants (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  household_member_id uuid not null references public.household_members(id) on delete restrict,
  status public.participant_status not null default 'planned',
  participant_notes text,
  sensory_notes_snapshot text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (appointment_id, household_member_id)
);

comment on table public.appointment_participants is 'Links household members to an appointment so one booking can cover multiple people.';
comment on column public.appointment_participants.sensory_notes_snapshot is 'Captures family-member care notes at booking time for historical accuracy.';

create table public.appointment_services (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  appointment_participant_id uuid references public.appointment_participants(id) on delete cascade,
  service_id uuid references public.services(id) on delete restrict,
  service_addon_id uuid references public.service_addons(id) on delete restrict,
  quantity integer not null default 1 check (quantity > 0),
  duration_snapshot_minutes integer check (duration_snapshot_minutes is null or duration_snapshot_minutes >= 0),
  price_snapshot_cents integer check (price_snapshot_cents is null or price_snapshot_cents >= 0),
  line_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (num_nonnulls(service_id, service_addon_id) = 1)
);

comment on table public.appointment_services is 'Line items for appointment pricing, duration snapshots, and service composition.';
comment on column public.appointment_services.price_snapshot_cents is 'Historical pricing snapshot so later catalog changes do not rewrite booked appointments.';

create table public.appointment_photos (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  household_member_id uuid references public.household_members(id) on delete set null,
  uploaded_by_user_profile_id uuid not null references public.user_profiles(id) on delete restrict,
  storage_bucket text not null default 'appointment-photos',
  storage_path text not null,
  photo_type public.photo_type not null default 'reference',
  is_customer_visible boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.appointment_photos is 'Metadata rows for uploaded appointment photos. Storage bucket permissions must be configured separately.';
comment on column public.appointment_photos.storage_path is 'Path inside Supabase Storage, not a public URL.';

create table public.internal_notes (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete cascade,
  household_id uuid references public.households(id) on delete cascade,
  author_user_profile_id uuid not null references public.user_profiles(id) on delete restrict,
  note_type public.note_type not null default 'admin',
  note_body text not null,
  is_admin_only boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (appointment_id is not null or household_id is not null)
);

comment on table public.internal_notes is 'Private staff notes. Customers must never be allowed to read this table directly.';

create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid not null unique references public.appointments(id) on delete cascade,
  assigned_stylist_profile_id uuid not null references public.stylist_profiles(id) on delete restrict,
  status public.check_in_status not null default 'not_started',
  check_in_at timestamptz,
  check_out_at timestamptz,
  check_in_latitude numeric(9, 6),
  check_in_longitude numeric(9, 6),
  check_out_latitude numeric(9, 6),
  check_out_longitude numeric(9, 6),
  check_in_notes text,
  check_out_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.check_ins is 'Operational safety record for stylist arrival and departure.';

create table public.safety_events (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete cascade,
  stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  reported_by_user_profile_id uuid not null references public.user_profiles(id) on delete restrict,
  event_type public.safety_event_type not null,
  status public.safety_event_status not null default 'open',
  severity smallint not null default 1 check (severity between 1 and 5),
  details text not null,
  resolution_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.safety_events is 'Safety-related records for admins and relevant stylists. Future SOS workflows can build on this table.';

create table public.availability_blocks (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  stylist_profile_id uuid not null references public.stylist_profiles(id) on delete cascade,
  block_type public.availability_block_type not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (end_at > start_at)
);

comment on table public.availability_blocks is 'Future scheduling and time-off model for stylists.';

create table public.policy_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_profile_id uuid not null references public.user_profiles(id) on delete cascade,
  market_id uuid references public.markets(id) on delete set null,
  territory_id uuid references public.territories(id) on delete set null,
  policy_type public.policy_type not null,
  policy_version text not null,
  accepted_at timestamptz not null default timezone('utc', now()),
  source text not null default 'mobile_app',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.policy_acceptances is 'Immutable-ish audit trail of policy acknowledgements by users.';

create table public.payments_placeholder (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  customer_profile_id uuid not null references public.customer_profiles(id) on delete restrict,
  status public.payment_placeholder_status not null default 'not_started',
  amount_cents integer check (amount_cents is null or amount_cents >= 0),
  currency_code text not null default 'USD',
  is_deposit boolean not null default false,
  external_reference text,
  payment_summary text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.payments_placeholder is 'Placeholder payment table for future Stripe integration. Do not store card data here.';
comment on column public.payments_placeholder.external_reference is 'Safe reference to an external processor object, such as a Stripe PaymentIntent id.';

create table public.reviews_placeholder (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  appointment_id uuid not null unique references public.appointments(id) on delete cascade,
  customer_profile_id uuid not null references public.customer_profiles(id) on delete restrict,
  stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  rating integer check (rating is null or rating between 1 and 5),
  review_text text,
  status public.review_placeholder_status not null default 'draft',
  submitted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.reviews_placeholder is 'Future customer review model, kept simple for MVP planning.';

create index markets_status_idx on public.markets (status);

create index territories_market_id_idx on public.territories (market_id);
create index territories_status_idx on public.territories (status);

create index user_profiles_default_market_id_idx on public.user_profiles (default_market_id);
create index user_profiles_default_territory_id_idx on public.user_profiles (default_territory_id);
create index user_profiles_status_idx on public.user_profiles (status);

create index user_roles_user_profile_id_idx on public.user_roles (user_profile_id);
create index user_roles_role_idx on public.user_roles (role);
create index user_roles_market_scope_idx on public.user_roles (market_id, territory_id);

create index customer_profiles_user_profile_id_idx on public.customer_profiles (user_profile_id);
create index customer_profiles_scope_idx on public.customer_profiles (market_id, territory_id);

create index stylist_profiles_user_profile_id_idx on public.stylist_profiles (user_profile_id);
create index stylist_profiles_scope_idx on public.stylist_profiles (market_id, territory_id);
create index stylist_profiles_booking_status_idx on public.stylist_profiles (market_id, is_accepting_bookings);

create index households_scope_idx on public.households (market_id, territory_id);
create index households_created_by_user_profile_id_idx on public.households (created_by_user_profile_id);

create index household_members_household_id_idx on public.household_members (household_id);

create index addresses_household_id_idx on public.addresses (household_id);
create index addresses_scope_status_idx on public.addresses (market_id, territory_id, service_area_status);

create index service_categories_scope_status_idx on public.service_categories (market_id, territory_id, status);
create index services_category_id_idx on public.services (service_category_id);
create index services_scope_status_idx on public.services (market_id, territory_id, status);
create index service_addons_service_id_idx on public.service_addons (service_id);

create index appointments_customer_profile_id_idx on public.appointments (customer_profile_id);
create index appointments_household_id_idx on public.appointments (household_id);
create index appointments_address_id_idx on public.appointments (address_id);
create index appointments_requested_by_idx on public.appointments (requested_by_user_profile_id);
create index appointments_assigned_stylist_schedule_idx on public.appointments (assigned_stylist_profile_id, scheduled_start_at);
create index appointments_scope_status_idx on public.appointments (market_id, territory_id, status);
create index appointments_requested_start_idx on public.appointments (requested_start_at);

create index appointment_participants_appointment_id_idx on public.appointment_participants (appointment_id);
create index appointment_participants_household_member_id_idx on public.appointment_participants (household_member_id);

create index appointment_services_appointment_id_idx on public.appointment_services (appointment_id);
create index appointment_services_participant_id_idx on public.appointment_services (appointment_participant_id);

create index appointment_photos_appointment_id_idx on public.appointment_photos (appointment_id);
create index appointment_photos_household_member_id_idx on public.appointment_photos (household_member_id);
create index appointment_photos_uploaded_by_idx on public.appointment_photos (uploaded_by_user_profile_id);

create index internal_notes_appointment_id_idx on public.internal_notes (appointment_id);
create index internal_notes_household_id_idx on public.internal_notes (household_id);
create index internal_notes_scope_idx on public.internal_notes (market_id, territory_id);

create index check_ins_stylist_id_idx on public.check_ins (assigned_stylist_profile_id);
create index check_ins_scope_status_idx on public.check_ins (market_id, territory_id, status);

create index safety_events_appointment_id_idx on public.safety_events (appointment_id);
create index safety_events_stylist_profile_id_idx on public.safety_events (stylist_profile_id);
create index safety_events_scope_status_idx on public.safety_events (market_id, territory_id, status);

create index availability_blocks_stylist_time_idx on public.availability_blocks (stylist_profile_id, start_at, end_at);
create index availability_blocks_scope_idx on public.availability_blocks (market_id, territory_id);

create index policy_acceptances_user_profile_id_idx on public.policy_acceptances (user_profile_id);
create index policy_acceptances_policy_lookup_idx on public.policy_acceptances (policy_type, policy_version);

create index payments_placeholder_appointment_id_idx on public.payments_placeholder (appointment_id);
create index payments_placeholder_customer_profile_id_idx on public.payments_placeholder (customer_profile_id);
create index payments_placeholder_scope_status_idx on public.payments_placeholder (market_id, territory_id, status);

create index reviews_placeholder_customer_profile_id_idx on public.reviews_placeholder (customer_profile_id);
create index reviews_placeholder_stylist_profile_id_idx on public.reviews_placeholder (stylist_profile_id);
create index reviews_placeholder_scope_status_idx on public.reviews_placeholder (market_id, territory_id, status);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'markets',
    'territories',
    'user_profiles',
    'user_roles',
    'customer_profiles',
    'stylist_profiles',
    'households',
    'household_members',
    'addresses',
    'service_categories',
    'services',
    'service_addons',
    'appointments',
    'appointment_participants',
    'appointment_services',
    'appointment_photos',
    'internal_notes',
    'check_ins',
    'safety_events',
    'availability_blocks',
    'policy_acceptances',
    'payments_placeholder',
    'reviews_placeholder'
  ]
  loop
    execute format(
      'create trigger set_%1$s_updated_at before update on public.%1$s for each row execute function public.set_updated_at()',
      table_name
    );
  end loop;
end;
$$;

create or replace function public.current_user_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select up.id
  from public.user_profiles up
  where up.auth_user_id = auth.uid()
  limit 1;
$$;

comment on function public.current_user_profile_id() is 'Resolves the current auth user into the app-level user_profiles id.';

create or replace function public.is_corporate_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_profile_id = public.current_user_profile_id()
      and ur.role = 'corporate_admin'
      and ur.status = 'active'
  );
$$;

create or replace function public.has_scoped_admin_access(target_market_id uuid, target_territory_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_corporate_admin()
  or exists (
    select 1
    from public.user_roles ur
    where ur.user_profile_id = public.current_user_profile_id()
      and ur.role in ('admin', 'franchisee')
      and ur.status = 'active'
      and (target_market_id is null or ur.market_id = target_market_id)
      and (
        target_territory_id is null
        or ur.territory_id is null
        or ur.territory_id = target_territory_id
      )
  );
$$;

comment on function public.has_scoped_admin_access(uuid, uuid) is 'Checks admin or franchisee access within a market or territory. Corporate admins bypass the scope check.';

create or replace function public.owns_customer_profile(target_customer_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.customer_profiles cp
    where cp.id = target_customer_profile_id
      and cp.user_profile_id = public.current_user_profile_id()
  );
$$;

create or replace function public.owns_household(target_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.households h
    where h.id = target_household_id
      and h.created_by_user_profile_id = public.current_user_profile_id()
  );
$$;

create or replace function public.is_assigned_stylist_for_appointment(target_appointment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.appointments a
    join public.stylist_profiles sp on sp.id = a.assigned_stylist_profile_id
    where a.id = target_appointment_id
      and sp.user_profile_id = public.current_user_profile_id()
  );
$$;

create or replace function public.can_access_appointment(target_appointment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.appointments a
    join public.customer_profiles cp on cp.id = a.customer_profile_id
    where a.id = target_appointment_id
      and (
        cp.user_profile_id = public.current_user_profile_id()
        or public.is_assigned_stylist_for_appointment(a.id)
        or public.has_scoped_admin_access(a.market_id, a.territory_id)
      )
  );
$$;

create or replace function public.can_access_household(target_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.households h
    where h.id = target_household_id
      and (
        h.created_by_user_profile_id = public.current_user_profile_id()
        or public.has_scoped_admin_access(h.market_id, h.territory_id)
        or exists (
          select 1
          from public.appointments a
          where a.household_id = h.id
            and public.is_assigned_stylist_for_appointment(a.id)
        )
      )
  );
$$;

comment on function public.can_access_household(uuid) is 'Allows household access for the owning customer, scoped admins, and stylists assigned to related appointments.';

alter table public.markets enable row level security;
alter table public.territories enable row level security;
alter table public.user_profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.customer_profiles enable row level security;
alter table public.stylist_profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.addresses enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_addons enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_participants enable row level security;
alter table public.appointment_services enable row level security;
alter table public.appointment_photos enable row level security;
alter table public.internal_notes enable row level security;
alter table public.check_ins enable row level security;
alter table public.safety_events enable row level security;
alter table public.availability_blocks enable row level security;
alter table public.policy_acceptances enable row level security;
alter table public.payments_placeholder enable row level security;
alter table public.reviews_placeholder enable row level security;

create policy "markets are readable to authenticated users"
on public.markets
for select
to authenticated
using (true);

create policy "markets are manageable by scoped admins"
on public.markets
for all
to authenticated
using (public.has_scoped_admin_access(id, null))
with check (public.has_scoped_admin_access(id, null));

create policy "territories are readable to authenticated users"
on public.territories
for select
to authenticated
using (true);

create policy "territories are manageable by scoped admins"
on public.territories
for all
to authenticated
using (public.has_scoped_admin_access(market_id, id))
with check (public.has_scoped_admin_access(market_id, id));

create policy "users can read their own profile or admins can read scoped profiles"
on public.user_profiles
for select
to authenticated
using (
  id = public.current_user_profile_id()
  or public.has_scoped_admin_access(default_market_id, default_territory_id)
);

create policy "users can update their own profile or admins can update scoped profiles"
on public.user_profiles
for update
to authenticated
using (
  id = public.current_user_profile_id()
  or public.has_scoped_admin_access(default_market_id, default_territory_id)
)
with check (
  id = public.current_user_profile_id()
  or public.has_scoped_admin_access(default_market_id, default_territory_id)
);

create policy "admins can insert profiles"
on public.user_profiles
for insert
to authenticated
with check (public.has_scoped_admin_access(default_market_id, default_territory_id));

create policy "users can read their roles and admins can read scoped roles"
on public.user_roles
for select
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "admins manage user roles"
on public.user_roles
for all
to authenticated
using (public.has_scoped_admin_access(market_id, territory_id))
with check (public.has_scoped_admin_access(market_id, territory_id));

create policy "customers read own customer profile and admins read scoped customer profiles"
on public.customer_profiles
for select
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "customers create their own customer profile or admins create scoped customer profiles"
on public.customer_profiles
for insert
to authenticated
with check (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "customers update own customer profile and admins update scoped customer profiles"
on public.customer_profiles
for update
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "stylists read own profile and admins read scoped stylist profiles"
on public.stylist_profiles
for select
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "stylists update own profile and admins update scoped stylist profiles"
on public.stylist_profiles
for update
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "admins can insert stylist profiles"
on public.stylist_profiles
for insert
to authenticated
with check (public.has_scoped_admin_access(market_id, territory_id));

create policy "households are readable by owning customers assigned stylists and scoped admins"
on public.households
for select
to authenticated
using (public.can_access_household(id));

create policy "customers and admins can create households"
on public.households
for insert
to authenticated
with check (
  created_by_user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "households are updatable by owners and scoped admins"
on public.households
for update
to authenticated
using (
  created_by_user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  created_by_user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "household members follow household access"
on public.household_members
for select
to authenticated
using (public.can_access_household(household_id));

create policy "customers and admins create household members"
on public.household_members
for insert
to authenticated
with check (public.owns_household(household_id) or exists (
  select 1
  from public.households h
  where h.id = household_id
    and public.has_scoped_admin_access(h.market_id, h.territory_id)
));

create policy "customers and admins update household members"
on public.household_members
for update
to authenticated
using (public.can_access_household(household_id))
with check (public.can_access_household(household_id));

create policy "addresses follow household access"
on public.addresses
for select
to authenticated
using (public.can_access_household(household_id));

create policy "customers and admins create addresses"
on public.addresses
for insert
to authenticated
with check (
  public.owns_household(household_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "customers and admins update addresses"
on public.addresses
for update
to authenticated
using (public.can_access_household(household_id))
with check (public.can_access_household(household_id));

create policy "reference service data is readable to authenticated users"
on public.service_categories
for select
to authenticated
using (true);

create policy "admins manage scoped service categories"
on public.service_categories
for all
to authenticated
using (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
)
with check (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
);

create policy "services are readable to authenticated users"
on public.services
for select
to authenticated
using (true);

create policy "admins manage scoped services"
on public.services
for all
to authenticated
using (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
)
with check (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
);

create policy "service add-ons are readable to authenticated users"
on public.service_addons
for select
to authenticated
using (true);

create policy "admins manage scoped service add-ons"
on public.service_addons
for all
to authenticated
using (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
)
with check (
  public.has_scoped_admin_access(market_id, territory_id)
  or (market_id is null and public.is_corporate_admin())
);

create policy "appointments are visible to owner customer assigned stylist and scoped admins"
on public.appointments
for select
to authenticated
using (public.can_access_appointment(id));

create policy "customers create their own appointments and admins create scoped appointments"
on public.appointments
for insert
to authenticated
with check (
  (
    public.owns_customer_profile(customer_profile_id)
    and public.owns_household(household_id)
    and requested_by_user_profile_id = public.current_user_profile_id()
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "appointments are updatable by owner customer assigned stylist and scoped admins"
on public.appointments
for update
to authenticated
using (public.can_access_appointment(id))
with check (public.can_access_appointment(id));

-- TODO: Tighten appointment update rules before production so customers cannot
-- change fields that should only be editable by admins or assigned stylists.

create policy "appointment participants follow appointment access"
on public.appointment_participants
for select
to authenticated
using (public.can_access_appointment(appointment_id));

create policy "appointment participants are managed by appointment owners stylists and admins"
on public.appointment_participants
for all
to authenticated
using (public.can_access_appointment(appointment_id))
with check (public.can_access_appointment(appointment_id));

create policy "appointment service lines follow appointment access"
on public.appointment_services
for select
to authenticated
using (public.can_access_appointment(appointment_id));

create policy "appointment service lines are managed by appointment owners stylists and admins"
on public.appointment_services
for all
to authenticated
using (public.can_access_appointment(appointment_id))
with check (public.can_access_appointment(appointment_id));

create policy "appointment photos are visible through appointment access"
on public.appointment_photos
for select
to authenticated
using (
  public.can_access_appointment(appointment_id)
  and (
    is_customer_visible
    or public.is_assigned_stylist_for_appointment(appointment_id)
    or public.has_scoped_admin_access(market_id, territory_id)
  )
);

create policy "appointment photos are insertable by appointment participants and admins"
on public.appointment_photos
for insert
to authenticated
with check (
  (
    public.can_access_appointment(appointment_id)
    and uploaded_by_user_profile_id = public.current_user_profile_id()
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "appointment photos are updatable by admins and assigned stylists"
on public.appointment_photos
for update
to authenticated
using (
  public.is_assigned_stylist_for_appointment(appointment_id)
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  public.is_assigned_stylist_for_appointment(appointment_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

-- TODO: Add matching Supabase Storage bucket policies for appointment-photos.

create policy "internal notes are visible to assigned stylists and scoped admins only"
on public.internal_notes
for select
to authenticated
using (
  (
    appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id)
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "internal notes are insertable by assigned stylists and scoped admins"
on public.internal_notes
for insert
to authenticated
with check (
  author_user_profile_id = public.current_user_profile_id()
  and (
    (appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id))
    or public.has_scoped_admin_access(market_id, territory_id)
  )
);

create policy "internal notes are updatable by assigned stylists and scoped admins"
on public.internal_notes
for update
to authenticated
using (
  (
    appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id)
  )
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  (
    appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id)
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "check-ins are visible to assigned stylists and scoped admins"
on public.check_ins
for select
to authenticated
using (
  public.is_assigned_stylist_for_appointment(appointment_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "check-ins are managed by assigned stylists and scoped admins"
on public.check_ins
for all
to authenticated
using (
  public.is_assigned_stylist_for_appointment(appointment_id)
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  public.is_assigned_stylist_for_appointment(appointment_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "safety events are visible to relevant stylists and scoped admins"
on public.safety_events
for select
to authenticated
using (
  public.has_scoped_admin_access(market_id, territory_id)
  or (
    appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id)
  )
  or exists (
    select 1
    from public.stylist_profiles sp
    where sp.id = stylist_profile_id
      and sp.user_profile_id = public.current_user_profile_id()
  )
);

create policy "safety events are insertable by relevant stylists and scoped admins"
on public.safety_events
for insert
to authenticated
with check (
  reported_by_user_profile_id = public.current_user_profile_id()
  and (
    public.has_scoped_admin_access(market_id, territory_id)
    or (
      appointment_id is not null and public.is_assigned_stylist_for_appointment(appointment_id)
    )
    or exists (
      select 1
      from public.stylist_profiles sp
      where sp.id = stylist_profile_id
        and sp.user_profile_id = public.current_user_profile_id()
    )
  )
);

create policy "safety events are updatable by scoped admins"
on public.safety_events
for update
to authenticated
using (public.has_scoped_admin_access(market_id, territory_id))
with check (public.has_scoped_admin_access(market_id, territory_id));

create policy "availability blocks are visible to owning stylists and scoped admins"
on public.availability_blocks
for select
to authenticated
using (
  exists (
    select 1
    from public.stylist_profiles sp
    where sp.id = stylist_profile_id
      and sp.user_profile_id = public.current_user_profile_id()
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "availability blocks are managed by owning stylists and scoped admins"
on public.availability_blocks
for all
to authenticated
using (
  exists (
    select 1
    from public.stylist_profiles sp
    where sp.id = stylist_profile_id
      and sp.user_profile_id = public.current_user_profile_id()
  )
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  exists (
    select 1
    from public.stylist_profiles sp
    where sp.id = stylist_profile_id
      and sp.user_profile_id = public.current_user_profile_id()
  )
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "policy acceptances are visible to the owning user and scoped admins"
on public.policy_acceptances
for select
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "policy acceptances are insertable by the owning user and scoped admins"
on public.policy_acceptances
for insert
to authenticated
with check (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "payments placeholder is visible to scoped admins only"
on public.payments_placeholder
for select
to authenticated
using (public.has_scoped_admin_access(market_id, territory_id));

create policy "payments placeholder is managed by scoped admins only"
on public.payments_placeholder
for all
to authenticated
using (public.has_scoped_admin_access(market_id, territory_id))
with check (public.has_scoped_admin_access(market_id, territory_id));

-- TODO: Expose customer-safe payment summaries through a dedicated view later.

create policy "reviews placeholder is visible to owning customers relevant stylists and scoped admins"
on public.reviews_placeholder
for select
to authenticated
using (
  public.owns_customer_profile(customer_profile_id)
  or public.has_scoped_admin_access(market_id, territory_id)
  or exists (
    select 1
    from public.stylist_profiles sp
    where sp.id = stylist_profile_id
      and sp.user_profile_id = public.current_user_profile_id()
  )
);

create policy "reviews placeholder is insertable by owning customers and scoped admins"
on public.reviews_placeholder
for insert
to authenticated
with check (
  public.owns_customer_profile(customer_profile_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "reviews placeholder is updatable by owning customers and scoped admins"
on public.reviews_placeholder
for update
to authenticated
using (
  public.owns_customer_profile(customer_profile_id)
  or public.has_scoped_admin_access(market_id, territory_id)
)
with check (
  public.owns_customer_profile(customer_profile_id)
  or public.has_scoped_admin_access(market_id, territory_id)
);

commit;