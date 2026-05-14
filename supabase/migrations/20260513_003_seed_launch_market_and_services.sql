begin;

insert into public.markets (
  id,
  name,
  slug,
  status,
  timezone,
  country_code
)
select
  gen_random_uuid(),
  'Utah County Launch Market',
  'utah-county-launch',
  'active',
  'America/Denver',
  'US'
where not exists (
  select 1 from public.markets where slug = 'utah-county-launch'
);

insert into public.service_categories (
  market_id,
  name,
  description,
  sort_order,
  status
)
select m.id, category_name, category_description, sort_order, 'active'::public.service_status
from public.markets m
cross join (
  values
    ('Women', 'Premium in-home services for women including cuts, blowouts, and color.', 1),
    ('Men', 'Clean, polished grooming services delivered at home.', 2),
    ('Kids', 'Family-friendly haircut services including sensory-friendly options.', 3),
    ('Family', 'Bundled household appointment blocks for multiple participants.', 4)
) as seed(category_name, category_description, sort_order)
where m.slug = 'utah-county-launch'
  and not exists (
    select 1
    from public.service_categories sc
    where sc.market_id = m.id
      and sc.name = seed.category_name
  );

insert into public.services (
  service_category_id,
  market_id,
  name,
  description,
  duration_minutes,
  base_price_cents,
  status,
  allows_multiple_participants,
  is_mobile_service
)
select
  sc.id,
  sc.market_id,
  seed.service_name,
  seed.service_description,
  seed.duration_minutes,
  seed.base_price_cents,
  'active'::public.service_status,
  seed.allows_multiple_participants,
  true
from public.service_categories sc
join (
  values
    ('Women', 'Luxury Women''s Haircut', 'An in-home haircut with consultation and polished finish.', 75, 12000, false),
    ('Women', 'Signature Blowout', 'A smooth, styled finish for everyday luxury or events.', 60, 8500, false),
    ('Women', 'Color Refresh', 'A premium color maintenance visit booked as a request for admin confirmation.', 120, 18500, false),
    ('Men', 'Men''s Haircut', 'A clean in-home cut with light styling.', 45, 6500, false),
    ('Men', 'Beard Trim', 'A detailed beard cleanup and shaping service.', 30, 3500, false),
    ('Kids', 'Kids Haircut', 'A family-friendly haircut with calm, home-based convenience.', 30, 4500, false),
    ('Kids', 'Sensory-friendly Kids Haircut', 'A slower, gentler haircut experience designed around sensory needs.', 45, 5500, false),
    ('Family', 'Family Appointment Block', 'A bundled household visit for multiple participants under one request.', 120, 0, true)
) as seed(category_name, service_name, service_description, duration_minutes, base_price_cents, allows_multiple_participants)
  on sc.name = seed.category_name
where sc.market_id = (select id from public.markets where slug = 'utah-county-launch' limit 1)
  and not exists (
    select 1
    from public.services s
    where s.market_id = sc.market_id
      and s.name = seed.service_name
  );

commit;