import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class MindScreen extends StatefulWidget {
  const MindScreen({super.key});

  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> {
  void _showMoodDialog() {
    final moods = {
      'Happy': '😊',
      'Sad': '😔',
      'Angry': '😠',
      'Anxious': '😰',
      'Calm': '😌',
      'Tired': '😴',
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('How are you feeling today?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moods.entries.map((e) {
            return ListTile(
              leading: Text(e.value, style: const TextStyle(fontSize: 22)),
              title: Text(e.key),
              onTap: () {
                setState(() {
                  AppState.instance.logMood(e.key);
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // STREAK + POINTS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🔥 Streak: ${state.streak}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('⭐ Points: ${state.points}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DAILY AFFIRMATION
            const _SoftLargeCard(
              icon: Icons.favorite,
              title: 'Daily Affirmation',
              subtitle: 'A gentle reminder for today',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showMoodDialog,
                    child: _ActionCard(
                      title: state.todayMood == null
                          ? 'Log Mood'
                          : 'Mood: ${state.todayMood}',
                      icon: Icons.add_reaction,
                      gradient: const [
                        Color(0xFF9D50BB),
                        Color(0xFF6E48AA),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _ActionCard(
                    title: 'Gratitude Journal',
                    icon: Icons.add_circle_outline,
                    gradient: [
                      Color(0xFFB993D6),
                      Color(0xFF8CA6DB),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const _SoftLargeCard(
              icon: Icons.edit_note,
              title: 'Reflection / Notes',
              subtitle: 'Write freely and reflect',
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- ACTION CARD ---------- */

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- SOFT LARGE CARD ---------- */

class _SoftLargeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SoftLargeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurple.shade200,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700),
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
