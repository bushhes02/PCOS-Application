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
        title: Text('Log ${mealType.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: e.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '${e.key} (g)'),
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
            child: const Text('Reset Meal', style: TextStyle(color: Colors.red)),
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

  Widget _mealSection(String title, MealType type) {
    final state = AppState.instance;
    final entries = state.mealsToday[type]!;
    final score = state.calculateMealScore(type);
    final points = state.calculateMealPoints(type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showMealDialog(type),
              ),
            ],
          ),

          if (entries.isEmpty)
            const Text('No entries yet')
          else ...[
            ...entries.entries.map(
              (e) => Text('${e.key} • ${e.value}g'),
            ),
            const SizedBox(height: 6),
            Text(
              'Rating: $score / 3  •  +$points points',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
      appBar: AppBar(title: const Text('Meals')),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

            Expanded(
              child: Row(
                children: [
                  // Water bar
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: state.waterGlasses / 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text('${state.waterGlasses}/8'),
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
                        _mealSection('Breakfast', MealType.breakfast),
                        const SizedBox(height: 12),
                        _mealSection('Lunch', MealType.lunch),
                        const SizedBox(height: 12),
                        _mealSection('Dinner', MealType.dinner),
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