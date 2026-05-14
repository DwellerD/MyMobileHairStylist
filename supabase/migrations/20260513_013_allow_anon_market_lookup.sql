begin;

create policy "markets are readable to anonymous users"
on public.markets
for select
to anon
using (true);

commit;