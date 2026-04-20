import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/repositories.dart';
import 'infrastructure_providers.dart';
import 'currency_state_provider.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends ChangeNotifier {
  AuthState _state = AuthState(isLoading: true);
  AuthState get state => _state;

  final AuthRepository authRepo;
  final CurrencyNotifier currencyNotifier;

  AuthNotifier(this.authRepo, this.currencyNotifier) {
    _checkCurrentUser();
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        await currencyNotifier.loadUserDefaultCurrency(user.id!);
      }
      _updateState(AuthState(user: user, isLoading: false));
    } catch (e) {
      _updateState(AuthState(isLoading: false));
    }
  }

  void updateUser(UserEntity updatedUser) {
    _updateState(AuthState(user: updatedUser, isLoading: false));
  }

  Future<void> refreshUser() async {
    final user = await authRepo.getCurrentUser();
    _updateState(AuthState(user: user, isLoading: false));
    if (user != null) {
      await currencyNotifier.loadUserDefaultCurrency(user.id!);
    }
  }

  Future<void> login(String email, String password) async {
    _updateState(AuthState(isLoading: true));
    try {
      final user = await authRepo.login(email, password);
      if (user != null) {
        await currencyNotifier.loadUserDefaultCurrency(user.id!);
        _updateState(AuthState(user: user, isLoading: false));
      } else {
        _updateState(AuthState(isLoading: false, error: 'Invalid email or password'));
      }
    } catch (e) {
      _updateState(AuthState(isLoading: false, error: e.toString()));
    }
  }

  Future<void> register(String username, String email, String password, {String defaultCurrency = 'USD'}) async {
    _updateState(AuthState(isLoading: true));
    try {
      final user = await authRepo.register(
        UserEntity(
          username: username, 
          email: email, 
          password: password,
          defaultCurrency: defaultCurrency,
        ),
      );
      _updateState(AuthState(user: user, isLoading: false));
    } catch (e) {
      _updateState(AuthState(isLoading: false, error: e.toString()));
    }
  }

  Future<void> logout() async {
    await authRepo.logout();
    _updateState(AuthState());
  }

  Future<void> forgotPassword(String email) async {
    _updateState(AuthState(isLoading: true));
    try {
      await authRepo.forgotPassword(email);
      _updateState(AuthState(isLoading: false));
    } catch (e) {
      _updateState(AuthState(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    _updateState(AuthState(isLoading: true));
    try {
      final exists = await authRepo.checkEmailExists(email);
      _updateState(AuthState(isLoading: false));
      return exists;
    } catch (e) {
      _updateState(AuthState(isLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<void> updatePassword(String email, String newPassword) async {
    _updateState(AuthState(isLoading: true));
    try {
      await authRepo.updatePassword(email, newPassword);
      _updateState(AuthState(isLoading: false));
    } catch (e) {
      _updateState(AuthState(isLoading: false, error: e.toString()));
      rethrow;
    }
  }
}

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final currencyNotifier = ref.read(currencyStateProvider.notifier);
  return AuthNotifier(authRepo, currencyNotifier);
});