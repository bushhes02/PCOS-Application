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
          title: const Text('Log Movement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'Walk', child: Text('Walk')),
                  DropdownMenuItem(value: 'Yoga', child: Text('Yoga')),
                  DropdownMenuItem(value: 'Stretch', child: Text('Stretch')),
                  DropdownMenuItem(value: 'Workout', child: Text('Workout')),
                ],
                onChanged: (value) => selectedType = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDuration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 45, child: Text('45 minutes')),
                  DropdownMenuItem(value: 60, child: Text('60 minutes')),
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
      appBar: AppBar(title: const Text('Movement')),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Streak + points
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

            // Top cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showMovementDialog,
                    child: const _Card(title: 'Log Today’s Movement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DailyLogCard(
                    onRemove: _removeMovement,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const _LargeCard(title: 'Quests / Challenges'),
            const SizedBox(height: 16),
            const _LargeCard(title: 'Achievement Shelf'),
          ],
        ),
      ),
    );
  }
}

class _DailyLogCard extends StatelessWidget {
  final void Function(int index) onRemove;
  const _DailyLogCard({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final movements = AppState.instance.todayMovements;

    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: movements.isEmpty
          ? const Center(
              child: Text(
                'No movement logged yet',
                textAlign: TextAlign.center,
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
                            child: const Text('Cancel'),
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
                    child: Text(
                      '${log.type} • ${log.duration} min',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
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
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(title, textAlign: TextAlign.center),
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
        child: Text(title, textAlign: TextAlign.center),
      ),
    );
  }
}