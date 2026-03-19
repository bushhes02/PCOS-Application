import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealAnalyzerPage extends StatefulWidget {
  const MealAnalyzerPage({Key? key}) : super(key: key);
  @override
  State<MealAnalyzerPage> createState() => _MealAnalyzerPageState();
}

class _MealAnalyzerPageState extends State<MealAnalyzerPage> {
  final List<Map<String, dynamic>> _mealItems = [];
  final _gramsController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _selectedFood;
  int _autocompleteKey = 0;  // NEW: Key to force autocomplete rebuild

  // UPDATED: Expanded food list with 148 foods
  final List<String> _availableFoods = [
    // === GRAINS & STARCHES ===
    'white rice cooked',
    'brown rice cooked',
    'basmati rice cooked',
    'jasmine rice cooked',
    'wild rice cooked',
    'red rice cooked',
    'white pasta cooked',
    'whole wheat pasta cooked',
    'quinoa cooked',
    'oats cooked',
    'steel cut oats cooked',
    'white bread',
    'whole wheat bread',
    'sourdough bread',
    'rye bread',
    'pita bread white',
    'naan bread',
    'tortilla flour',
    'bagel plain',
    'english muffin',
    'cornmeal cooked',
    'couscous cooked',
    'bulgur cooked',
    'barley cooked',
    'millet cooked',
    'sweet potato baked',
    'white potato baked',
    'french fries',
    'mashed potato',
    'potato chips',
    
    // === PROTEINS ===
    'chicken breast cooked',
    'chicken thigh cooked',
    'turkey breast cooked',
    'beef lean cooked',
    'pork chop cooked',
    'lamb cooked',
    'bacon cooked',
    'salmon cooked',
    'tuna cooked',
    'cod cooked',
    'shrimp cooked',
    'prawns cooked',
    'crab cooked',
    'tilapia cooked',
    'sardines canned',
    'eggs boiled',
    'eggs scrambled',
    'egg white cooked',
    'tofu firm',
    'tempeh',
    'seitan',
    
    // === LEGUMES ===
    'chickpeas cooked',
    'black beans cooked',
    'kidney beans cooked',
    'lentils cooked',
    'red lentils cooked',
    'split peas cooked',
    'edamame cooked',
    
    // === NUTS & SEEDS ===
    'peanuts roasted',
    'almonds',
    'walnuts',
    'cashews',
    'pistachios',
    'sunflower seeds',
    'pumpkin seeds',
    'chia seeds',
    'flax seeds',
    'sesame seeds',
    
    // === VEGETABLES ===
    'broccoli cooked',
    'cauliflower cooked',
    'spinach cooked',
    'kale cooked',
    'cabbage cooked',
    'brussels sprouts cooked',
    'carrots cooked',
    'green beans cooked',
    'asparagus cooked',
    'bell pepper cooked',
    'zucchini cooked',
    'eggplant cooked',
    'tomato cooked',
    'cucumber raw',
    'lettuce raw',
    'celery raw',
    'onion cooked',
    'garlic raw',
    'mushroom cooked',
    'beetroot cooked',
    'pumpkin cooked',
    'sweet corn cooked',
    'peas cooked',
    
    // === FRUITS ===
    'avocado raw',
    'apple raw',
    'banana raw',
    'orange raw',
    'strawberries raw',
    'blueberries raw',
    'grapes raw',
    'watermelon raw',
    'mango raw',
    'pineapple raw',
    'kiwi raw',
    'pear raw',
    'peach raw',
    'plum raw',
    'cherries raw',
    'grapefruit raw',
    'papaya raw',
    'cantaloupe raw',
    'berries mixed',
    'dates dried',
    'raisins',
    
    // === DAIRY & ALTERNATIVES ===
    'milk whole',
    'milk skim',
    'yogurt plain',
    'yogurt greek',
    'cheese cheddar',
    'cheese mozzarella',
    'cottage cheese',
    'cream cheese',
    'butter',
    'ice cream vanilla',
    'soy milk',
    'almond milk',
    'coconut milk',
    'rice milk',
    
    // === PREPARED FOODS ===
    'pizza cheese',
    'burger beef',
    'hot dog',
    'sandwich turkey',
    'taco',
    'burrito bean',
    'sushi roll',
    'pasta carbonara',
    'lasagna',
    'mac and cheese',
    'fried rice',
    'stir fry vegetables',
    'soup vegetable',
    'hummus',
    'salsa',
    'guacamole',
    'peanut butter',
    'honey',
    'maple syrup',
    'jam strawberry',
    'chocolate dark',
    'chocolate milk',
  ];

