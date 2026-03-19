import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

const _bg   = Color(0xFFFFF7F2);
const _pink = Color(0xFFF4826A);
const _ink  = Color(0xFF1E1610);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await AppState.initForUser();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with that email.';
      case 'wrong-password':    return 'Incorrect password — try again.';
      case 'invalid-email':     return 'That doesn\'t look like a valid email.';
      case 'too-many-requests': return 'Too many attempts. Please wait a moment.';
      default:                  return 'Something went wrong. Please try again.';
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

                const Text('Welcome back!',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: _ink, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Log in to continue your journey',
                    style: TextStyle(
                        fontSize: 14, color: _ink.withOpacity(0.45))),

                const SizedBox(height: 32),

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

                // ── Log in button ──────────────────────────
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
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Log In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Switch to sign up ──────────────────────
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14, color: _ink.withOpacity(0.45)),
                      children: [
                        const TextSpan(text: 'Don\'t have an account? '),
                        const TextSpan(
                          text: 'Sign Up',
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
