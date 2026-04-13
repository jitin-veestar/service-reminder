import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/core/errors/failure.dart';

abstract final class FailureMapper {
  static Failure fromException(Object error) {
    return switch (error) {
      supabase.AuthException() => AuthFailure(error.message),
      supabase.PostgrestException() => DatabaseFailure(_postgrestMessage(error)),
      NetworkException() => NetworkFailure(error.message),
      DatabaseException() => DatabaseFailure(error.message),
      NotFoundException() => NotFoundFailure(error.message),
      AppException() => UnknownFailure(error.message),
      _ => const UnknownFailure(),
    };
  }

  static String _postgrestMessage(supabase.PostgrestException e) {
    return switch (e.code) {
      '23505' => 'A record with this information already exists.',
      '23503' => 'Referenced record not found.',
      '42501' => 'Permission denied.',
      _ => e.message,
    };
  }
}
