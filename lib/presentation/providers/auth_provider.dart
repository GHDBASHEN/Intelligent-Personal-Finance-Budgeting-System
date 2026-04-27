import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import 'infrastructure_providers.dart';

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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkCurrentUser();
    return AuthState(isLoading: true);
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: null);
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter your email address');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter your password');
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password. Please try again.',
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> register(String username, String email, String password) async {
    if (username.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter a username');
      return;
    }
    if (username.length < 3) {
      state = state.copyWith(isLoading: false, error: 'Username must be at least 3 characters');
      return;
    }
    if (email.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter your email address');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(isLoading: false, error: 'Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter a password');
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: 'Password must be at least 6 characters');
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(
            UserEntity(
              username: username, 
              email: email, 
              password: password,
            ),
          );
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
      state = AuthState();
    } catch (e) {
      // Silent fail on logout error
      state = AuthState();
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter your email address');
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exists = await ref.read(authRepositoryProvider).checkEmailExists(email);
      state = state.copyWith(isLoading: false);
      return exists;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: null);
      return false;
    }
  }

  Future<void> updatePassword(String email, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).updatePassword(email, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? profileImageUrl,
    String? preferredCurrency,
    String? phoneNumber,
  }) async {
    try {
      if (state.user == null) throw Exception('Please login to update your profile');
      
      final updatedUser = state.user!.copyWith(
        username: username ?? state.user!.username,
        profileImageUrl: profileImageUrl ?? state.user!.profileImageUrl,
        preferredCurrency: preferredCurrency ?? state.user!.preferredCurrency,
        phoneNumber: phoneNumber ?? state.user!.phoneNumber,
      );
      
      final savedUser = await ref.read(authRepositoryProvider).updateUser(updatedUser);
      state = state.copyWith(user: savedUser, isLoading: false, error: null);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);