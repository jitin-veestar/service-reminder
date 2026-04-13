// Connectivity checking is handled at the Supabase layer for this MVP.
// This class is a placeholder for future offline-support work.

abstract final class ConnectivityService {
  static Future<bool> isConnected() async => true;
}
