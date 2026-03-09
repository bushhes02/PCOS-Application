import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'signup_screen.dart';

// ─────────────────────────────────────────────────────────
//  Shared colour tokens
// ─────────────────────────────────────────────────────────
const _bg       = Color(0xFFFFF7F2);
const _pink     = Color(0xFFF4826A);
const _ink      = Color(0xFF1E1610);

// ─────────────────────────────────────────────────────────
//  WelcomeScreen  →  5 s splash  →  Polly intro
// ─────────────────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showPolly = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();

    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _showPolly = true);
        _ctrl.forward();
      });
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: FadeTransition(
      opacity: _fade,
      child: _showPolly ? const _PollyIntroScreen() : const _SplashScreen(),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  Splash  (5 s logo screen)
// ─────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Logo placeholder ── swap with Image.asset('assets/logo.png')
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: _pink.withOpacity(0.08),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _pink.withOpacity(0.25), width: 2),
          ),
          child: const Center(
            child: Text('🌸', style: TextStyle(fontSize: 56)),
          ),
        ),
        const SizedBox(height: 28),
        const Text('Ovarrior',
            style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w900,
              color: _ink, letterSpacing: -1.5, height: 1)),
        const SizedBox(height: 10),
        Text('Your PCOS wellness companion',
            style: TextStyle(
              fontSize: 14, letterSpacing: 0.3,
              color: _ink.withOpacity(0.4))),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  Polly intro screen
// ─────────────────────────────────────────────────────────
class _PollyIntroScreen extends StatelessWidget {
  const _PollyIntroScreen();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const Spacer(flex: 3),

        // Duck + speech bubble
        Column(children: [
          // Speech bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _pink.withOpacity(0.2)),
              boxShadow: [BoxShadow(
                color: _pink.withOpacity(0.1),
                blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              Text('Hey there! I\'m Polly! 👋',
                  style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, color: _ink),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Welcome to the Cysterhood 💜\n\n'
                'I\'ll be cheering you on every step of your wellness journey. Let\'s do this together!',
                style: TextStyle(
                  fontSize: 14, color: _ink.withOpacity(0.55), height: 1.65),
                textAlign: TextAlign.center),
            ]),
          ),

          // Bubble tail pointing down toward duck
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(24, 12),
              painter: _TailPainter(),
            ),
          ),

          // Polly
          Image.asset(
            'assets/images/polly.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
        ]),

        const Spacer(flex: 2),

        // CTA buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: const Text('Join the Cysterhood',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: _ink.withOpacity(0.45)),
              children: [
                const TextSpan(text: 'Already a member? '),
                TextSpan(
                  text: 'Log in',
                  style: const TextStyle(
                    color: _pink, fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: _pink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    ),
  );
}

// Small downward-pointing triangle under the speech bubble
class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill   = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = _pink.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }
  @override
  bool shouldRepaint(_) => false;
}
