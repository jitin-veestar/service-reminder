import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/app/app.dart';
import 'package:service_reminder/app/di/provider_observers.dart';
import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/core/services/notifications/notification_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConstants.hasSupabaseConfig) {
    runApp(const _MissingSupabaseConfigApp());
    return;
  }

  await initializeDateFormatting('en');
  await initializeDateFormatting('hi');

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialise local notifications (timezone setup + plugin init).
  // Permission is requested separately after the user is signed in.
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const App(),
    ),
  );
}

/// Shown when the app is run without `SUPABASE_URL` / `SUPABASE_ANON_KEY` dart-defines.
class _MissingSupabaseConfigApp extends StatelessWidget {
  const _MissingSupabaseConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  'Supabase is not configured.\n\n'
                  'Build or run with:\n'
                  '  --dart-define=SUPABASE_URL=https://….supabase.co\n'
                  '  --dart-define=SUPABASE_ANON_KEY=…\n\n'
                  'Or copy dart_defines.example.json to dart_defines.json '
                  '(gitignored) and run:\n'
                  '  flutter run --dart-define-from-file=dart_defines.json',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
