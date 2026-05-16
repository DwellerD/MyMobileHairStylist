begin;

create table public.stylist_applications (
  id uuid primary key default gen_random_uuid(),
  user_profile_id uuid not null unique references public.user_profiles(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete restrict,
  territory_id uuid references public.territories(id) on delete set null,
  phone text,
  city text,
  state text,
  license_number text,
  years_experience integer,
  specialties text[] not null default '{}',
  portfolio_url text,
  motivation text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewer_notes text,
  reviewed_by_user_profile_id uuid references public.user_profiles(id) on delete set null,
  reviewed_at timestamptz,
  approved_stylist_profile_id uuid references public.stylist_profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (years_experience is null or years_experience >= 0)
);

comment on table public.stylist_applications is 'Applications submitted by prospective stylists before operational access is activated.';
comment on column public.stylist_applications.status is 'Approval state for the stylist onboarding workflow.';

create index stylist_applications_status_idx
  on public.stylist_applications (status, market_id, territory_id);

drop trigger if exists set_stylist_applications_updated_at on public.stylist_applications;
create trigger set_stylist_applications_updated_at
before update on public.stylist_applications
for each row execute function public.set_updated_at();

alter table public.stylist_applications enable row level security;

create policy "users read own stylist application and admins read scoped applications"
on public.stylist_applications
for select
to authenticated
using (
  user_profile_id = public.current_user_profile_id()
  or public.has_scoped_admin_access(market_id, territory_id)
);

create policy "users create their own stylist application"
on public.stylist_applications
for insert
to authenticated
with check (
  user_profile_id = public.current_user_profile_id()
);

create policy "admins update scoped stylist applications"
on public.stylist_applications
for update
to authenticated
using (public.has_scoped_admin_access(market_id, territory_id))
with check (public.has_scoped_admin_access(market_id, territory_id));

commit;