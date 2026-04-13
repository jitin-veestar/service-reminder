import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<void> call({required String email, required String password}) =>
      _repository.signUp(email: email, password: password);
}
