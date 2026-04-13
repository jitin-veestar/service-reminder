# Service Reminder

Technician-focused Flutter app for RO (reverse osmosis) and similar **service visit reminders**: customers, assigned visits, notifications, reports, optional WhatsApp helpers, and PDF receipts. Uses **Riverpod**, **go_router**, and **Supabase** (auth + data).

## Stack

- Flutter (Dart 3.3+)
- `flutter_riverpod`, `go_router`, `supabase_flutter`
- Local notifications, optional Hindi UI (`lib/l10n/`)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A [Supabase](https://supabase.com) project (URL + **anon** public key — never commit the **service_role** key in the client)

## Configuration

The app does **not** ship with Supabase credentials in source. You must pass them at build/run time.

### Option A: `dart_defines.json` (recommended for local dev)

1. Copy `dart_defines.example.json` to **`dart_defines.json`** in the project root (this file is **gitignored**).
2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### Option B: Inline defines

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Release builds (Play / TestFlight / App Store) should use the same mechanism in CI (e.g. inject defines from secrets).

If defines are missing, the app shows a short configuration screen instead of connecting to Supabase.

### Optional schema flags

See comments in `lib/core/constants/app_constants.dart` for flags such as `CUSTOMERS_HAS_CUSTOMER_TYPE`, `SERVICES_HAS_AMOUNT_CHARGED`, etc., if your database schema differs.

## Running

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

## Tests

```bash
flutter test
```

## Android release (Google Play)

- **Application ID:** `com.veestar.service_reminder`
- **Signing:** copy `android/key.properties.example` to **`android/key.properties`** (gitignored), add your keystore path and passwords, and place the `.jks` under `android/` (also gitignored). See the example file for a sample `keytool` command.
- Without `key.properties`, release builds still sign with the **debug** key (fine for local checks; **not** for Play upload).

```bash
flutter build appbundle --dart-define-from-file=dart_defines.json
```

## iOS

- **Bundle ID:** `com.veestar.serviceReminder` (Xcode / App Store Connect).
- Open `ios/Runner.xcworkspace`, set signing team, archive, and upload. Pass the same Supabase defines for release builds.

## Store / billing note

In-app “plans” currently control **feature flags** on device; **Apple/Google in-app purchase is not wired**. Copy on the plans screen states that no charge goes through the stores until real billing is implemented per store rules.

## Project layout (high level)

| Path | Purpose |
|------|--------|
| `lib/app/` | Bootstrap, router, `MaterialApp` |
| `lib/core/` | Theme, constants, notifications, PDF helpers |
| `lib/features/` | Feature modules (auth, dashboard, customers, …) |
| `lib/l10n/` | ARBs + generated `AppLocalizations` |
| `supabase/` | Migrations and local Supabase config |

## License

`publish_to: "none"` — private / unpublished package; add a license file if you open-source the repo.
