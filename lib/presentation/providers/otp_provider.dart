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
    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: dotenv.env['SMTP_EMAIL'] ?? '',
      password: dotenv.env['SMTP_PASSWORD'] ?? '',
    );
    
    EmailOTP.config(
      appName: 'Finance System',
      otpType: OTPType.numeric,
      emailTheme: EmailTheme.v4,
      otpLength: 6,
    );
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null, isSent: false);
    try {
      final success = await EmailOTP.sendOTP(email: email);
      if (success) {
        state = state.copyWith(isLoading: false, isSent: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  bool verifyOtp(String otp) {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isVerified = EmailOTP.verifyOTP(otp: otp);
      if (isVerified) {
        state = state.copyWith(isLoading: false, isVerified: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid OTP');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
