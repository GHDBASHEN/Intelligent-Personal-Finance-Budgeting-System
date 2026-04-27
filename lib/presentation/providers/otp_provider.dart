import 'package:email_otp/email_otp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpState {
  final bool isLoading;
  final String? error;
  final bool isSent;
  final bool isVerified;

  OtpState({
    this.isLoading = false,
    this.error,
    this.isSent = false,
    this.isVerified = false,
  });

  OtpState copyWith({
    bool? isLoading,
    String? error,
    bool? isSent,
    bool? isVerified,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSent: isSent ?? this.isSent,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class OtpNotifier extends Notifier<OtpState> {
  @override
  OtpState build() {
    _initialize();
    return OtpState();
  }

  void _initialize() {
    final smtpEmail = dotenv.env['SMTP_EMAIL'] ?? '';
    final smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
    
    if (smtpEmail.isEmpty || smtpPassword.isEmpty) {
      print('⚠️ SMTP credentials not found in .env file. OTP will not work.');
    }
    
    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: smtpEmail,
      password: smtpPassword,
    );
    
    EmailOTP.config(
      appName: 'Finance System',
      otpType: OTPType.numeric,
      emailTheme: EmailTheme.v4,
      otpLength: 6,
    );
  }

  Future<bool> sendOtp(String email) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(error: 'Please enter your email address');
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null, isSent: false);
    try {
      final success = await EmailOTP.sendOTP(email: email);
      if (success) {
        state = state.copyWith(isLoading: false, isSent: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Unable to send verification code. Please check your email address and try again.');
        return false;
      }
    } catch (e) {
      String errorMessage = 'Failed to send verification code. ';
      if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check your internet.';
      } else {
        errorMessage += 'Please check your email address and try again.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  bool verifyOtp(String otp) {
    if (otp.length != 6) {
      state = state.copyWith(error: 'Please enter the 6-digit verification code');
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isVerified = EmailOTP.verifyOTP(otp: otp);
      if (isVerified) {
        state = state.copyWith(isLoading: false, isVerified: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid verification code. Please check and try again.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unable to verify code. Please try again.');
      return false;
    }
  }

  void reset() {
    state = OtpState();
  }
}

final otpProvider = NotifierProvider.autoDispose<OtpNotifier, OtpState>(
  OtpNotifier.new,
); 