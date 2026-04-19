import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _email;
  String? _phone;
  String? _userRole; // 'requester' or 'runner' - can be both in this app
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get email => _email;
  String? get phone => _phone;
  String? get userRole => _userRole;
  Map<String, dynamic> get userProfile => {
    'id': _userId,
    'fullName': _userName,
    'email': _email,
    'phone': _phone,
    'role': _userRole,
  };

  // OTP verification
  Future<bool> sendOTP(String phoneOrEmail, {bool isEmail = false}) async {
    try {
      // TODO: Integrate with backend OTP service (Twilio/AWS SNS)
      debugPrint('OTP would be sent to: $phoneOrEmail');
      // For now, simulate OTP sent
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneOrEmail, String otp, {bool isEmail = false}) async {
    try {
      // TODO: Verify OTP with backend
      debugPrint('Verifying OTP: $otp for $phoneOrEmail');
      
      // Mock verification - in real app, validate with backend
      if (otp.length == 4) {
        // Successful verification
        _isAuthenticated = true;
        _userId = 'user_${phoneOrEmail.hashCode}';
        _phone = isEmail ? null : phoneOrEmail;
        _email = isEmail ? phoneOrEmail : null;
        _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        // Default name - user can update in profile
        _userName = _phone ?? _email ?? 'User';
        _userRole = 'both'; // Can be requester and runner
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  void updateProfile(String name, {String? phone, String? email}) {
    _userName = name;
    if (phone != null) _phone = phone;
    if (email != null) _email = email;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _userName = null;
    _email = null;
    _phone = null;
    _authToken = null;
    notifyListeners();
  }
}
