import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/xp_popup.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import 'meal_analyzer_page.dart';
import 'meal_nutrients.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> with TickerProviderStateMixin {
  final state = AppState.instance;
  late AnimationController _waterController;
  late Animation<double> _waterAnimation;

  @override
  void initState() {
    super.initState();
    final fill = state.waterGlasses / 8.0;
    _waterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waterAnimation = Tween<double>(begin: fill, end: fill)
        .animate(CurvedAnimation(parent: _waterController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _waterController.dispose();
    super.dispose();
  }

  void _animateWaterTo(double newFill) {
    _waterAnimation = Tween<double>(
      begin: _waterAnimation.value,
      end: newFill,
    ).animate(CurvedAnimation(parent: _waterController, curve: Curves.easeOutCubic));
    _waterController
      ..reset()
      ..forward();
  }

  void _openMealDetail(MealType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealDetailSheet(
        mealType: type,
        onChanged: () => setState(() {}),
      ),
    );
  }

  // ── Weekly tracker helpers ─────────────────────────────
  // Returns Monday of the current week
  DateTime _weekStart() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  // Count main meals logged on a past day from history
  int _mainMealsLoggedOn(String dateKey) {
    final history = state.mealDayHistory;
    if (!history.containsKey(dateKey)) return 0;
    final meals = history[dateKey]!;
    int count = 0;
    for (final type in ['breakfast', 'lunch', 'dinner']) {
      if (meals.containsKey(type) && meals[type]!.isNotEmpty) count++;
    }
    return count;
  }

  // Count today's meals from live AppState (not yet in history)
  int _mainMealsLoggedToday() {
    int count = 0;
    if (state.mealItems[MealType.breakfast]!.isNotEmpty) count++;
    if (state.mealItems[MealType.lunch]!.isNotEmpty) count++;
    if (state.mealItems[MealType.dinner]!.isNotEmpty) count++;
    return count;
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: OvColors.coral,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _appBarBadge('🔥', '${state.streak}'),
          _appBarBadge('⭐', '${state.points}', rightMargin: 14),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWaterCard(),
              const SizedBox(height: 12),
              _buildMealCard(MealType.breakfast, '🌅', 'Breakfast',
                  const Color(0xFFF7971E), const Color(0xFFFFF3E0)),
              const SizedBox(height: 8),
              _buildMealCard(MealType.lunch, '☀️', 'Lunch',
                  const Color(0xFF2F80ED), const Color(0xFFE3F2FD)),
              const SizedBox(height: 8),
              _buildMealCard(MealType.dinner, '🌙', 'Dinner',
                  const Color(0xFF9D50BB), const Color(0xFFF3E5F5)),
              const SizedBox(height: 4),
              Center(
                child: Text('Tap a card to log  •  +2 XP per meal',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ),
              const SizedBox(height: 12),
              _buildWeeklyTrackerCard(),
              const SizedBox(height: 12),
              _buildAnalyseButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar badge ──────────────────────────────────────
  Widget _appBarBadge(String emoji, String value, {double rightMargin = 6}) {
    return Container(
      margin: EdgeInsets.only(right: rightMargin, top: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4))),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 5),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white)),
      ]),
    );
  }

  // ── Water Card ─────────────────────────────────────────
  Widget _buildWaterCard() {
    final glasses = state.waterGlasses;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text("Let's Hydrate!",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$glasses / 8',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: OvColors.sky)),
        ]),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _waterAnimation,
          builder: (_, __) {
            final animFill = _waterAnimation.value;
            return LayoutBuilder(builder: (ctx, constraints) {
              final width = constraints.maxWidth;
              const height = 48.0;
              return GestureDetector(
                onTap: () {
                  if (glasses < 8) {
                    setState(() => state.addWaterGlass());
                    _animateWaterTo(state.waterGlasses / 8.0);
                    if (state.waterGlasses == 8) {
                      XpPopup.show(context, '+1 XP ⭐', color: OvColors.sky);
                    } else {
                      XpPopup.show(context, '+1 XP ⭐');
                    }
                  }
                },
                child: Stack(children: [
                  Container(
                    width: width, height: height,
                    decoration: BoxDecoration(
                        color: OvColors.skyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: OvColors.sky.withOpacity(0.5), width: 1.5)),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: width * animFill, height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [OvColors.sky.withOpacity(0.7), OvColors.sky],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                    ),
                  ),
                  if (animFill > 0.01 && animFill < 0.99)
                    Positioned(
                      left: (width * animFill) - 14, top: 0, bottom: 0,
                      child: Container(
                        width: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.35),
                              Colors.transparent
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight)),
                      ),
                    ),
                  ...List.generate(7, (i) {
                    final x = width * (i + 1) / 8;
                    return Positioned(
                      left: x - 0.5, top: 8, bottom: 8,
                      child: Container(
                        width: 1,
                        color: (i + 1) <= glasses
                            ? Colors.white.withOpacity(0.45)
                            : OvColors.sky.withOpacity(0.35)),
                    );
                  }),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        glasses == 0 ? 'Tap to log' : '$glasses of 8 glasses',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: animFill > 0.35 ? Colors.white : OvColors.sky),
                      ),
                    ),
                  ),
                ]),
              );
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(8, (i) {
            final filled = i < glasses;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (!filled) {
                    state.addWaterGlass();
                    _animateWaterTo(state.waterGlasses / 8.0);
                    if (state.waterGlasses == 8) {
                      XpPopup.show(context, '+1 XP ⭐', color: OvColors.sky);
                    } else {
                      XpPopup.show(context, '+1 XP ⭐');
                    }
                  } else if (i == glasses - 1) {
                    state.removeWaterGlass();
                    _animateWaterTo(state.waterGlasses / 8.0);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: filled ? OvColors.sky : OvColors.skyLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: filled
                          ? OvColors.sky
                          : OvColors.sky.withOpacity(0.5),
                      width: 1.5)),
                child: Center(
                  child: Text('💧',
                      style: TextStyle(
                        fontSize: filled ? 11 : 9,
                        color:
                            filled ? null : OvColors.sky.withOpacity(0.5))),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text('Tap a bubble to add or remove  •  +1 XP per glass',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ]),
    );
  }

  // ── Horizontal Meal Card ───────────────────────────────
  Widget _buildMealCard(
      MealType type, String emoji, String label, Color color, Color bg) {
    final items  = state.mealItems[type]!;
    final logged = items.isNotEmpty;

    return GestureDetector(
      onTap: () => _openMealDetail(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: logged ? bg : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: logged ? color.withOpacity(0.4) : Colors.grey.shade200,
            width: logged ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: logged
                  ? color.withOpacity(0.07)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // Emoji badge
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: logged
                  ? color.withOpacity(0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          // Label + preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: logged ? color : Colors.grey.shade500)),
                const SizedBox(height: 3),
                logged
                    ? Text(
                        items.map((f) => f.name).join(', '),
                        style: TextStyle(
                            fontSize: 11,
                            color: color.withOpacity(0.8),
                            height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text('Tap to log',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Count badge or add icon
          logged
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('${items.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)))
              : Icon(Icons.add_circle_outline,
                  color: Colors.grey.shade300, size: 22),
        ]),
      ),
    );
  }

  // ── Weekly Meal Tracker Card ───────────────────────────
  Widget _buildWeeklyTrackerCard() {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final monday  = _weekStart();
    const labels  = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: OvColors.coral.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9)),
            child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 15)))),
          const SizedBox(width: 9),
          const Text("This Week's Meals",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day      = monday.add(Duration(days: i));
            final isToday  = day == today;
            final isFuture = day.isAfter(today);
            final dateKey  =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

            final count = isToday
                ? _mainMealsLoggedToday()
                : isFuture
                    ? 0
                    : _mainMealsLoggedOn(dateKey);

            // 0 → empty, 1 → 1/3, 2 → 2/3, 3 → full
            final fraction = count == 0
                ? 0.0
                : count == 1
                    ? 1 / 3
                    : count == 2
                        ? 2 / 3
                        : 1.0;

            return Column(children: [
              // Outer coral ring for today
              Container(
                width: 38, height: 38,
                decoration: isToday
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: OvColors.coral, width: 2))
                    : null,
                child: Padding(
                  padding:
                      isToday ? const EdgeInsets.all(3) : EdgeInsets.zero,
                  child: CustomPaint(
                    painter: _MealArcPainter(
                      fillFraction: fraction,
                      isFuture: isFuture,
                      fillColor: OvColors.coral,
                    ),
                    child: Center(
                      child: count > 0
                          ? Text('$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: OvColors.coral))
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday
                      ? OvColors.coral
                      : Colors.grey.shade400),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Breakfast, lunch and dinner count  •  1 meal = 1/3 of the circle',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ]),
    );
  }

  // ── Analyse Button ─────────────────────────────────────
  Widget _buildAnalyseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: OvColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MealAnalyzerPage())),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔬', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('Analyse Meal',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────
class _MealArcPainter extends CustomPainter {
  final double fillFraction; // 0.0 → 1.0
  final bool   isFuture;
  final Color  fillColor;

  const _MealArcPainter({
    required this.fillFraction,
    required this.isFuture,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Background fill
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = isFuture ? Colors.grey.shade100 : Colors.grey.shade200
        ..style = PaintingStyle.fill,
    );

    // Filled arc — clockwise from top
    if (fillFraction > 0) {
      canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * fillFraction, true,
        Paint()
          ..color = fillColor.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * fillFraction, false,
        Paint()
          ..color = fillColor.withOpacity(0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Outer ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = isFuture ? Colors.grey.shade200 : Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_MealArcPainter old) =>
      old.fillFraction != fillFraction || old.isFuture != isFuture;
}

// ── Meal Detail Sheet ─────────────────────────────────────
class _MealDetailSheet extends StatefulWidget {
  final MealType     mealType;
  final VoidCallback onChanged;
  const _MealDetailSheet({required this.mealType, required this.onChanged});
  @override
  State<_MealDetailSheet> createState() => _MealDetailSheetState();
}

class _MealDetailSheetState extends State<_MealDetailSheet> {
  final state              = AppState.instance;
  final _nameCtrl          = TextEditingController();
  final _portionAmountCtrl = TextEditingController();

  bool   _loadingNutrients  = false;
  bool   _loadingSearch     = false;
  bool   _selectedFromDb    = false; // tracks if current name was picked from dropdown
  String? _selectedDbName;           // exact name from database
  List<FoodSearchResult> _suggestions = [];

  // Debounce timer for search
  DateTime? _lastSearch;

  // Parses grams from a portion string like "150g" → 150.0
  double? _parseGrams(String portion) {
    final match = RegExp(r'^(\d+(\.\d+)?)g$').firstMatch(portion.trim());
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  // Called when user types in the food name field
  Future<void> _onSearchChanged(String query) async {
    // Clear selection if user edits after picking from dropdown
    if (_selectedFromDb) {
      setState(() {
        _selectedFromDb = false;
        _selectedDbName = null;
        _suggestions    = [];
      });
    }

    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    // Simple debounce — ignore if called within 400ms of last search
    final now = DateTime.now();
    _lastSearch = now;
    await Future.delayed(const Duration(milliseconds: 400));
    if (_lastSearch != now || !mounted) return;

    setState(() => _loadingSearch = true);
    final results = await NutrientApiService.searchFoods(query);
    if (!mounted) return;
    setState(() {
      _suggestions    = results;
      _loadingSearch  = false;
    });
  }

  // Called when user taps a suggestion
  void _selectSuggestion(FoodSearchResult food) {
    setState(() {
      _nameCtrl.text   = food.foodName;
      _selectedFromDb  = true;
      _selectedDbName  = food.foodName;
      _suggestions     = [];
    });
    // Move focus to grams field
    FocusScope.of(context).nextFocus();
  }

  Future<void> _fetchNutrients() async {
    final items = state.mealItems[widget.mealType]!;
    if (items.isEmpty) return;

    // Only pass items that were selected from the database
    final dbItems     = items.where((i) => i.fromDatabase).toList();
    final manualItems = items.where((i) => !i.fromDatabase).toList();

    final foods = dbItems.map((item) {
      final grams = _parseGrams(item.portion) ?? 1.0;
      return MealFood(foodName: item.name, grams: grams);
    }).toList();

    setState(() => _loadingNutrients = true);
    final result = foods.isNotEmpty
        ? await NutrientApiService.calculateNutrients(foods)
        : null;
    if (!mounted) return;
    setState(() => _loadingNutrients = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NutrientResultSheet(
        mealLabel:    _title,
        result:       result,
        notFound:     result?.notFound ?? [],
        manualItems:  manualItems.map((i) => i.name).toList(),
      ),
    );
  }

  String get _title => switch (widget.mealType) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch     => 'Lunch',
    MealType.dinner    => 'Dinner',
  };

  String get _emoji => switch (widget.mealType) {
    MealType.breakfast => '🌅',
    MealType.lunch     => '☀️',
    MealType.dinner    => '🌙',
  };

  String _buildPortionString() {
    final g = _portionAmountCtrl.text.trim();
    return g.isEmpty ? '1g' : '${g}g';
  }

  void _addItem() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final wasEmpty = state.mealItems[widget.mealType]!.isEmpty;
    setState(() => state.addFoodItem(
        widget.mealType,
        FoodItem(
          name:         name,
          portion:      _buildPortionString(),
          fromDatabase: _selectedFromDb,
        )));
    widget.onChanged();
    _nameCtrl.clear();
    _portionAmountCtrl.clear();
    _selectedFromDb = false;
    _selectedDbName = null;
    _suggestions    = [];
    if (wasEmpty) XpPopup.show(context, '+2 XP ⭐');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _portionAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = state.mealItems[widget.mealType]!;
    final maxH  = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('$_emoji $_title',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            // Nutrients button — only shown when items are logged
            if (state.mealItems[widget.mealType]!.isNotEmpty)
              GestureDetector(
                onTap: _loadingNutrients ? null : _fetchNutrients,
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OvColors.coral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OvColors.coral.withOpacity(0.3))),
                  child: _loadingNutrients
                      ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: OvColors.coral))
                      : Text('Nutrients',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: OvColors.coral)),
                ),
              ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close,
                  color: Colors.grey.shade400, size: 22)),
          ]),
        ),
        const SizedBox(height: 14),
        // ── Food name with autocomplete ──────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search food name',
                  filled: true,
                  fillColor: _selectedFromDb
                      ? OvColors.coral.withOpacity(0.07)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: _selectedFromDb
                          ? BorderSide(
                              color: OvColors.coral.withOpacity(0.4),
                              width: 1.5)
                          : BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  suffixIcon: _loadingSearch
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: OvColors.coral)))
                      : _selectedFromDb
                          ? Icon(Icons.check_circle,
                              color: OvColors.coral, size: 18)
                          : null,
                ),
              ),
              // Dropdown suggestions
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4))],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final food = _suggestions[i];
                      return InkWell(
                        onTap: () => _selectSuggestion(food),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Text(
                            food.foodName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Hint when not selected from DB
              if (!_selectedFromDb && _nameCtrl.text.isNotEmpty && _suggestions.isEmpty && !_loadingSearch)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    'Not in database — nutrients won\'t be available for this item.',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _portionAmountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 150',
              suffixText: 'g',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16,
              MediaQuery.of(context).viewInsets.bottom + 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OvColors.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_emoji,
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text('No items yet',
                        style:
                            TextStyle(color: Colors.grey.shade400)),
                  ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade200)),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(item.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.fromDatabase
                                        ? OvColors.coral.withOpacity(0.1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    item.fromDatabase ? 'DB' : 'manual',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: item.fromDatabase
                                          ? OvColors.coral
                                          : Colors.grey.shade500))),
                              ]),
                              Text(item.portion,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            state.removeFoodItem(widget.mealType, i);
                            widget.onChanged();
                          }),
                          child: Icon(Icons.close,
                              size: 18,
                              color: Colors.grey.shade400)),
                      ]),
                    );
                  }),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

}

