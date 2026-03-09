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

  final List<String> _availableFoods = [
    'white rice cooked',
    'brown rice cooked',
    'white pasta cooked',
    'quinoa cooked',
    'oats cooked',
    'white bread',
    'chicken breast cooked',
    'fish cooked',
    'eggs boiled',
    'chickpeas cooked',
    'tofu',
    'prawns cooked',
    'broccoli cooked',
    'spinach cooked',
    'cabbage cooked',
    'carrots cooked',
    'avocado raw',
    'plain yogurt',
  ];

  void _addFood() {
    if (_selectedFood == null || _gramsController.text.isEmpty) return;
    final grams = int.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) return;
    setState(() {
      _mealItems.add({'food_name': _selectedFood!, 'grams': grams});
      _selectedFood = null;
      _gramsController.clear();
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
  void dispose() { _gramsController.dispose(); super.dispose(); }

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
              // Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFood,
                    isExpanded: true,
                    hint: Text('What are we having today? 🍽️',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                    items: _availableFoods.map((food) => DropdownMenuItem(
                      value: food,
                      child: Text(_capitalize(food),
                          style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedFood = v),
                  ),
                ),
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
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Current meal items ────────────────────────
          if (_mealItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Chosen Meal:',
              emoji: '🍽️',
              child: Column(children: [
                ..._mealItems.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('${i + 1}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.deepPurple.shade400))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_capitalize(item['food_name'] as String),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('${item['grams']}g',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.deepPurple.shade600)),
                        ),
                        const SizedBox(width: 6),
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
