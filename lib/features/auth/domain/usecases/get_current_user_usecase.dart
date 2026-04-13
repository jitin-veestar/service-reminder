import 'package:service_reminder/features/auth/domain/entities/technician_user.dart';
import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  TechnicianUser? call() => _repository.currentUser;
}
