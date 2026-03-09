import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/meals_screen.dart';
import '../screens/mind_screen.dart';
import '../screens/profile_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final screens = [
      const HomeScreen(),
      const MealsScreen(),
      const MindScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screens[index],
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, child) => child,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_run),
          label: 'Move',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Meals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.self_improvement),
          label: 'Mind',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
