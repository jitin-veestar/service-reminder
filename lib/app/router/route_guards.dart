import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_reminder/app/router/route_names.dart';

abstract final class RouteGuard {
  /// Called by GoRouter on every navigation. Returns a redirect path or null.
  static String? redirect(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthenticated = user != null;
    final location = state.matchedLocation;

    // Let the splash page handle its own redirect on first load.
    if (location == RouteNames.splash) return null;

    final isPublicAuth =
        location == RouteNames.login || location == RouteNames.signup;

    if (!isAuthenticated) {
      return isPublicAuth ? null : RouteNames.login;
    }

    // Suspension check — admin sets suspended_at in auth.users.user_metadata.
    final meta = user.userMetadata ?? {};
    if (meta['suspended_at'] != null) {
      // Keep suspended users on the suspended page; block all other routes.
      return location == RouteNames.suspended ? null : RouteNames.suspended;
    }

    // Non-suspended users must not reach the suspended page.
    if (location == RouteNames.suspended) return RouteNames.dashboard;

    // Authenticated users should not stay on auth screens.
    if (isPublicAuth) return RouteNames.dashboard;

    // List lives under the shell at /home/customers. Bare /customers or
    // /customers/ has no :id and would otherwise fail route matching.
    final path = state.uri.path;
    if (path == '/customers' || path == '/customers/') {
      return RouteNames.customers;
    }

    return null;
  }
}
