import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appState = AppState.instance;

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BIG AVATAR / PROGRESS SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.purple.shade300,
                      child: const Icon(Icons.person, size: 60),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      user?.displayName ?? 'Welcome',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '🔥 ${appState.streak}-day streak',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATS ROW
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Points',
                      value: appState.points.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatCard(title: 'Badges', value: '6'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ACHIEVEMENTS
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _AchievementCard(title: '7-day streak'),
                    _AchievementCard(title: 'First log'),
                    _AchievementCard(title: 'Hydration goal'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // WEEKLY HIGHLIGHTS
              const Text(
                'This Week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              const _HighlightCard(text: 'Logged movement 4 times'),
              const _HighlightCard(text: 'Improved food score'),
              const _HighlightCard(text: 'Completed 2 mindfulness sessions'),

              const SizedBox(height: 24),

              // SETTINGS
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),

              const SizedBox(height: 8),

              // SIGN OUT
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  const _AchievementCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String text;
  const _HighlightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}
