import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // TOP SPACER
            const Spacer(),

            // CENTER CONTENT
            Column(
              children: const [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(
                    Icons.local_florist,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'PCOS Wellness',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your health journey starts here!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            // BOTTOM SPACER
            const Spacer(),

            // BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }
}
