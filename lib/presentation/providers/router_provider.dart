import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/auth/currency_selection_screen.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/dashboard_analytics_screen.dart';
import '../screens/dashboard/past_details_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../../domain/entities/user_entity.dart';


class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      final user = authState.user;
      
      final needsCurrency = isLoggedIn && (user?.preferredCurrency == null || user?.preferredCurrency?.isEmpty == true);
      
      final isAuthPath = state.uri.path == '/login' || 
                         state.uri.path == '/register' || 
                         state.uri.path == '/forgot-password' ||
                         state.uri.path == '/verify-otp';
      final isCurrencyPath = state.uri.path == '/currency-selection';
      
      if (!isLoggedIn && !isAuthPath) {
        return '/login';
      }
      
      if (isLoggedIn && isAuthPath) {
        if (needsCurrency) {
          return '/currency-selection';
        }
        return '/dashboard';
      }
      
      if (isLoggedIn && needsCurrency && !isCurrencyPath) {
        return '/currency-selection';
      }
      
      if (isLoggedIn && !needsCurrency && isCurrencyPath) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/verify-otp', 
        builder: (context, state) {
          final user = state.extra as UserEntity?;
          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return OtpVerificationScreen(user: user);
        },
      ),
      GoRoute(path: '/currency-selection', builder: (context, state) => const CurrencySelectionScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardAnalyticsScreen()),
          GoRoute(path: '/transactions', builder: (context, state) => const TransactionsListScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/dashboard/past-details', builder: (context, state) => const PastDetailsScreen()),
    ],
  );
});