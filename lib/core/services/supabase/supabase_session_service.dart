import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase auth for convenient access to session state.
class SupabaseSessionService {
  final SupabaseClient _client;

  const SupabaseSessionService(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Throws [StateError] if called when no user is signed in.
  String get currentUserId {
    final user = currentUser;
    if (user == null) throw StateError('No authenticated user.');
    return user.id;
  }
}
