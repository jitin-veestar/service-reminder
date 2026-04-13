import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repo;
  const VerifyOtpUseCase(this._repo);

  Future<void> call({required String phone, required String token}) =>
      _repo.verifyOtp(phone: phone, token: token);
}
