import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PCOSApp());
}

class PCOSApp extends StatelessWidget {
  const PCOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeState.instance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ovarrior',
        theme:     lightTheme(),
        darkTheme:  darkTheme(),
        themeMode: ThemeState.instance.isDark ? ThemeMode.dark : ThemeMode.light,
        home: const WelcomeScreen(),
      ),
    );
  }
}
