import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;
  String? _successMessage;
  late final Future<void> bootstrapFuture;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Convenience getters for user data
  String get userName => _userProfile?['full_name'] ?? _userProfile?['fullName'] ?? _userProfile?['name'] ?? 'User';
  String get userEmail => _userProfile?['email'] ?? '';
  String get userPhone => _userProfile?['phone'] ?? '';
  String get userLocation => _userProfile?['location'] ?? 'Sector 18, Noida';
  double get userRating => (_userProfile?['rating'] as num?)?.toDouble() ?? 4.8;
  double get walletBalance => (_userProfile?['wallet'] as num?)?.toDouble() ?? 2500;
  double get earnings => (_userProfile?['earnings'] as num?)?.toDouble() ?? 0;
  bool get isRunner => _userProfile?['isRunner'] == true || _userProfile?['role'] == 'runner';
  bool get kycCompleted => _userProfile?['kycCompleted'] == true || _userProfile?['kyc_verified'] == true;

  AuthProvider() {
    bootstrapFuture = _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    final token = prefs.getString('access_token');
    final savedProfile = prefs.getString('user_profile');

    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      if (savedProfile != null) {
        _userProfile = jsonDecode(savedProfile);
      }
      notifyListeners();
      await fetchProfile();
    }
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveProfileLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_userProfile != null) {
      await prefs.setString('user_profile', jsonEncode(_userProfile));
    }
  }

  // ── Login with Email + Password ────────────────────────────────
  Future<bool> login(String email, String password) async {
    // Validation
    if (email.trim().isEmpty) {
      setErrorMessage('Please enter your email');
      return false;
    }
    if (!email.contains('@')) {
      setErrorMessage('Please enter a valid email address');
      return false;
    }
    if (password.isEmpty) {
      setErrorMessage('Please enter your password');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.postRequest('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'] ?? data['token'];
        final user = data['user'];

        if (token != null && user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          _isAuthenticated = true;
          _userProfile = user;
          setSuccessMessage('Login successful!');
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 401) {
        setErrorMessage('Invalid email or password');
        return false;
      } else if (response.statusCode == 403) {
        setErrorMessage('Account has been deactivated');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setErrorMessage('Login failed. Please check your connection.');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Register New User ────────────────────────────────
  Future<bool> register(String fullName, String email, String phone, String password) async {
    // Validation
    if (fullName.trim().isEmpty) {
      setErrorMessage('Please enter your full name');
      return false;
    }
    if (email.trim().isEmpty) {
      setErrorMessage('Please enter your email');
      return false;
    }
    if (!email.contains('@')) {
      setErrorMessage('Please enter a valid email address');
      return false;
    }
    if (phone.trim().isEmpty) {
      setErrorMessage('Please enter your phone number');
      return false;
    }
    if (password.isEmpty) {
      setErrorMessage('Please enter a password');
      return false;
    }
    if (password.length < 8) {
      setErrorMessage('Password must be at least 8 characters');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.postRequest('/auth/register', {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'role': 'requester',
      });

      _isLoading = false;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final token = data['accessToken'];

        if (user != null && token != null) {
          // Auto-login: save user profile and token
          final prefs = await SharedPreferences.getInstance();
          
          await prefs.setString('access_token', token);
          
          _isAuthenticated = true;
          _userProfile = user;
          _rememberMe = true;
          await prefs.setBool('remember_me', true);
          await prefs.setString('user_profile', jsonEncode(user));
          
          setSuccessMessage('Welcome, ${user['full_name']}! Signup successful!');
          notifyListeners();
          return true;
        }

        // Fallback: if registration succeeded but token missing, login directly
        if (user != null) {
          final loginResponse = await _apiClient.postRequest('/auth/login', {
            'email': email.trim(),
            'password': password,
          });

          if (loginResponse.statusCode == 200) {
            final loginData = jsonDecode(loginResponse.body);
            final loginToken = loginData['accessToken'] ?? loginData['token'];
            final loginUser = loginData['user'] ?? user;

            if (loginToken != null && loginUser != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('access_token', loginToken);
              _isAuthenticated = true;
              _userProfile = loginUser;
              _rememberMe = true;
              await prefs.setBool('remember_me', true);
              await prefs.setString('user_profile', jsonEncode(loginUser));
              setSuccessMessage('Welcome, ${loginUser['full_name'] ?? loginUser['fullName'] ?? loginUser['name'] ?? 'User'}! Signup successful!');
              notifyListeners();
              return true;
            }
          }
        }
      }

      // Parse backend error and show precise reason
      String reason = 'Signup failed';
      try {
        final data = jsonDecode(response.body);
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          reason = error['message'] as String;
        } else if (data['message'] is String) {
          reason = data['message'] as String;
        }

        // Prefer field-level validation message when available
        if (error is Map && error['details'] is List && (error['details'] as List).isNotEmpty) {
          final firstDetail = (error['details'] as List).first;
          if (firstDetail is Map && firstDetail['message'] is String) {
            reason = firstDetail['message'] as String;
          }
        }
      } catch (_) {
        // Keep fallback reason if body is not JSON
      }

      if (response.statusCode == 409 && reason == 'Signup failed') {
        reason = 'Email or phone already registered';
      }

      setErrorMessage(reason);
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      setErrorMessage('Signup failed. Please check your connection or server status.');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Google Sign In ────────────────────────────────
  Future<bool> googleSignIn() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.postRequest('/auth/google-signin', {
        'token': 'google_token_placeholder',
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        final user = data['user'];
        if (token != null && user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          _isAuthenticated = true;
          _userProfile = user;
          setSuccessMessage('Login successful!');
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
    }
    setErrorMessage('Google sign in failed');
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Request OTP ────────────────────────────────
  Future<bool> requestOtp(String identifier) async {
    if (identifier.trim().isEmpty) {
      setErrorMessage('Please enter your phone number');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.postRequest('/auth/otp/request', {
        'identifier': identifier.trim(),
      });
      _isLoading = false;

      if (response.statusCode == 200) {
        setSuccessMessage('OTP sent successfully to $identifier');
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        setErrorMessage('Phone number not registered');
        return false;
      }
    } catch (e) {
      debugPrint('OTP request error: $e');
      setErrorMessage('Failed to send OTP. Please try again.');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Verify OTP ────────────────────────────────
  Future<bool> verifyOtp(String identifier, String code) async {
    if (code.trim().isEmpty) {
      setErrorMessage('Please enter the OTP');
      return false;
    }
    if (code.length != 4 || !RegExp(r'^\d+$').hasMatch(code)) {
      setErrorMessage('OTP must be 4 digits');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.postRequest('/auth/otp/verify', {
        'identifier': identifier.trim(),
        'code': code,
      });

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'] ?? data['token'];
        final user = data['user'];

        if (token != null && user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          _isAuthenticated = true;
          _userProfile = user;
          setSuccessMessage('OTP verified! Login successful.');
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 400) {
        setErrorMessage('Invalid or expired OTP');
        return false;
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
      setErrorMessage('OTP verification failed. Please try again.');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiClient.getRequest('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userProfile = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(_userProfile));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_profile');
    _isAuthenticated = false;
    _userProfile = null;
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    SharedPreferences.getInstance().then((p) => p.setBool('remember_me', value));
    notifyListeners();
  }

  // ── Update Profile ────────────────────────────────
  Future<bool> updateProfile(String fullName, {String? phone, String? email}) async {
    if (fullName.trim().isEmpty) {
      setErrorMessage('Full name cannot be empty');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.putRequest('/auth/me', {
        'fullName': fullName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.isNotEmpty) 'email': email.trim(),
      });

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];

        if (user != null) {
          _userProfile = user;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(user));
          setSuccessMessage('Profile updated successfully');
          notifyListeners();
          return true;
        }
      }

      String reason = 'Failed to update profile';
      try {
        final data = jsonDecode(response.body);
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          reason = error['message'] as String;
        } else if (data['message'] is String) {
          reason = data['message'] as String;
        }
      } catch (_) {}
      setErrorMessage(reason);
      return false;
    } catch (e) {
      debugPrint('Update profile error: $e');
      setErrorMessage('Failed to update profile');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Update Password ────────────────────────────────
  Future<bool> updatePassword(String currentPassword, String newPassword, String confirmPassword) async {
    // Validation
    if (currentPassword.isEmpty) {
      setErrorMessage('Please enter your current password');
      return false;
    }
    if (newPassword.isEmpty) {
      setErrorMessage('Please enter a new password');
      return false;
    }
    if (newPassword.length < 6) {
      setErrorMessage('Password must be at least 6 characters');
      return false;
    }
    if (newPassword != confirmPassword) {
      setErrorMessage('Passwords do not match');
      return false;
    }
    if (newPassword == currentPassword) {
      setErrorMessage('New password must be different from current password');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.postRequest('/auth/update-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      _isLoading = false;

      if (response.statusCode == 200) {
        setSuccessMessage('Password updated successfully!');
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        setErrorMessage('Current password is incorrect');
        return false;
      }
    } catch (e) {
      debugPrint('Password update error: $e');
      setErrorMessage('Failed to update password. Please try again.');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void setUserProfile(Map<String, dynamic> profile) {
    _isAuthenticated = true;
    _userProfile = profile;
    _saveProfileLocally();
    notifyListeners();
  }
}
