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
5. Copy `.env/dev.json.example` to `.env/dev.json` and fill in your values.
6. On iOS, set `SdkRoot` in `.env/dev.json` from:

```bash
xcrun --sdk iphoneos --show-sdk-path
```

7. Run the app with your define file:

```bash
flutter run --dart-define-from-file=.env/dev.json
```

For iOS Simulator, override `SdkRoot` to the simulator SDK:

```bash
flutter run -d "iPhone 17 Pro" --dart-define-from-file=.env/dev.json --dart-define=SdkRoot=$(xcrun --sdk iphonesimulator --show-sdk-path)
```

If the dart defines are missing, the app still boots but Supabase-backed flows remain unavailable.

## Current Supabase Project

This workspace is prepared to run against:

- Project URL: `https://xdykcrwbkupevoanunto.supabase.co`
- Public key: configured in [.vscode/launch.json](.vscode/launch.json) for local development only

From VS Code, you can launch the app with the `Flutter (Supabase Project)` run configuration.

Important:

- This only wires the app to the Supabase project.
- The database still needs the SQL migrations applied before auth, booking, stylist, and admin flows can work.
- Never put a `service_role` key in the Flutter app.

## First Run In Supabase

Apply these files in order inside the Supabase SQL Editor:

1. `supabase/migrations/20260513_001_initial_hair_salon_schema.sql`
2. `supabase/migrations/20260513_002_auth_profile_bootstrap.sql`
3. `supabase/migrations/20260513_003_seed_launch_market_and_services.sql`
4. `supabase/migrations/20260513_004_booking_request_fields.sql`
5. `supabase/migrations/20260513_005_appointment_photo_bucket.sql`
6. `supabase/migrations/20260513_006_stylist_mvp_operational_updates.sql`
7. `supabase/migrations/20260513_007_admin_confirmed_status.sql`
8. `supabase/migrations/20260513_008_booking_payment_placeholders.sql`
9. `supabase/migrations/20260513_009_harden_appointment_photo_storage.sql`
10. `supabase/migrations/20260513_010_harden_appointment_updates.sql`
11. `supabase/migrations/20260513_011_harden_appointment_line_item_policies.sql`

## Validation

```powershell
flutter analyze
flutter test
```

## Release Preparation Assets

- Android signing template: `android/key.properties.example`
- Privacy policy draft: `docs/privacy-policy.md`
- Terms draft: `docs/terms-of-service.md`
- Account deletion process draft: `docs/account-deletion.md`
- Support contact draft: `docs/support.md`

Before submitting to app stores, replace placeholder emails/domains in `docs/` with your production contact information and publish these documents at public URLs.

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

