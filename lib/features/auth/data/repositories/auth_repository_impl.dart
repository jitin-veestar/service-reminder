import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_reminder/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:service_reminder/features/auth/data/mappers/technician_user_mapper.dart';
import 'package:service_reminder/features/auth/domain/entities/technician_user.dart';
import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final SupabaseClient _client;

  const AuthRepositoryImpl(this._dataSource, this._client);

  @override
  TechnicianUser? get currentUser =>
      TechnicianUserMapper.fromSupabaseUser(_client.auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _dataSource.signIn(email: email, password: password);

  @override
  Future<void> signUp({required String email, required String password}) =>
      _dataSource.signUp(email: email, password: password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> sendOtp({required String phone}) =>
      _dataSource.sendOtp(phone: phone);

  @override
  Future<void> verifyOtp({required String phone, required String token}) =>
      _dataSource.verifyOtp(phone: phone, token: token);
}
