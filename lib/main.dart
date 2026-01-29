import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PCOSApp());
}

class PCOSApp extends StatelessWidget {
  const PCOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PCOS App',
      home: const LoginScreen(),
    );
  }
}