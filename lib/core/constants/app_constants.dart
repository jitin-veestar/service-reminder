abstract final class AppConstants {
  /// Supabase project URL. Required — pass at build time, never commit real values.
  ///
  /// ```
  /// flutter run \
  ///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  ///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
  /// ```
  ///
  /// Or: `flutter run --dart-define-from-file=dart_defines.json`
  /// (use [dart_defines.example.json] as a template; keep `dart_defines.json` gitignored).
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// When `true`, the app reads/writes `customers.customer_type` (`amc` | `one_time`).
  /// Default `true` so edits persist; if the column is missing, use:
  ///   `--dart-define=CUSTOMERS_HAS_CUSTOMER_TYPE=false`
  static const customersHasCustomerTypeColumn = bool.fromEnvironment(
    'CUSTOMERS_HAS_CUSTOMER_TYPE',
    defaultValue: true,
  );

  /// When `true`, the app reads/writes `customers.service_frequency_days` (int).
  /// Default `true` so edits persist; if the column is missing, use:
  ///   `--dart-define=CUSTOMERS_HAS_SERVICE_FREQUENCY_DAYS=false`
  static const customersHasServiceFrequencyDaysColumn = bool.fromEnvironment(
    'CUSTOMERS_HAS_SERVICE_FREQUENCY_DAYS',
    defaultValue: true,
  );

  /// When `true`, inserts/reads include `amount_charged` on **`service_history`**
  /// (visit rows). Catalog menu is `public.services` — do not confuse the two.
  /// Use `false` only if `service_history.amount_charged` does not exist:
  ///   `--dart-define=SERVICES_HAS_AMOUNT_CHARGED=false`
  static const servicesHasAmountChargedColumn = bool.fromEnvironment(
    'SERVICES_HAS_AMOUNT_CHARGED',
    defaultValue: true,
  );

  /// Supabase Storage bucket for per-visit voice notes (create in Dashboard → Storage).
  static const serviceRecordingsBucket = 'service-recordings';

  /// When `true`, inserts include `catalog_service_id` and `audio_storage_path` on `service_history`.
  /// Add columns via `supabase/migrations/...service_history_catalog_audio.sql`.
  static const serviceHistoryHasExtendedFields = bool.fromEnvironment(
    'SERVICE_HISTORY_EXTENDED',
    defaultValue: true,
  );

  static const appName = 'Service Reminder';
}
