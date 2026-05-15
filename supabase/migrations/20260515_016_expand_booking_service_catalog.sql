begin;

update public.service_categories
set
  description = seed.description,
  sort_order = seed.sort_order,
  status = 'active'::public.service_status
from (
  values
    ('Women', 'Precision women''s haircut and styling services delivered in-home.', 1),
    ('Hair Color', 'Highlights, balayage, all-over color, glossing, and corrective color services.', 2),
    ('Men', 'Men''s haircut, beard, taper, and grooming services.', 3),
    ('Kids', 'Children''s haircut and simple styling services for in-home visits.', 4),
    ('Add-Ons', 'Treatment and finishing upgrades paired with a core service.', 5),
    ('Special Event / Wedding', 'Formal styling and bridal services for events and wedding days.', 6)
) as seed(name, description, sort_order)
where public.service_categories.market_id = (
    select id from public.markets where slug = 'utah-county-launch' limit 1
  )
  and public.service_categories.name = seed.name;

insert into public.service_categories (
  market_id,
  name,
  description,
  sort_order,
  status
)
select
  m.id,
  seed.name,
  seed.description,
  seed.sort_order,
  'active'::public.service_status
from public.markets m
cross join (
  values
    ('Women', 'Precision women''s haircut and styling services delivered in-home.', 1),
    ('Hair Color', 'Highlights, balayage, all-over color, glossing, and corrective color services.', 2),
    ('Men', 'Men''s haircut, beard, taper, and grooming services.', 3),
    ('Kids', 'Children''s haircut and simple styling services for in-home visits.', 4),
    ('Add-Ons', 'Treatment and finishing upgrades paired with a core service.', 5),
    ('Special Event / Wedding', 'Formal styling and bridal services for events and wedding days.', 6)
) as seed(name, description, sort_order)
where m.slug = 'utah-county-launch'
  and not exists (
    select 1
    from public.service_categories sc
    where sc.market_id = m.id
      and sc.name = seed.name
  );

update public.service_categories
set status = 'inactive'::public.service_status
where market_id = (
    select id from public.markets where slug = 'utah-county-launch' limit 1
  )
  and name = 'Family';

update public.services
set status = 'inactive'::public.service_status
where market_id = (
    select id from public.markets where slug = 'utah-county-launch' limit 1
  )
  and name in (
    'Luxury Women''s Haircut',
    'Signature Blowout',
    'Color Refresh',
    'Kids Haircut',
    'Sensory-friendly Kids Haircut',
    'Family Appointment Block'
  );

update public.services s
set
  service_category_id = sc.id,
  description = seed.service_description,
  duration_minutes = seed.duration_minutes,
  base_price_cents = seed.base_price_cents,
  status = 'active'::public.service_status,
  allows_multiple_participants = seed.allows_multiple_participants,
  is_mobile_service = true
