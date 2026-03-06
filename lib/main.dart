import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();

  await Hive.openBox('userData');

  runApp(const PCOSApp());
}

class PCOSApp extends StatelessWidget {
  const PCOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PCOS App',
      home: const WelcomeScreen(),
    );
  }
}