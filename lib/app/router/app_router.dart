import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/app/router/route_guards.dart';
import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/features/auth/presentation/pages/login_page.dart';
import 'package:service_reminder/features/auth/presentation/pages/signup_page.dart';
import 'package:service_reminder/features/auth/presentation/pages/splash_page.dart';
import 'package:service_reminder/features/auth/presentation/pages/suspended_page.dart';
import 'package:service_reminder/features/customers/presentation/pages/customer_detail_page.dart';
import 'package:service_reminder/features/customers/presentation/pages/customer_form_page.dart';
import 'package:service_reminder/features/customers/presentation/pages/customers_list_page.dart';
import 'package:service_reminder/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:service_reminder/features/assigned_services/presentation/pages/assign_service_form_page.dart';
import 'package:service_reminder/features/profile/presentation/pages/profile_page.dart';
import 'package:service_reminder/features/reminders/presentation/pages/reminders_page.dart';
import 'package:service_reminder/features/reports/presentation/pages/reports_page.dart';
import 'package:service_reminder/features/service_catalog/presentation/pages/service_offering_form_page.dart';
import 'package:service_reminder/features/service_catalog/presentation/pages/service_offerings_list_page.dart';
import 'package:service_reminder/features/services/presentation/pages/all_services_page.dart';
import 'package:service_reminder/features/services/presentation/pages/service_history_page.dart';
import 'package:service_reminder/features/services/presentation/pages/service_record_form_page.dart';
import 'package:service_reminder/l10n/app_localizations.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash, // splash redirects to dashboard after auth check
    refreshListenable: authNotifier,
    redirect: RouteGuard.redirect,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (_, __) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) {
          if (state.uri.path == '/home') {
            return RouteNames.dashboard;
          }
          return null;
        },
        routes: [
          ShellRoute(
            builder: (context, state, child) => _AppShell(child: child),
            routes: [
              GoRoute(
                path: 'dashboard',
                builder: (_, __) => const DashboardPage(),
              ),
              GoRoute(
                path: 'services',
                builder: (_, __) => const AllServicesPage(),
              ),
              GoRoute(
                path: 'reminders',
                builder: (_, __) => const RemindersPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      // ── Pages pushed from Account (no bottom nav) ──────────────────────────
      GoRoute(
        path: RouteNames.customers,
        builder: (_, __) => const CustomersListPage(),
      ),
      GoRoute(
        path: RouteNames.reports,
        builder: (_, __) => const ReportsPage(),
      ),
      GoRoute(
        path: RouteNames.serviceOfferings,
        builder: (_, __) => const ServiceOfferingsListPage(),
      ),
      GoRoute(
        path: RouteNames.addCustomer,
        builder: (_, __) => const CustomerFormPage(),
      ),
      GoRoute(
        path: RouteNames.editCustomer,
        builder: (_, state) => CustomerFormPage(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.customerServiceHistory,
        builder: (_, state) => CustomerServiceHistoryPage(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.customerDetail,
        builder: (_, state) => CustomerDetailPage(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.addService,
        builder: (_, state) => ServiceRecordFormPage(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.assignService,
        builder: (_, __) => const AssignServiceFormPage(),
      ),
      GoRoute(
        path: RouteNames.addServiceOffering,
        builder: (_, __) => const ServiceOfferingFormPage(),
      ),
      GoRoute(
        path: RouteNames.editServiceOffering,
        builder: (_, state) => ServiceOfferingFormPage(
          offeringId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.suspended,
        builder: (_, __) => const SuspendedPage(),
      ),
    ],
  );
});

/// Notifies GoRouter whenever Supabase auth state changes so it re-evaluates
/// the [RouteGuard.redirect] callback.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Bottom navigation shell shared by the Dashboard, Customers and Reminders tabs.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.dashboard);
            case 1:
              context.go(RouteNames.allServices);
            case 2:
              context.go(RouteNames.profile);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: l10n.services,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: const Icon(Icons.account_circle),
            label: l10n.account,
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RouteNames.allServices)) return 1;
    if (path.startsWith(RouteNames.profile)) return 2;
    return 0;
  }
}
