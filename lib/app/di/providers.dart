// Core DI barrel — re-exports the providers that are needed app-wide.
// Feature-specific providers live inside their respective feature folders.

export 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
export 'package:service_reminder/app/router/app_router.dart' show goRouterProvider;
