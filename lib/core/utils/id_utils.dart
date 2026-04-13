// UUIDs are generated server-side by Supabase (gen_random_uuid()).
// This utility is kept for any client-side temporary IDs if ever needed.

abstract final class IdUtils {
  static String tempId() => 'tmp_${DateTime.now().millisecondsSinceEpoch}';
}
