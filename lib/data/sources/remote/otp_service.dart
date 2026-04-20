class OTPService {
  static String? _generatedOtp;
  static DateTime? _otpExpiry;
  
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      print('Sending OTP to: $email');
      
      _generatedOtp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      _otpExpiry = DateTime.now().add(const Duration(minutes: 5));
      
      print('✅ Generated OTP: $_generatedOtp');
      
      return {
        'success': true,
        'message': 'OTP generated successfully',
        'mockOtp': _generatedOtp,
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }
  
  static bool verifyOTP(String otp) {
    try {
      if (_generatedOtp == null) {
        print('❌ No OTP generated');
        return false;
      }
      
      if (_otpExpiry != null && DateTime.now().isAfter(_otpExpiry!)) {
        print('❌ OTP expired');
        _generatedOtp = null;
        _otpExpiry = null;
        return false;
      }
      
      final isValid = otp == _generatedOtp;
      
      if (isValid) {
        print('✅ OTP verified!');
        _generatedOtp = null;
        _otpExpiry = null;
      } else {
        print('❌ Invalid OTP: $otp');
      }
      
      return isValid;
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }
  
  static void clearOTP() {
    _generatedOtp = null;
    _otpExpiry = null;
  }
}