from public.service_categories sc
join (
  values
    ('Women', 'Women''s Haircut', 'Precision haircut customized to your hair type, face shape, and styling preferences.', 60, 8500, false),
    ('Women', 'Shampoo, Haircut & Style', 'Includes shampoo, customized haircut, and finished styling.', 75, 10500, false),
    ('Women', 'Trim / Maintenance Cut', 'Light dusting and reshaping to maintain healthy ends and style.', 45, 6500, false),
    ('Women', 'Layered Haircut', 'Soft or dramatic layers for movement, texture, and dimension.', 75, 9500, false),
    ('Women', 'Long Haircut', 'Designed for medium to long hair needing reshaping and healthy ends.', 75, 9800, false),
    ('Women', 'Bob / Lob Haircut', 'Structured short-to-medium haircut with customized shaping.', 60, 9000, false),
    ('Women', 'Curly Haircut', 'Haircut designed to enhance natural curls and reduce bulk.', 90, 11000, false),
    ('Women', 'Bang Trim', 'Quick fringe or face-frame refresh between appointments.', 20, 2500, false),
    ('Women', 'Blowout & Style', 'Professional blow dry and styling without haircut service.', 50, 7000, false),
    ('Women', 'Special Event Styling', 'Soft curls, waves, half-up styles, or elegant event hair styling.', 75, 12000, false),
    ('Women', 'Bridal / Wedding Hair', 'Customized wedding styling consultation and event-day hair.', 120, 18000, false),
    ('Hair Color', 'Highlights', 'Traditional foil highlights for brightness and dimension.', 150, 16500, false),
    ('Hair Color', 'Partial Highlights', 'Focused highlights around the face and crown area.', 120, 13500, false),
    ('Hair Color', 'Baby Lights', 'Ultra-fine highlights for a soft, natural sun-kissed look.', 150, 17500, false),
    ('Hair Color', 'Balayage', 'Hand-painted color for blended, lived-in dimension.', 180, 19500, false),
    ('Hair Color', 'Root Retouch', 'Color refresh for regrowth and gray coverage.', 90, 9500, false),
    ('Hair Color', 'All Over Color', 'Single-process color from roots to ends.', 120, 12500, false),
    ('Hair Color', 'Toner / Gloss', 'Enhances tone, shine, and color longevity.', 45, 5500, false),
    ('Hair Color', 'Color Correction', 'Customized corrective color service consultation required.', 210, 0, false),
    ('Men', 'Men''s Haircut', 'Classic cut, fade, taper, or scissor haircut customized to your style.', 45, 6500, false),
    ('Men', 'Haircut + Beard Trim', 'Haircut with beard shaping and cleanup.', 60, 8500, false),
    ('Men', 'Buzz Cut', 'Single-length clipper cut with edge cleanup.', 25, 3500, false),
    ('Men', 'Fade / Taper Cut', 'Precision fade or taper blending service.', 45, 7000, false),
    ('Men', 'Beard Trim', 'Detailed beard shaping and neckline cleanup.', 20, 2500, false),
    ('Men', 'Eyebrow Cleanup', 'Quick eyebrow shaping and stray hair cleanup.', 15, 1800, false),
    ('Men', 'Scalp Treatment', 'Refreshing scalp cleansing and treatment service.', 20, 2500, false),
    ('Kids', 'Kids Haircut – Boys', 'Classic haircut for boys ages 10 and under.', 30, 4500, false),
    ('Kids', 'Kids Haircut – Girls', 'Haircut and trim service for girls ages 10 and under.', 35, 4800, false),
    ('Kids', 'Kids Shampoo + Cut', 'Gentle shampoo and haircut service for kids.', 40, 5200, false),
    ('Kids', 'First Haircut Package', 'Special keepsake-style first haircut experience.', 35, 5000, false),
    ('Kids', 'Braids / Simple Styling', 'Simple braids or light styling after haircut.', 25, 3000, false),
    ('Add-Ons', 'Deep Conditioning Treatment', 'Hydrating treatment to improve softness and shine.', 15, 2200, false),
    ('Add-Ons', 'Extra Styling Time', 'Added curling, flat ironing, or detailed finishing.', 20, 2500, false),
    ('Add-Ons', 'Hot Tool Styling', 'Professional curls, waves, or smoothing finish.', 25, 3000, false),
    ('Add-Ons', 'Hair Tinsel', 'Temporary sparkle strands for fun styling.', 15, 1800, false),
    ('Add-Ons', 'Scalp Treatment', 'Refreshing scalp care add-on.', 15, 2000, false),
    ('Add-Ons', 'Eyebrow Cleanup', 'Quick shaping and cleanup.', 10, 1500, false),
    ('Add-Ons', 'Beard Trim', 'Beard detailing add-on for men''s services.', 15, 1800, false),
    ('Add-Ons', 'Extension Blend Style', 'Blending and styling existing extensions.', 30, 4000, false),
    ('Special Event / Wedding', 'Bridal Trial', 'Preview styling appointment before the wedding day.', 90, 12500, false),
    ('Special Event / Wedding', 'Bridal Hair Styling', 'Wedding-day bridal hair service.', 120, 18000, false),
    ('Special Event / Wedding', 'Bridesmaid Styling', 'Event styling for bridal party members.', 60, 8500, false),
    ('Special Event / Wedding', 'Flower Girl Styling', 'Simple curls, braids, or elegant styling for flower girls.', 35, 4500, false),
    ('Special Event / Wedding', 'Event Hair Styling', 'Hair styling for parties, photoshoots, dances, or formal events.', 60, 9000, false),
    ('Special Event / Wedding', 'Glam Waves / Hollywood Waves', 'Polished formal wave styling.', 75, 11000, false),
    ('Special Event / Wedding', 'Updo Styling', 'Elegant updo or pinned formal hairstyle.', 75, 10500, false),
    ('Special Event / Wedding', 'On-Location Bridal Package', 'Mobile wedding-day styling package for groups/events.', 180, 0, true)
) as seed(category_name, service_name, service_description, duration_minutes, base_price_cents, allows_multiple_participants)
  on sc.name = seed.category_name
  and sc.market_id = (select id from public.markets where slug = 'utah-county-launch' limit 1)
