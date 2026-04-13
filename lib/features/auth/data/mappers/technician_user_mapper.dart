import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_reminder/features/auth/data/dtos/technician_user_dto.dart';
import 'package:service_reminder/features/auth/domain/entities/technician_user.dart';

abstract final class TechnicianUserMapper {
  static TechnicianUser? fromSupabaseUser(User? user) {
    if (user == null) return null;
    return TechnicianUserDto.fromSupabaseUser(user).toDomain();
  }
}
