# Mobile Hair Stylist

Premium mobile hair salon Flutter app scaffold with customer booking, stylist operations, admin review workflows, and a Supabase-first backend structure.

## Current Scope

- Flutter app with Riverpod state management and go_router role-based navigation
- Supabase authentication with customer, stylist, and admin role routing
- Real customer booking flow with address, household members, services, notes, photos, preferred time, and payment placeholder steps
- Real stylist operational screens for today, schedule, appointment detail, check-in, check-out, completion, and safety event placeholders
- Real admin dashboard for booking review, assignment, customer/stylist directories, and service catalog management
- Supabase SQL migrations for schema, auth bootstrap, booking support, storage, and RLS hardening

## Tech Stack

- Flutter
- Dart
- flutter_riverpod
- go_router
- supabase_flutter
- Supabase Postgres, Auth, Storage, and RLS

## Project Structure

```text
lib/
	core/
	features/
	shared/
supabase/
	migrations/
test/
```

## Local Setup

1. Install Flutter and verify with `flutter doctor`.
2. Install project dependencies with `flutter pub get`.
3. Create a Supabase project.
4. Apply the SQL files in `supabase/migrations/` in order.
5. Run the app with compile-time environment values:

```powershell
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If the dart defines are missing, the app still boots but Supabase-backed flows remain unavailable.

## Validation

```powershell
flutter analyze
flutter test
```

## Supabase Notes

- The app does not store secrets in source control.
- Supabase configuration is read from `--dart-define` values.
- Appointment photo storage and appointment mutation policies were tightened to reduce cross-user access.
- Payment handling is intentionally placeholder-only for MVP; no production card processing is implemented in this repository.

## Current MVP Gaps

- Customer appointment detail, family management, and profile management still need fuller product implementation.
- Stylist earnings and full safety escalation are still placeholder workflows.
- Production Stripe payments and signed media delivery should be implemented server-side in a later phase.

## Next Recommended Build Steps

1. Add customer appointment detail and household management flows.
2. Add automated Supabase policy tests and booking lifecycle integration tests.
3. Move payment collection to server-created Stripe PaymentIntents via Supabase Edge Functions.

