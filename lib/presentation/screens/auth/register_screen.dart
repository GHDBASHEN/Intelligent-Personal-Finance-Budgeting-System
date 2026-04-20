// lib/presentation/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../presentation/providers/registration_provider.dart';
import '../../../presentation/providers/currency_state_provider.dart';
import '../../widgets/custom_app_bar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      ref.read(registrationProvider.notifier).updateUsername(_usernameController.text);
    });
    _emailController.addListener(() {
      ref.read(registrationProvider.notifier).updateEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      ref.read(registrationProvider.notifier).updatePassword(_passwordController.text);
    });
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final currencyState = ref.watch(currencyStateProvider);
    
    // Available currencies with fallback
    List<String> availableCurrencies = ['USD', 'EUR', 'GBP', 'LKR', 'INR', 'CAD', 'AUD', 'JPY', 'CNY'];
    
    if (currencyState.rates.isNotEmpty && currencyState.rates.keys.length > 1) {
      availableCurrencies = currencyState.rates.keys.toList()..sort();
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Account',
        actions: regState.currentStep > 0
            ? [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ref.read(registrationProvider.notifier).goBack();
                    if (regState.currentStep == 1) {
                      _otpController.clear();
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStepIndicator(regState.currentStep),
                      const SizedBox(height: 24),
                      _buildCurrentStep(
                        regState,
                        availableCurrencies,
                        context,
                      ),
                      const SizedBox(height: 24),
                      if (regState.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            regState.error!,
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (regState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: [
        Expanded(child: _buildStepCircle(0, currentStep, 'Details', Icons.person_outline)),
        Expanded(child: _buildStepCircle(1, currentStep, 'Verify', Icons.verified_user_outlined)),
        Expanded(child: _buildStepCircle(2, currentStep, 'Currency', Icons.currency_exchange)),
      ],
    );
  }

  Widget _buildStepCircle(int step, int currentStep, String label, IconData icon) {
    final isActive = step <= currentStep;
    final isCurrent = step == currentStep;
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.orange : Colors.grey.shade200,
            border: isCurrent ? Border.all(color: Colors.orange, width: 3) : null,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade500,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(
    RegistrationState regState,
    List<String> currencies,
    BuildContext context,
  ) {
    switch (regState.currentStep) {
      case 0:
        return _buildDetailsStep(regState, context);
      case 1:
        return _buildOTPStep(regState, context);
      case 2:
        return _buildCurrencyStep(regState, currencies, context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDetailsStep(RegistrationState regState, BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.account_circle,
          size: 80,
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Fill in your details to get started',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person_outline, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password (min 6 characters)',
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: () {
            if (_usernameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter username')),
              );
              return;
            }
            if (_emailController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter email')),
              );
              return;
            }
            if (_passwordController.text.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password must be at least 6 characters')),
              );
              return;
            }
            ref.read(registrationProvider.notifier).sendOTP(context);
          },
          child: const Text(
            'Send Verification Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPStep(RegistrationState regState, BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.verified_user,
          size: 80,
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit verification code sent to',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            regState.email,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Pinput(
          length: 6,
          controller: _otpController,
          onCompleted: (pin) {
            ref.read(registrationProvider.notifier).verifyOTP(pin, context);
          },
          defaultPinTheme: PinTheme(
            width: 55,
            height: 55,
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ref.read(registrationProvider.notifier).verifyOTP(_otpController.text, context);
          },
          child: const Text(
            'Verify Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive the code? "),
            TextButton(
              onPressed: () {
                _otpController.clear();
                ref.read(registrationProvider.notifier).sendOTP(context);
              },
              child: const Text(
                'Resend Code',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyStep(
    RegistrationState regState,
    List<String> currencies,
    BuildContext context,
  ) {
    return Column(
      children: [
        const Icon(
          Icons.currency_exchange,
          size: 80,
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Select Default Currency',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred currency for all transactions',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: regState.selectedCurrency,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 32),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              dropdownColor: Colors.white,
              items: currencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        _getCurrencyFlag(currency),
                        const SizedBox(width: 12),
                        Text(
                          currency,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(registrationProvider.notifier).updateCurrency(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can change your currency anytime in Settings',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(registrationProvider.notifier).goBack();
                  _otpController.clear();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.orange),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.orange, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref.read(registrationProvider.notifier).completeRegistration(context, ref);
                },
                child: const Text(
                  'Complete Registration',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getCurrencyFlag(String currency) {
    switch (currency) {
      case 'USD': return const Text('🇺🇸', style: TextStyle(fontSize: 24));
      case 'EUR': return const Text('🇪🇺', style: TextStyle(fontSize: 24));
      case 'GBP': return const Text('🇬🇧', style: TextStyle(fontSize: 24));
      case 'LKR': return const Text('🇱🇰', style: TextStyle(fontSize: 24));
      case 'INR': return const Text('🇮🇳', style: TextStyle(fontSize: 24));
      case 'CAD': return const Text('🇨🇦', style: TextStyle(fontSize: 24));
      case 'AUD': return const Text('🇦🇺', style: TextStyle(fontSize: 24));
      case 'JPY': return const Text('🇯🇵', style: TextStyle(fontSize: 24));
      case 'CNY': return const Text('🇨🇳', style: TextStyle(fontSize: 24));
      default: return const Text('🌍', style: TextStyle(fontSize: 24));
    }
  }
}