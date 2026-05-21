begin;

grant select, insert, update on public.stylist_applications to authenticated;

grant execute on function public.approve_stylist_application(uuid, uuid, text) to authenticated;
grant execute on function public.reject_stylist_application(uuid, text) to authenticated;
grant execute on function public.grant_admin_access(uuid, public.app_role, uuid, uuid, boolean) to authenticated;

commit;