// ── Nutrient Result Sheet ─────────────────────────────────
class _NutrientResultSheet extends StatelessWidget {
  final String               mealLabel;
  final NutrientCalculation? result;
  final List<String>         notFound;
  final List<String>         manualItems; // manually logged, not in DB

  const _NutrientResultSheet({
    required this.mealLabel,
    required this.result,
    required this.notFound,
    required this.manualItems,
  });

  Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = result != null;
    final totals    = result?.totals;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('$mealLabel Nutrients',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close,
                  color: Colors.grey.shade400, size: 22)),
          ]),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No DB items at all — all manual
                if (!hasResult && manualItems.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('No database items to calculate',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'All items in this meal were logged manually. '
                          'Search and select foods from the database to get nutrient information.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.5)),
                      ],
                    ),
                  ),
                ],

                // Nutrient totals
                if (hasResult && totals != null) ...[
                  // Calories highlight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OvColors.coral.withOpacity(0.12),
                          OvColors.coral.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: OvColors.coral.withOpacity(0.2))),
                    child: Column(children: [
                      Text('${totals.calories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: OvColors.coral)),
                      const SizedBox(height: 2),
                      Text('Total calories',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Macro breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Column(children: [
                      _macroRow('Protein',
                          '${totals.protein.toStringAsFixed(1)}g',
                          const Color(0xFF2F80ED)),
                      _macroRow('Carbohydrates',
                          '${totals.carbs.toStringAsFixed(1)}g',
                          const Color(0xFFF7971E)),
                      _macroRow('Fat',
                          '${totals.fat.toStringAsFixed(1)}g',
                          const Color(0xFF9D50BB)),
                      _macroRow('Fibre',
                          '${totals.fiber.toStringAsFixed(1)}g',
                          const Color(0xFF43A047)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Per-food breakdown
                  if (result!.foods.isNotEmpty) ...[
                    const Text('Per item',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...result!.foods.map((food) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(food.foodName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('${food.grams.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                        Text('${food.calories.toStringAsFixed(0)} kcal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: OvColors.coral)),
                      ]),
                    )),
                  ],
                ],

                // Items not found in USDA database
                if (notFound.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Not found in database',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        ...notFound.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('• $name',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        )),
                      ],
                    ),
                  ),
                ],

                // Manually logged items excluded from calculation
                if (manualItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manually logged — excluded',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Select from the database search to include these.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
                        const SizedBox(height: 6),
                        ...manualItems.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('• $name',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        )),
                      ],
                    ),
                  ),
                ],

                // API connection error (has DB items but result came back null)
                if (!hasResult && manualItems.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(children: [
                      Icon(Icons.cloud_off_outlined,
                          color: Colors.grey.shade300, size: 48),
                      const SizedBox(height: 12),
                      Text('Could not reach the nutrients service.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      Text('Check your connection and try again.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared Card Widget ────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))
      ],
    ),
    child: child,
  );
}
