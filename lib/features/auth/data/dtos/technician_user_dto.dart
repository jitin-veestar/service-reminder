import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_reminder/features/auth/domain/entities/technician_user.dart';

/// Maps a Supabase [User] to our domain [TechnicianUser].
class TechnicianUserDto {
  final String id;
  final String email;

  const TechnicianUserDto({required this.id, required this.email});

  factory TechnicianUserDto.fromSupabaseUser(User user) {
    return TechnicianUserDto(
      id: user.id,
      email: user.email ?? '',
    );
  }

  TechnicianUser toDomain() => TechnicianUser(id: id, email: email);
}