  void _addFood() {
    if (_selectedFood == null || _gramsController.text.isEmpty) return;
    final grams = int.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) return;
    setState(() {
      _mealItems.add({'food_name': _selectedFood!, 'grams': grams});
      _selectedFood = null;
      _gramsController.clear();
      _autocompleteKey++;  // Force autocomplete to rebuild and clear
    });
  }

  Future<void> _analyzeMeal() async {
    if (_mealItems.isEmpty) return;
    setState(() { _isLoading = true; _result = null; });
    try {
      final response = await http.post(
        Uri.parse('https://pcos-gl-api.onrender.com/analyze-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'meal_items': _mealItems}),
      );
      
      if (response.statusCode == 200) {
        setState(() { _result = jsonDecode(response.body); _isLoading = false; });
      } else if (response.statusCode == 400) {
        // Handle validation errors
        setState(() => _isLoading = false);
        final error = jsonDecode(response.body);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ Cannot Calculate GL'),
              content: Text(
                error['message'] ?? 'The formula works best with balanced meals under 80g protein. Try smaller portions!',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')));
    }
  }

  Color get _riskColor {
    final risk = _result?['risk_level'] ?? '';
    if (risk == 'High')   return Colors.red;
    if (risk == 'Medium') return const Color(0xFFF7971E);
    return const Color(0xFF4CAF7D);
  }

  Color get _riskBgColor {
    final risk = _result?['risk_level'] ?? '';
    if (risk == 'High')   return Colors.red.shade50;
    if (risk == 'Medium') return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F5E9);
  }

  String get _riskEmoji {
    final risk = _result?['risk_level'] ?? '';
    if (risk == 'High')   return '⚠️';
    if (risk == 'Medium') return '📊';
    return '✅';
  }

  @override
  void dispose() { 
    _gramsController.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('GL Analyzer', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Explainer chip ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100.withOpacity(0.4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.shade100)),
            child: Row(children: [
              const Text('🔬', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Add your meal items below and we\'ll calculate the Glycaemic Load (GL) and suggest lower-GL swaps. Note: this is an estimate.',
                style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade700, height: 1.4))),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Add food card ─────────────────────────────
          _SectionCard(
            title: 'Add Food',
            emoji: '🍽️',
            child: Column(children: [
              // FIXED: Autocomplete with key to force rebuild/clear
              Autocomplete<String>(
                key: ValueKey(_autocompleteKey),  // Forces rebuild when key changes
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _availableFoods.where((String food) {
                    return food.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedFood = selection;
                  });
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search food (e.g., "quinoa", "chicken")... 🔍',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() => _selectedFood = null);
                        }
                      },
                    ),
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  _capitalize(option),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              // Grams field + Add button
              Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Amount (grams)',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixText: 'g',
                        suffixStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addFood,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A5AE0), Color(0xFF8B7BE8)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF6A5AE0).withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Text('Add', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Current meal ──────────────────────────────
          if (_mealItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Current Meal',
              emoji: '📝',
              child: Column(children: [
                ...List.generate(_mealItems.length, (i) {
                  final item = _mealItems[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        const Text('•', style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_capitalize(item['food_name'] as String),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${item['grams']}g',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        )),
                        GestureDetector(
                          onTap: () => setState(() => _mealItems.removeAt(i)),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close, size: 14, color: Colors.red.shade400)),
                        ),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 4),

                // Analyse button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.deepPurple.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('🔬', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Text('Analyse GL',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ]),
                  ),
                ),
              ]),
            ),
          ],

          // ── Results ───────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 16),

            // GL score hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _riskBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _riskColor.withOpacity(0.25))),
              child: Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(_riskEmoji,
                      style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Meal GL Score',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.8, color: _riskColor)),
                  const SizedBox(height: 4),
                  Text('${_result!['meal_gl']}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                          color: _riskColor, height: 1)),
                  const SizedBox(height: 4),
                  Text(_result!['message'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
                ])),
              ]),
            ),

            // Risk pill
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _riskColor,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('${_result!['risk_level']} GL',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text('Low < 10  •  Medium 10–19  •  High ≥ 20',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),

            // Suggestions
            if (_result!['suggestions'] != null &&
                (_result!['suggestions'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Lower-GL Swaps',
                emoji: '💡',
                child: Column(
                  children: (_result!['suggestions'] as List).map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('↩', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(width: 6),
                          Text('Instead of ${_capitalize(suggestion['original_food'] as String)}:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                        ]),
                        const SizedBox(height: 8),
                        ...(suggestion['alternatives'] as List).map((alt) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF4CAF7D).withOpacity(0.3))),
                            child: Row(children: [
                              const Text('✓', style: TextStyle(fontSize: 13,
                                  color: Color(0xFF4CAF7D), fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_capitalize(alt['name'] as String),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF7D),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Text('↓${alt['improvement_percent']}% GL',
                                    style: const TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ]),
                          ),
                        )),
                        if ((_result!['suggestions'] as List).last != suggestion)
                          Divider(height: 16, color: Colors.grey.shade200),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s
      : s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

// ── Section Card ──────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title, emoji;
  final Widget child;
  const _SectionCard({required this.title, required this.emoji, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}
