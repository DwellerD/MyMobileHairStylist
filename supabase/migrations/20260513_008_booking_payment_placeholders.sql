begin;

alter table public.payments_placeholder
add column if not exists provider text,
add column if not exists payment_kind text,
add column if not exists payment_reference_type text;

comment on column public.payments_placeholder.provider is 'Planned payment provider identifier such as stripe. Safe for configuration and reporting only.';
comment on column public.payments_placeholder.payment_kind is 'Business intent for the placeholder record such as deposit, balance, tip, refund, or cancellation_fee.';
comment on column public.payments_placeholder.payment_reference_type is 'Reference category such as payment_intent, refund, transfer, or charge when a real processor is integrated.';

create or replace function public.create_booking_payment_placeholder()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.payments_placeholder (
    market_id,
    territory_id,
    appointment_id,
    customer_profile_id,
    status,
    amount_cents,
    currency_code,
    is_deposit,
    provider,
    payment_kind,
    payment_summary
  )
  values (
    new.market_id,
    new.territory_id,
    new.id,
    new.customer_profile_id,
    'not_started',
    null,
    'USD',
    true,
    'stripe',
    'deposit',
    'MVP placeholder only. Future server-side Stripe PaymentIntent creation will update this record; no card data is stored here.'
  );

  return new;
end;
$$;

comment on function public.create_booking_payment_placeholder() is 'Creates a safe payment placeholder row when a booking request is inserted. No real payment processing happens here.';

drop trigger if exists create_booking_payment_placeholder_on_appointment on public.appointments;

create trigger create_booking_payment_placeholder_on_appointment
after insert on public.appointments
for each row
execute function public.create_booking_payment_placeholder();

commit;