import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';

enum AlertType { success, error, info }

extension AlertTypeExt on AlertType {
  Color get color {
    switch (this) {
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.error:
        return const Color(0xFFEF4444);
      case AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  Color get bgColor {
    switch (this) {
      case AlertType.success:
        return const Color(0xFFF0FDF4);
      case AlertType.error:
        return const Color(0xFFFEF2F2);
      case AlertType.info:
        return const Color(0xFFF0F9FF);
    }
  }

  String get title {
    switch (this) {
      case AlertType.success:
        return 'Success';
      case AlertType.error:
        return 'Error';
      case AlertType.info:
        return 'Info';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.success:
        return Icons.check_circle;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.info:
        return Icons.info_outline;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'login';
  String _loginMethod = 'email';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.successMessage != null) {
        _showAlert(auth.successMessage!, AlertType.success);
        auth.clearMessages();
        if (_mode == 'signup') {
          setState(() => _mode = 'login');
          _clearSignupFields();
        }
      } else if (auth.errorMessage != null) {
        _showAlert(auth.errorMessage!, AlertType.error);
        auth.clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _clearFields() {
    _emailCtrl.clear();
    _passCtrl.clear();
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _otpCtrl.clear();
    _confirmPassCtrl.clear();
  }

  void _clearSignupFields() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _passCtrl.clear();
    _confirmPassCtrl.clear();
  }

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearMessages();

    if (_loginMethod == 'phone') {
      final success = await auth.requestOtp(_phoneCtrl.text);
      if (!mounted) return;
      if (success) {
        _showSnackbar('OTP sent to ${_phoneCtrl.text}', AlertType.success);
        setState(() => _mode = 'otp');
      } else {
        _showSnackbar(auth.errorMessage ?? 'Failed to send OTP', AlertType.error);
      }
      return;
    }

    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    if (success) {
      _showSnackbar('Login successful!', AlertType.success);
      auth.setRememberMe(_rememberMe);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      _showSnackbar(auth.errorMessage ?? 'Login failed', AlertType.error);
    }
  }

  Future<void> _handleSignup() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearMessages();

    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackbar('Please enter your full name', AlertType.error);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnackbar('Please enter your email', AlertType.error);
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnackbar('Please enter your phone number', AlertType.error);
      return;
    }
    if (_passCtrl.text.isEmpty) {
      _showSnackbar('Please enter a password', AlertType.error);
      return;
    }
    if (_confirmPassCtrl.text.isEmpty) {
      _showSnackbar('Please confirm your password', AlertType.error);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showSnackbar('Passwords do not match', AlertType.error);
      return;
    }

    final success = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnackbar('Welcome! Signup successful!', AlertType.success);
      _clearSignupFields();
      // Auto-navigate to home after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      _showSnackbar(auth.errorMessage ?? 'Signup failed', AlertType.error);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearMessages();

    final success = await auth.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
    if (!mounted) return;

    if (success) {
      _showSnackbar('OTP verified!', AlertType.success);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      _showSnackbar(auth.errorMessage ?? 'OTP verification failed', AlertType.error);
    }
  }

  void _handleGoogleLogin() {
    _showSnackbar('Google sign-in will be available soon', AlertType.info);
  }

  void _handleForgotPassword() {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnackbar('Please enter your email first', AlertType.error);
      return;
    }
    _showSnackbar('Password reset link sent to ${_emailCtrl.text}', AlertType.success);
    setState(() => _mode = 'login');
    _clearFields();
  }

  void _showAlert(String message, AlertType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: type.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(type.icon, color: type.color, size: 24),
            const SizedBox(width: 10),
            Text(type.title, style: TextStyle(color: type.color, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: TextStyle(color: type.color.withValues(alpha: 0.95))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: type.color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, AlertType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(type.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
        ),
        backgroundColor: type.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: type == AlertType.success ? 2 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Center(child: Text('🛒', style: TextStyle(fontSize: 34))),
                ),
                const SizedBox(height: 18),
                const Text('Insta Buddy Mart', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  _mode == 'login'
                      ? 'Welcome back!'
                      : _mode == 'signup'
                          ? 'Create your account'
                          : _mode == 'otp'
                              ? 'Verify your phone'
                              : 'Reset Password',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: _mode == 'otp' ? _buildOtpForm() : _mode == 'forgot' ? _buildForgotForm() : _buildMainForm(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Column(
        children: [
          if (_mode == 'login')
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _methodTab('email', '📧 Email'),
                  _methodTab('phone', '📱 Phone'),
                ],
              ),
            ),
          if (_mode == 'login') const SizedBox(height: 18),
          if (_mode == 'signup') ...[
            _input(_nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
          ],
          if (_loginMethod == 'email' || _mode == 'signup') ...[
            _input(_emailCtrl, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
          ],
          if (_mode == 'signup') ...[
            _input(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
          ],
          if (_loginMethod == 'email' || _mode == 'signup') ...[
            if (_mode == 'signup')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _input(
                    _passCtrl,
                    'Password',
                    Icons.lock_outline,
                    obscure: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Minimum 8 characters required', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              )
            else
              _input(
                _passCtrl,
                'Password',
                Icons.lock_outline,
                obscure: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (_mode == 'signup') ...[
            _input(
              _confirmPassCtrl,
              'Confirm Password',
              Icons.lock_outline,
              obscure: !_showConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_mode == 'login' && _loginMethod == 'phone') ...[
            _input(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
          ],
          if (_mode == 'login' && _loginMethod == 'email')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v!),
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Remember me', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _mode = 'forgot'),
                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          const SizedBox(height: 18),
          _gradientButton(
            auth.isLoading ? '⏳ Loading...' : (_mode == 'signup' ? 'Sign Up' : _loginMethod == 'phone' ? 'Send OTP' : 'Login'),
            auth.isLoading ? () {} : (_mode == 'signup' ? _handleSignup : _handleLogin),
          ),
          const SizedBox(height: 16),
          if (_mode == 'login')
            Row(children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
            ]),
          if (_mode == 'login') const SizedBox(height: 16),
          if (_mode == 'login') ...[
            _outlineButton('🔵  Continue with Google', _handleGoogleLogin),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: () {
              _mode == 'login' ? setState(() => _mode = 'signup') : setState(() => _mode = 'login');
              _clearFields();
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                children: [
                  TextSpan(text: _mode == 'login' ? "Don't have an account? " : 'Already have an account? '),
                  TextSpan(
                    text: _mode == 'login' ? 'Sign Up' : 'Login',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Column(
        children: [
          const Text('Enter the 4-digit code sent to your phone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          _input(_otpCtrl, 'Enter OTP', Icons.pin, keyboardType: TextInputType.number),
          const SizedBox(height: 18),
          _gradientButton(auth.isLoading ? '⏳ Verifying...' : 'Verify & Login', auth.isLoading ? () {} : _handleVerifyOtp),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _mode = 'login'),
            child: const Text('← Back to Login', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotForm() {
    return Column(
      children: [
        _input(_emailCtrl, 'Enter your email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 18),
        _gradientButton('Send Reset Link', _handleForgotPassword),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _mode = 'login'),
          child: const Text('← Back to Login', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _methodTab(String method, String label) {
    final active = _loginMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _loginMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false, Widget? suffixIcon, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
