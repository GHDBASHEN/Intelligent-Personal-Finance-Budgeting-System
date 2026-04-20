import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/sources/remote/otp_service.dart';
import '../../data/repositories/repository_impls.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_provider.dart';
import 'currency_state_provider.dart';

class RegistrationState {
  final String username;
  final String email;
  final String password;
  final String selectedCurrency;
  final int currentStep;
  final bool isLoading;
  final String? error;

  RegistrationState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.selectedCurrency = 'USD',
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
  });

  RegistrationState copyWith({
    String? username,
    String? email,
    String? password,
    String? selectedCurrency,
    int? currentStep,
    bool? isLoading,
    String? error,
  }) {
    return RegistrationState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RegistrationNotifier extends ChangeNotifier {
  RegistrationState _state = RegistrationState();
  RegistrationState get state => _state;

  void _updateState(RegistrationState newState) {
    _state = newState;
    notifyListeners();
  }

  void updateUsername(String value) {
    _updateState(_state.copyWith(username: value));
  }

  void updateEmail(String value) {
    _updateState(_state.copyWith(email: value));
  }

  void updatePassword(String value) {
    _updateState(_state.copyWith(password: value));
  }

  void updateCurrency(String currency) {
    _updateState(_state.copyWith(selectedCurrency: currency));
  }

  Future<void> sendOTP(BuildContext context) async {
    if (_state.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    _updateState(_state.copyWith(isLoading: true, error: null));
    
    try {
      final result = await OTPService.sendOTP(_state.email);
      
      if (result['success'] == true) {
        _updateState(_state.copyWith(
          isLoading: false,
          currentStep: 1,
        ));
        
        if (context.mounted) {
          _showEmailSentDialog(context, _state.email, result['mockOtp']);
        }
      } else {
        _updateState(_state.copyWith(
          isLoading: false,
          error: result['error'] ?? 'Failed to send OTP',
        ));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to send OTP')),
          );
        }
      }
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: 'Error sending OTP: $e',
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending OTP: $e')),
        );
      }
    }
  }
  
  void _showEmailSentDialog(BuildContext context, String email, String? mockOtp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.green),
            SizedBox(width: 8),
            Text('Verification Email Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('A 6-digit verification code has been sent to'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ),
            if (mockOtp != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Development Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mock OTP: $mockOtp',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Please check your inbox (and spam folder)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> verifyOTP(String otp, BuildContext context) async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit verification code')),
      );
      return;
    }

    _updateState(_state.copyWith(isLoading: true, error: null));
    
    try {
      final isValid = OTPService.verifyOTP(otp);
      
      if (isValid) {
        _updateState(_state.copyWith(
          isLoading: false,
          currentStep: 2,
        ));
      } else {
        _updateState(_state.copyWith(
          isLoading: false,
          error: 'Invalid OTP. Please try again.',
        ));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid verification code. Please try again.')),
          );
        }
      }
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: 'Error verifying OTP: $e',
      ));
    }
  }

  Future<void> completeRegistration(BuildContext context, WidgetRef ref) async {
    if (_state.selectedCurrency.isEmpty) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: 'Please select a currency',
      ));
      return;
    }

    _updateState(_state.copyWith(isLoading: true, error: null));
    
    try {
      final authRepo = AuthRepositoryImpl();
      
      final emailExists = await authRepo.checkEmailExists(_state.email);
      if (emailExists) {
        _updateState(_state.copyWith(
          isLoading: false,
          error: 'Email already registered. Please login.',
        ));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already registered. Please login.')),
          );
          context.go('/login');
        }
        return;
      }
      
      final user = UserEntity(
        username: _state.username,
        email: _state.email,
        password: _state.password,
        defaultCurrency: _state.selectedCurrency,
      );
      
      final registeredUser = await authRepo.register(user);
      
      final currencyNotifier = ref.read(currencyStateProvider.notifier);
      await currencyNotifier.loadUserDefaultCurrency(registeredUser.id!);
      currencyNotifier.setTargetCurrency(_state.selectedCurrency);
      
      ref.read(authProvider.notifier).updateUser(registeredUser);
      
      _updateState(_state.copyWith(isLoading: false));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${_state.username}! Default currency: ${_state.selectedCurrency}'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  void reset() {
    _updateState(RegistrationState());
  }

  void goBack() {
    if (_state.currentStep > 0) {
      _updateState(_state.copyWith(
        currentStep: _state.currentStep - 1,
        error: null,
      ));
    }
  }
}

final registrationProvider = ChangeNotifierProvider<RegistrationNotifier>((ref) {
  return RegistrationNotifier();
});