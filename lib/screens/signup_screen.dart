import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'avatar_screen.dart';

const _bg   = Color(0xFFFFF7F2);
const _pink = Color(0xFFF4826A);
const _ink  = Color(0xFF1E1610);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure      = true;
  bool _loading      = false;
  bool _agreedToTerms = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Terms & Conditions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _termSection('Not Medical Advice',
                      'Ovarrior is a wellness and lifestyle tracking application. '
                      'The content, features, and information provided within this app — '
                      'including insights, suggestions, and tracking tools — are for '
                      'general informational and motivational purposes only. '
                      'Nothing in this app constitutes medical advice, diagnosis, or treatment.'),
                  _termSection('Consult a Professional',
                      'Always consult a qualified healthcare provider before making '
                      'changes to your diet, exercise routine, or any aspect of your '
                      'health management. This is especially important if you have '
                      'been diagnosed with PCOS or any other medical condition.'),
                  _termSection('No Guarantees',
                      'Ovarrior does not guarantee any specific health outcomes. '
                      'Individual results vary. The app is intended to support '
                      'healthy habits, not to replace clinical care.'),
                  _termSection('Your Data',
                      'Your lifestyle logs and progress data are stored securely '
                      'using Firebase and are used solely to personalise your '
                      'in-app experience. We do not sell or share your data '
                      'with third parties.'),
                  _termSection('Use at Your Own Discretion',
                      'By using Ovarrior, you acknowledge that you have read and '
                      'understood these terms and agree to use the app responsibly '
                      'and in conjunction with professional healthcare guidance '
                      'where appropriate.'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _termSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        Text(body,
            style: TextStyle(
                fontSize: 13, color: _ink.withOpacity(0.6), height: 1.6)),
      ]),
    );
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'Please agree to the Terms & Conditions to continue.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await AppState.initForUser();
      if (!mounted) return;
      // Navigate to avatar selection before home
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AvatarScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That doesn\'t look like a valid email.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Logo ──────────────────────────────────
                Image.asset(
                  'assets/images/logo.png',
                  width: 160,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 28),

                const Text('Create your account',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: _ink, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Start your wellness journey today',
                    style: TextStyle(
                        fontSize: 14, color: _ink.withOpacity(0.45))),

                const SizedBox(height: 32),

                // ── Name ───────────────────────────────────
                _AuthField(
                  controller: _nameCtrl,
                  hint: 'Name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),

                // ── Email ──────────────────────────────────
                _AuthField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // ── Password ───────────────────────────────
                _AuthField(
                  controller: _passwordCtrl,
                  hint: 'Password',
                  obscure: _obscure,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20, color: _ink.withOpacity(0.35)),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Terms & Conditions checkbox ────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: _pink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 13, color: _ink.withOpacity(0.6)),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: _pink,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: _pink),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTerms,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Error ──────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100)),
                    child: Text(_error!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.red.shade600)),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Sign up button ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _pink.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Sign Up',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Switch to log in ───────────────────────
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14, color: _ink.withOpacity(0.45)),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        const TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: _pink,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _pink),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared text field ─────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _ink.withOpacity(0.1)),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: _ink.withOpacity(0.3)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 16),
        border: InputBorder.none,
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(),
      ),
    ),
  );
}
