import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showMovementDialog() {
    String selectedType = 'Walk';
    int selectedDuration = 15;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Log Movement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Movement type'),
                items: const [
                  DropdownMenuItem(value: 'Walk', child: Text('🚶 Walk')),
                  DropdownMenuItem(value: 'Yoga', child: Text('🧘 Yoga')),
                  DropdownMenuItem(value: 'Stretch', child: Text('🤸 Stretch')),
                  DropdownMenuItem(value: 'Workout', child: Text('🏋️ Workout')),
                ],
                onChanged: (value) => selectedType = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDuration,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 45, child: Text('45')),
                  DropdownMenuItem(value: 60, child: Text('60')),
                ],
                onChanged: (value) => selectedDuration = value!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: () {
                setState(() {
                  AppState.instance.logMovement(
                    type: selectedType,
                    duration: selectedDuration,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeMovement(int index) {
    setState(() {
      AppState.instance.removeMovement(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
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
                  Text(
                    '🔥 Streak: ${state.streak}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '⭐ Points: ${state.points}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TOP CARDS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showMovementDialog,
                    child: const _ActionCard(
                      title: 'Log Movement',
                      icon: Icons.add_circle,
                      gradient: [
                        Color(0xFF7F53AC),
                        Color(0xFF647DEE),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DailyLogCard(onRemove: _removeMovement),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _GoalsCard(onUpdate: () => setState(() {})),
            const SizedBox(height: 16),
            const _AchievementShelf(),
          ],
        ),
      ),
    );
  }
}

/* ---------- DAILY LOG CARD ---------- */

class _DailyLogCard extends StatelessWidget {
  final void Function(int index) onRemove;
  const _DailyLogCard({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final movements = AppState.instance.todayMovements;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: movements.isEmpty
          ? const Center(
              child: Text(
                'No movement yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final log = movements[index];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Movement Entry'),
                        content: Text(
                          '${log.type} • ${log.duration} min\n'
                          'Points: ${log.points}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onRemove(index);
                            },
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${log.type} • ${log.duration} min',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/* ---------- DAILY QUESTS (TOGGLEABLE) ---------- */

class _GoalsCard extends StatelessWidget {
  final VoidCallback onUpdate;
  const _GoalsCard({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Daily Quests',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...state.dailyQuests.map((quest) {
            final done = state.completedQuests.contains(quest);

            return ListTile(
              dense: true,
              leading: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? Colors.green : Colors.grey,
              ),
              title: Text(quest),
              trailing: done ? const Text('+10 ⭐') : null,
              onTap: () {
                state.toggleQuest(quest);
                onUpdate();
              },
            );
          }),
        ],
      ),
    );
  }
}

/* ---------- ACHIEVEMENT SHELF ---------- */

class _AchievementShelf extends StatelessWidget {
  const _AchievementShelf();

  @override
  Widget build(BuildContext context) {
    final achievements = AppState.instance.achievements;

    final allAchievements = [
      'First Movement',
      '5-day streak',
      'Hydration Pro',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Achievements',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: allAchievements.map((a) {
              final unlocked = achievements.contains(a);

              return Chip(
                label: Text(a),
                avatar: Icon(
                  unlocked ? Icons.star : Icons.lock,
                  size: 16,
                ),
                backgroundColor:
                    unlocked ? Colors.amber.shade200 : Colors.grey.shade300,
              );
            }).toList(),
          ),
        ],
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
