import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/dashboard_analytics_screen.dart';
import '../screens/dashboard/past_details_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/settings/settings_screen.dart';

// This class will notify GoRouter only when the login state changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(
      authProvider.select((state) => state.user != null),
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).user != null;
      final isAuthPath = state.uri.path == '/login' || state.uri.path == '/register' || state.uri.path == '/forgot-password';

      if (!isLoggedIn && !isAuthPath) return '/login';
      if (isLoggedIn && isAuthPath) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardAnalyticsScreen()),
          GoRoute(path: '/transactions', builder: (context, state) => const TransactionsListScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/dashboard/past-details', builder: (context, state) => const PastDetailsScreen()),
    ],
  );
});
