import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_reminder/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:service_reminder/core/errors/app_exception.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  const AuthRemoteDataSourceImpl(this._client);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      // Record last active timestamp so admin panel "Last seen" is accurate.
      await _client.auth.updateUser(
        UserAttributes(
          data: {'last_seen_at': DateTime.now().toUtc().toIso8601String()},
        ),
      );
    } on AuthException catch (e) {
      // Re-throw as Supabase AuthException so FailureMapper can handle it.
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw NetworkException(originalError: e);
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        // Seed user_metadata so admin panel sees plan/trial state immediately.
        data: {
          'plan': 'free',
          'subscription_status': 'trial',
          'trial_started_at': now,
          'last_seen_at': now,
        },
      );
      // Session is set by Supabase automatically when email confirmation is off.
      // GoRouter's _AuthChangeNotifier handles the redirect on auth state change.
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw NetworkException(originalError: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw NetworkException(originalError: e);
    }
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw NetworkException(originalError: e);
    }
  }

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (res.session == null) {
        throw const AuthException('Invalid or expired OTP. Please try again.');
      }
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw NetworkException(originalError: e);
    }
  }
}
