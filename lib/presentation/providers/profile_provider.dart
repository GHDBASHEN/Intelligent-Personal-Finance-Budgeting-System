// lib/presentation/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/repository_impls.dart';
import 'auth_provider.dart';

class ProfileState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isUpdating;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
  });

  ProfileState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isUpdating,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();

  @override
  ProfileState build() {
    // Load user data immediately
    _loadCurrentUser();
    return ProfileState(isLoading: true);
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = await _authRepo.getCurrentUser();
    state = state.copyWith(user: currentUser, isLoading: false);
    
    // Also update auth provider if needed
    if (currentUser != null) {
      ref.read(authProvider.notifier).updateUser(currentUser);
    }
  }

  // Add this method to refresh user data
  Future<void> refreshUser() async {
    final currentUser = await _authRepo.getCurrentUser();
    state = state.copyWith(user: currentUser);
    if (currentUser != null) {
      ref.read(authProvider.notifier).updateUser(currentUser);
    }
  }

  Future<void> updateProfile({
    required String username,
    String? profilePicturePath,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final currentUser = state.user;
      if (currentUser == null) throw Exception('User not found');
      
      final updatedUser = currentUser.copyWith(
        username: username,
        profilePicturePath: profilePicturePath ?? currentUser.profilePicturePath,
      );
      
      final savedUser = await _authRepo.updateUserProfile(updatedUser);
      
      // Update both providers
      ref.read(authProvider.notifier).updateUser(savedUser);
      state = state.copyWith(user: savedUser, isUpdating: false);
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final currentUser = state.user;
      if (currentUser == null) throw Exception('User not found');
      
      final isValid = await _authRepo.verifyUserPassword(currentUser.id!, currentPassword);
      
      if (!isValid) {
        throw Exception('Current password is incorrect');
      }
      
      await _authRepo.updateUserPassword(currentUser.id!, newPassword);
      state = state.copyWith(isUpdating: false);
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      rethrow;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);