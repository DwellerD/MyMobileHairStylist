begin;

update public.markets
set
  name = 'Utah County Launch Market',
  slug = 'utah-county-launch',
  timezone = 'America/Denver',
  updated_at = timezone('utc', now())
where slug = 'charlotte-launch';

commit;