import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/dashboard_analytics_screen.dart';
import '../screens/dashboard/past_details_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/transactions/transaction_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/profile_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isLoggedIn = false;

  RouterNotifier(this._ref) {
    _ref.listen<AuthNotifier>(authProvider, (previous, next) {
      final isLoggedIn = next.state.user != null;
      if (_isLoggedIn != isLoggedIn) {
        _isLoggedIn = isLoggedIn;
        notifyListeners();
      }
    });
    _isLoggedIn = _ref.read(authProvider).state.user != null;
  }

  bool get isLoggedIn => _isLoggedIn;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
      final isAuthPath = state.uri.path == '/login' || 
                         state.uri.path == '/register' || 
                         state.uri.path == '/forgot-password';

      if (!isLoggedIn && !isAuthPath) return '/login';
      if (isLoggedIn && isAuthPath) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardAnalyticsScreen(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsListScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard/past-details',
        name: 'past-details',
        builder: (context, state) => const PastDetailsScreen(),
      ),
      GoRoute(
        path: '/transaction/add',
        name: 'add-transaction',
        builder: (context, state) => const TransactionFormScreen(),
      ),
    ],
  );
});