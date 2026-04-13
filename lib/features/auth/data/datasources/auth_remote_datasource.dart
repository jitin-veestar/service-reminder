abstract interface class AuthRemoteDataSource {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();

  /// Sends a 6-digit OTP SMS to [phone] (E.164 format, e.g. +919876543210).
  Future<void> sendOtp({required String phone});

  /// Verifies the [token] received via SMS for [phone].
  Future<void> verifyOtp({required String phone, required String token});
}
