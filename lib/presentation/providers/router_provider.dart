import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/dashboard_analytics_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/receipt_scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isAuthPath = state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn && !isAuthPath) return '/login';
      if (isLoggedIn && isAuthPath) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardAnalyticsScreen()),
          GoRoute(path: '/transactions', builder: (context, state) => const TransactionsListScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/receipt-scan', builder: (context, state) => const ReceiptScanScreen()),
    ],
  );
});
