import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void debug(String message, {Object? error}) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) debugPrint('[DEBUG] Error: $error');
    }
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message, {Object? error}) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
      if (error != null) debugPrint('[WARN] Error: $error');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('[ERROR] Details: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrint('[ERROR] Stack: $stackTrace');
    }
  }
}
