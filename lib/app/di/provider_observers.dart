import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_reminder/core/logging/app_logger.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode && newValue is AsyncError) {
      AppLogger.error(
        'Provider error [${provider.name ?? provider.runtimeType}]',
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
    }
  }
}
