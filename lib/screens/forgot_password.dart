import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openzippers/screens/reset_password.dart';

import '../providers/forgot_password_provider.dart';


class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _resetLinkSent = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    // FIX 2 ── hide green success text as soon as the email field is cleared
    _emailController.addListener(() {
      if (_resetLinkSent && _emailController.text.trim().isEmpty) {
        setState(() => _resetLinkSent = false);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(forgotPasswordProvider.notifier)
          .sendResetLink(_emailController.text.trim());
    }
  }

  void _onBackToLogin() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    ref.listen(forgotPasswordProvider, (_, next) {
      if (next.status == FPStatus.success) {
        setState(() => _resetLinkSent = true);  // shows green text
        ref.read(forgotPasswordProvider.notifier).reset();
      } else if (next.status == FPStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(forgotPasswordProvider.notifier).reset();
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
                _buildLogo(),
                const SizedBox(height: 48),
                _buildCard(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() =>
      Image.asset('assets/images/logo.png', width: 80, height: 80);

  Widget _buildCard(FPState state) {
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
              'Forgot Password',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot your password? No problem. Just let us know your email '
                  'address and we will email you a password reset link that will '
                  'allow you to choose a new one.',
              style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),

            // ── FIX 2: Green text — only visible when _resetLinkSent = true
            //    AND email field is non-empty (listener above clears the flag) ──
            if (_resetLinkSent)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'We have emailed your password reset link.',
                  style: TextStyle(color: Color(0xFF3FCB82), fontSize: 14),
                ),
              ),

            // ── Email label ────────────────────────────────────────────────
            const Text(
              'Email',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // ── Email field ────────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              cursorColor: const Color(0xFFDB2777),
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: const TextStyle(color: _inputHint, fontSize: 14),
                filled: true,
                fillColor: _inputBg,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  borderSide:
                  const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFFDB2777), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'The email field is required.';
                }
                final emailRegex =
                RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Bottom row ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _onBackToLogin,
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildButton(state),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(FPState state) {
    return Container(
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
        state.status == FPStatus.loading ? null : _onSendResetLink,
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
        child: state.status == FPStatus.loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : const Text(
          'Send Reset Link',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}