import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  void _showMealDialog(MealType mealType) {
    final existing = AppState.instance.mealsToday[mealType]!;

    final controllers = {
      'Carbs': TextEditingController(text: existing['Carbs']?.toString() ?? ''),
      'Protein': TextEditingController(text: existing['Protein']?.toString() ?? ''),
      'Fats': TextEditingController(text: existing['Fats']?.toString() ?? ''),
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log ${mealType.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: e.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${e.key} (g)',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                AppState.instance.resetMeal(mealType);
              });
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final Map<String, int> macros = {};
              controllers.forEach((k, c) {
                final v = int.tryParse(c.text);
                if (v != null && v > 0) macros[k] = v;
              });

              setState(() {
                AppState.instance.saveMeal(
                  mealType: mealType,
                  macros: macros,
                );
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(String title, MealType type, List<Color> gradient) {
    final state = AppState.instance;
    final entries = state.mealsToday[type]!;
    final score = state.calculateMealScore(type);
    final points = state.calculateMealPoints(type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.white),
                onPressed: () => _showMealDialog(type),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (entries.isEmpty)
            const Text(
              'Tap + to log your meal',
              style: TextStyle(color: Colors.white70),
            )
          else ...[
            ...entries.entries.map(
              (e) => Text(
                '${e.key} • ${e.value}g',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⭐ Rating: $score / 3  •  +$points pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
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

            Expanded(
              child: Row(
                children: [
                  // WATER BAR
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: state.waterGlasses / 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${state.waterGlasses}/8 💧'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(state.addWaterGlass),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => setState(state.removeWaterGlass),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      children: [
                        _mealCard(
                          'Breakfast',
                          MealType.breakfast,
                          const [Color(0xFFF7971E), Color(0xFFFFD200)],
                        ),
                        const SizedBox(height: 12),
                        _mealCard(
                          'Lunch',
                          MealType.lunch,
                          const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                        ),
                        const SizedBox(height: 12),
                        _mealCard(
                          'Dinner',
                          MealType.dinner,
                          const [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                        ),
                      ],
                    ),
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