where s.market_id = sc.market_id
  and s.name = seed.service_name;

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
    ('Women', 'Women''s Haircut', 'Precision haircut customized to your hair type, face shape, and styling preferences.', 60, 8500, false),
    ('Women', 'Shampoo, Haircut & Style', 'Includes shampoo, customized haircut, and finished styling.', 75, 10500, false),
    ('Women', 'Trim / Maintenance Cut', 'Light dusting and reshaping to maintain healthy ends and style.', 45, 6500, false),
    ('Women', 'Layered Haircut', 'Soft or dramatic layers for movement, texture, and dimension.', 75, 9500, false),
    ('Women', 'Long Haircut', 'Designed for medium to long hair needing reshaping and healthy ends.', 75, 9800, false),
    ('Women', 'Bob / Lob Haircut', 'Structured short-to-medium haircut with customized shaping.', 60, 9000, false),
    ('Women', 'Curly Haircut', 'Haircut designed to enhance natural curls and reduce bulk.', 90, 11000, false),
    ('Women', 'Bang Trim', 'Quick fringe or face-frame refresh between appointments.', 20, 2500, false),
    ('Women', 'Blowout & Style', 'Professional blow dry and styling without haircut service.', 50, 7000, false),
    ('Women', 'Special Event Styling', 'Soft curls, waves, half-up styles, or elegant event hair styling.', 75, 12000, false),
    ('Women', 'Bridal / Wedding Hair', 'Customized wedding styling consultation and event-day hair.', 120, 18000, false),
    ('Hair Color', 'Highlights', 'Traditional foil highlights for brightness and dimension.', 150, 16500, false),
    ('Hair Color', 'Partial Highlights', 'Focused highlights around the face and crown area.', 120, 13500, false),
    ('Hair Color', 'Baby Lights', 'Ultra-fine highlights for a soft, natural sun-kissed look.', 150, 17500, false),
    ('Hair Color', 'Balayage', 'Hand-painted color for blended, lived-in dimension.', 180, 19500, false),
    ('Hair Color', 'Root Retouch', 'Color refresh for regrowth and gray coverage.', 90, 9500, false),
    ('Hair Color', 'All Over Color', 'Single-process color from roots to ends.', 120, 12500, false),
    ('Hair Color', 'Toner / Gloss', 'Enhances tone, shine, and color longevity.', 45, 5500, false),
    ('Hair Color', 'Color Correction', 'Customized corrective color service consultation required.', 210, 0, false),
    ('Men', 'Men''s Haircut', 'Classic cut, fade, taper, or scissor haircut customized to your style.', 45, 6500, false),
    ('Men', 'Haircut + Beard Trim', 'Haircut with beard shaping and cleanup.', 60, 8500, false),
    ('Men', 'Buzz Cut', 'Single-length clipper cut with edge cleanup.', 25, 3500, false),
    ('Men', 'Fade / Taper Cut', 'Precision fade or taper blending service.', 45, 7000, false),
    ('Men', 'Beard Trim', 'Detailed beard shaping and neckline cleanup.', 20, 2500, false),
    ('Men', 'Eyebrow Cleanup', 'Quick eyebrow shaping and stray hair cleanup.', 15, 1800, false),
    ('Men', 'Scalp Treatment', 'Refreshing scalp cleansing and treatment service.', 20, 2500, false),
    ('Kids', 'Kids Haircut – Boys', 'Classic haircut for boys ages 10 and under.', 30, 4500, false),
    ('Kids', 'Kids Haircut – Girls', 'Haircut and trim service for girls ages 10 and under.', 35, 4800, false),
    ('Kids', 'Kids Shampoo + Cut', 'Gentle shampoo and haircut service for kids.', 40, 5200, false),
    ('Kids', 'First Haircut Package', 'Special keepsake-style first haircut experience.', 35, 5000, false),
    ('Kids', 'Braids / Simple Styling', 'Simple braids or light styling after haircut.', 25, 3000, false),
    ('Add-Ons', 'Deep Conditioning Treatment', 'Hydrating treatment to improve softness and shine.', 15, 2200, false),
    ('Add-Ons', 'Toner / Gloss', 'Refreshes blonde, brunette, or dimensional tones.', 15, 2000, false),
    ('Add-Ons', 'Extra Styling Time', 'Added curling, flat ironing, or detailed finishing.', 20, 2500, false),
    ('Add-Ons', 'Hot Tool Styling', 'Professional curls, waves, or smoothing finish.', 25, 3000, false),
    ('Add-Ons', 'Hair Tinsel', 'Temporary sparkle strands for fun styling.', 15, 1800, false),
    ('Add-Ons', 'Scalp Treatment', 'Refreshing scalp care add-on.', 15, 2000, false),
    ('Add-Ons', 'Eyebrow Cleanup', 'Quick shaping and cleanup.', 10, 1500, false),
    ('Add-Ons', 'Beard Trim', 'Beard detailing add-on for men''s services.', 15, 1800, false),
    ('Add-Ons', 'Extension Blend Style', 'Blending and styling existing extensions.', 30, 4000, false),
    ('Special Event / Wedding', 'Bridal Trial', 'Preview styling appointment before the wedding day.', 90, 12500, false),
    ('Special Event / Wedding', 'Bridal Hair Styling', 'Wedding-day bridal hair service.', 120, 18000, false),
    ('Special Event / Wedding', 'Bridesmaid Styling', 'Event styling for bridal party members.', 60, 8500, false),
    ('Special Event / Wedding', 'Flower Girl Styling', 'Simple curls, braids, or elegant styling for flower girls.', 35, 4500, false),
    ('Special Event / Wedding', 'Event Hair Styling', 'Hair styling for parties, photoshoots, dances, or formal events.', 60, 9000, false),
    ('Special Event / Wedding', 'Glam Waves / Hollywood Waves', 'Polished formal wave styling.', 75, 11000, false),
    ('Special Event / Wedding', 'Updo Styling', 'Elegant updo or pinned formal hairstyle.', 75, 10500, false),
    ('Special Event / Wedding', 'On-Location Bridal Package', 'Mobile wedding-day styling package for groups/events.', 180, 0, true)
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