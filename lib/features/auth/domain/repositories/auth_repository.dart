import 'package:service_reminder/features/auth/domain/entities/technician_user.dart';

abstract interface class AuthRepository {
  TechnicianUser? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> sendOtp({required String phone});
  Future<void> verifyOtp({required String phone, required String token});
}
