import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reset_password_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// Email & token extracted from the deep link:
  /// e.g. https://openzippers.com/reset-password?token=abc123&email=user@gmail.com
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _passwordController        = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordObscure = true;
  bool _confirmObscure  = true;

  // ── Design tokens (identical to ForgotPasswordScreen) ──────────────────────
  static const Color _bgColor       = Color(0xFF0D1B2A);
  static const Color _cardColor     = Color(0xFF1C2B3A);
  static const Color _cardBorder    = Color(0xFF2A3D52);
  static const Color _textPrimary   = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0C4D8);
  static const Color _inputBg      = Color(0xFF243447);
  static const Color _inputBorder  = Color(0xFF2E4460);
  static const Color _inputHint    = Color(0xFF607A94);
  static const Color _btnGradStart = Color(0xFFE040FB);
  static const Color _btnGradEnd   = Color(0xFF7B2FFF);
  static const Color _accentPink   = Color(0xFFDB2777);

  @override
  void initState() {
    super.initState();
    // Pre-fill email from deep link — read only
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(resetPasswordProvider.notifier).resetPassword(
        email: widget.email,
        token: widget.token,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);

    ref.listen(resetPasswordProvider, (_, next) {
      if (next.status == RPStatus.success) {
        ref.read(resetPasswordProvider.notifier).reset();
        // Go back to login
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Password reset successfully.'),
            backgroundColor: const Color(0xFF3FCB82),
          ),
        );
      } else if (next.status == RPStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Failed to reset password.'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(resetPasswordProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo — same asset as splash screen ───────────────────
                Image.asset('assets/images/logo.png', width: 80, height: 80),
                const SizedBox(height: 48),
                _buildCard(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(RPState state) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────────
            const Text(
              'Reset Password',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your new password below to complete the reset.',
              style: TextStyle(
                  color: _textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),

            // ── Email (read-only, pre-filled from deep link) ───────────────
            _label('Email'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: _decoration(hint: ''),
            ),
            const SizedBox(height: 20),

            // ── Password ───────────────────────────────────────────────────
            _label('Password'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: _passwordObscure,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              cursorColor: _accentPink,
              decoration: _decoration(
                hint: 'Enter new password',
                suffixIcon: _eyeToggle(
                  obscure: _passwordObscure,
                  onTap: () =>
                      setState(() => _passwordObscure = !_passwordObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required.';
                if (v.length < 8) return 'Minimum 8 characters.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Confirm Password ───────────────────────────────────────────
            _label('Confirm Password'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _confirmObscure,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              cursorColor: _accentPink,
              decoration: _decoration(
                hint: 'Confirm new password',
                suffixIcon: _eyeToggle(
                  obscure: _confirmObscure,
                  onTap: () =>
                      setState(() => _confirmObscure = !_confirmObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password.';
                if (v != _passwordController.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Reset Password button — right aligned, matches screenshot ──
            Align(
              alignment: Alignment.centerRight,
              child: _buildButton(state),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: _textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  );

  InputDecoration _decoration({required String hint, Widget? suffixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _inputHint, fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accentPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accentPink, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accentPink, width: 1.5),
        ),
      );

  Widget _eyeToggle({required bool obscure, required VoidCallback onTap}) =>
      IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _inputHint,
          size: 20,
        ),
        onPressed: onTap,
      );

  Widget _buildButton(RPState state) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_btnGradStart, _btnGradEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: _btnGradEnd.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed:
      state.status == RPStatus.loading ? null : _onResetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: state.status == RPStatus.loading
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2),
      )
          : const Text(
        'Reset Password',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}