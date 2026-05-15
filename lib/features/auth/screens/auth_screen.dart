import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/aashraya_text_field.dart';
import '../../elder/screens/elder_dashboard.dart';
import '../../caretaker/screens/caretaker_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isRegister = true;

  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey    = GlobalKey<FormState>();

  final _nameCtrl      = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _regEmailCtrl  = TextEditingController();
  final _regPassCtrl   = TextEditingController();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl  = TextEditingController();

  bool _isLoading = false;
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    super.dispose();
  }

  bool get isElder => widget.role == AppConstants.roleElder;
  Color get roleColor => isElder ? AppColors.primary : AppColors.sage;
  String get roleEmoji => isElder ? '👴' : '👩‍⚕️';
  String get roleName => isElder ? 'Elder' : 'Caretaker';

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => isElder
            ? const ElderDashboard()
            : const CaretakerDashboard(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await _auth.register(
      name: _nameCtrl.text,
      email: _regEmailCtrl.text,
      phone: _phoneCtrl.text,
      password: _regPassCtrl.text,
      role: widget.role,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Account created! Please log in to continue. 🌸');
      setState(() => _isRegister = false);
      _loginEmailCtrl.text = _regEmailCtrl.text;
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await _auth.login(
      email: _loginEmailCtrl.text,
      password: _loginPassCtrl.text,
      expectedRole: widget.role,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      _showError(error);
    } else {
      _goToDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabSwitcher(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _isRegister
                    ? _buildRegisterForm()
                    : _buildLoginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.walnut),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(roleEmoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(roleName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor)),
              ],
            ),
          ),
          const Spacer(),
          Text('Aashraya',
              style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.walnut)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Create Account',
            isActive: _isRegister,
            activeColor: roleColor,
            onTap: () => setState(() => _isRegister = true),
          ),
          _TabButton(
            label: 'Sign In',
            isActive: !_isRegister,
            activeColor: roleColor,
            onTap: () => setState(() => _isRegister = false),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome to\n',
                  style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.walnut,
                      height: 1.3),
                ),
                TextSpan(
                  text: 'Aashraya 🏠',
                  style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text("Let's set up your account in a moment.",
              style: AppTextStyles.bodyMedium()),
          const SizedBox(height: 28),
          AashrayaTextField(
            label: 'Full Name',
            hint: 'e.g. Ramesh Kumar',
            controller: _nameCtrl,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter your name';
              if (v.trim().length < 2) return 'Name is too short';
              return null;
            },
          ),
          const SizedBox(height: 18),
          AashrayaTextField(
            label: 'Phone Number',
            hint: 'e.g. 9876543210',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter your phone number';
              if (v.trim().length < 10)
                return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 18),
          AashrayaTextField(
            label: 'Email Address',
            hint: 'e.g. ramesh@email.com',
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter your email';
              if (!v.contains('@') || !v.contains('.'))
                return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 18),
          AashrayaTextField(
            label: 'Password',
            hint: 'Minimum 6 characters',
            controller: _regPassCtrl,
            isPassword: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please enter a password';
              if (v.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: roleColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(roleEmoji,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Registering as $roleName',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: roleColor,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
              label: 'Create My Account', onTap: _handleRegister),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isRegister = false),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: roleColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome\n',
                  style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.walnut,
                      height: 1.3),
                ),
                TextSpan(
                  text: 'back 🌸',
                  style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text("We've missed you. Sign in to continue.",
              style: AppTextStyles.bodyMedium()),
          const SizedBox(height: 32),
          AashrayaTextField(
            label: 'Email Address',
            hint: 'e.g. ramesh@email.com',
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter your email';
              if (!v.contains('@'))
                return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 18),
          AashrayaTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _loginPassCtrl,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: _handleLogin,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textHint, size: 20),
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
              label: 'Sign In to Aashraya', onTap: _handleLogin),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isRegister = true),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'Create one',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: roleColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _isLoading
              ? roleColor.withOpacity(0.6)
              : roleColor == AppColors.primary
                  ? AppColors.walnut
                  : AppColors.sage,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.3)),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isActive
                        ? Colors.white
                        : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}