import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appState = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO AVATAR / PROGRESS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: const Icon(Icons.person,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    user?.displayName ?? 'Welcome',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '🔥 ${appState.streak}-day streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // STATS
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Points',
                    value: appState.points.toString(),
                    icon: Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    title: 'Badges',
                    value: '6',
                    icon: Icons.emoji_events,
                  ),
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
                  _AchievementCard(title: '7-day streak', icon: '🔥'),
                  _AchievementCard(title: 'First log', icon: '✅'),
                  _AchievementCard(title: 'Hydration goal', icon: '💧'),
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

            const _HighlightCard(text: '🏃 Logged movement 4 times'),
            const _HighlightCard(text: '🥗 Improved food score'),
            const _HighlightCard(text: '🧘 Completed 2 mindfulness sessions'),

            const SizedBox(height: 24),

            // SETTINGS + SIGN OUT
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading:
                        const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- STAT CARD ---------- */

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(title),
        ],
      ),
    );
  }
}

/* ---------- ACHIEVEMENT ---------- */

class _AchievementCard extends StatelessWidget {
  final String title;
  final String icon;
  const _AchievementCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '$icon  $title',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/* ---------- HIGHLIGHT ---------- */

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
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}
