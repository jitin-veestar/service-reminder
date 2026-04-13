import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository _repo;
  const SendOtpUseCase(this._repo);

  Future<void> call({required String phone}) =>
      _repo.sendOtp(phone: phone);
}
