import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Welcome Back'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 64, color: Colors.orangeAccent),
                    const SizedBox(height: 24),
                    const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    if (authState.isLoading) const Center(child: CircularProgressIndicator()),
                    if (authState.error != null) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(authState.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () => ref.read(authProvider.notifier).login(emailController.text, passwordController.text),
                      child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Don\'t have an account? Register'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Account'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 64, color: Colors.orangeAccent),
                    const SizedBox(height: 24),
                    const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      )
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      )
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    if (authState.isLoading) const Center(child: CircularProgressIndicator()),
                    if (authState.error != null) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(authState.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () => ref.read(authProvider.notifier).register(
                        usernameController.text, emailController.text, passwordController.text
                      ),
                      child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password
  
  void _sendOTP() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    
    // Check if email exists (we show a warning but allow moving to OTP screen for demo if desired)
    final exists = await ref.read(authProvider.notifier).checkEmailExists(email);
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not found. Please register first or check spelling.')),
        );
      }
      // return; // We'll keep this commented for now so you can test the UI steps easily
    }
    
    try {
      // Configuration for REAL email sending via SMTP
      // This requires SMTP_EMAIL and SMTP_PASSWORD in your .env file
      final smtpEmail = dotenv.env['SMTP_EMAIL'];
      final smtpPass = dotenv.env['SMTP_PASSWORD'];
      
      if (smtpEmail == null || smtpPass == null || smtpEmail.isEmpty || smtpPass.isEmpty) {
        // Fallback for testing: if no credentials, we simulate sending but MUST show the OTP field
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification mode: Simulation. (No SMTP credentials found in .env)'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _currentStep = 1; // Transition to OTP step
          });
        }
        return;
      }

      EmailOTP.config(
        appName: "Finance Tracker",
        otpType: OTPType.numeric,
        expiry: 300000,
        otpLength: 6,
        appEmail: smtpEmail,
        emailTheme: EmailTheme.v1,
      );

      EmailOTP.setSMTP(
        host: 'smtp.gmail.com',
        emailPort: EmailPort.port587,
        secureType: SecureType.tls,
        username: smtpEmail,
        password: smtpPass,
      );

      bool res = await EmailOTP.sendOTP(email: email);
      
      if (res && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A 6-digit code has been sent to your Gmail!'), backgroundColor: Colors.green),
        );
        setState(() {
          _currentStep = 1; // Transition to OTP step
        });
      } else {
        throw Exception('Failed to send OTP. Please check your SMTP settings in .env');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _verifyOTP() {
    // If SMTP wasn't configured, we allow '123456' as a universal test code
    final smtpEmail = dotenv.env['SMTP_EMAIL'];
    bool isCorrect = false;
    
    if (smtpEmail == null || smtpEmail.isEmpty) {
      isCorrect = otpController.text.trim() == '123456';
    } else {
      isCorrect = EmailOTP.verifyOTP(otp: otpController.text.trim());
    }

    if (isCorrect) {
      setState(() {
        _currentStep = 2; // Transition to Password Reset step
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Code. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetPassword() async {
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;
    
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 6 characters required')));
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    
    await ref.read(authProvider.notifier).updatePassword(emailController.text.trim(), pass);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password Reset Successful!'), backgroundColor: Colors.green),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Authentication'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentStep == 0 ? Icons.mark_email_unread_outlined : (_currentStep == 1 ? Icons.pin : Icons.lock_reset),
                          size: 72,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentStep == 0 ? 'Reset Password' : (_currentStep == 1 ? 'Verify Code' : 'Update Password'),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentStep == 0 
                            ? 'Enter your email to receive a recovery code' 
                            : (_currentStep == 1 ? 'Enter the 6-digit code sent to your Gmail' : 'Enter a strong new password'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 32),
                        
                        if (_currentStep == 0)
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Gmail Address',
                              prefixIcon: const Icon(Icons.alternate_email),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          )
                        else if (_currentStep == 1)
                          Pinput(
                            length: 6,
                            controller: otpController,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            defaultPinTheme: PinTheme(
                              width: 48,
                              height: 52,
                              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.transparent),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 48,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orangeAccent, width: 2),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.verified_user_outlined),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 32),
                        
                        if (authState.isLoading)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _currentStep == 0 ? _sendOTP : (_currentStep == 1 ? _verifyOTP : _resetPassword),
                              child: Text(
                                _currentStep == 0 ? 'GET OTP' : (_currentStep == 1 ? 'VERIFY CODE' : 'RESET PASSWORD'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Login', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
