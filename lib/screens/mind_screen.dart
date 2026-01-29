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
        title: const Text('How are you feeling today?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moods.entries.map((e) {
            return ListTile(
              title: Text('${e.value}  ${e.key}'),
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
      appBar: AppBar(title: const Text('Mind')),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Streak + Points
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Streak: ${state.streak} 🔥'),
                  Text('Points: ${state.points} ⭐'),
                ],
              ),
            ),

            _LargeCard(title: 'Daily Affirmation'),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showMoodDialog,
                    child: _Card(
                      title: state.todayMood == null
                          ? 'Mood Tracker'
                          : 'Mood: ${state.todayMood}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Card(title: 'Gratitude Journal'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _LargeCard(title: 'Reflection / Notes'),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  const _Card({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LargeCard extends StatelessWidget {
  final String title;
  const _LargeCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}