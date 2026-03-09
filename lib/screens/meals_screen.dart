import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/xp_popup.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import 'meal_analyzer_page.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> with TickerProviderStateMixin {
  final state = AppState.instance;

  late AnimationController _waterController;
  late Animation<double> _waterAnimation;
  double _previousFill = 0.0;
  @override
  void initState() {
    super.initState();
    _previousFill = state.waterGlasses / 8.0;
    _waterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waterAnimation = Tween<double>(begin: _previousFill, end: _previousFill)
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
    _previousFill = newFill;
  }

  // ── Top notification ──────────────────────────────────

  void _openMealDetail(MealType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealDetailSheet(mealType: type, onChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // scaffold bg from theme
      appBar: AppBar(
        title: const Text('Meals', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF4826A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).cardColor.withOpacity(0.3))),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 16)), const SizedBox(width: 5),
              Text('${state.streak}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(right: 14, top: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.35), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5))),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 16)), const SizedBox(width: 5),
              Text('${state.points}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      // No scroll — Column with Expanded plate card
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(children: [
          _buildWaterCard(),
          const SizedBox(height: 12),
          Expanded(child: _buildPlateCard()),
          const SizedBox(height: 8),
          _buildAnalyseButton(),
          const SizedBox(height: 12),
        ]),
      )),
    );
  }

  // ── Water Card ────────────────────────────────────────
  Widget _buildWaterCard() {
    final glasses = state.waterGlasses;
    final fill    = glasses / 8.0;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text("Let's Hydrate!", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$glasses / 8',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade600)),
        ]),
        const SizedBox(height: 10),

        // Compact animated tank
        AnimatedBuilder(
          animation: _waterAnimation,
          builder: (_, __) {
            final animFill = _waterAnimation.value;
            return LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              const height = 48.0;
              return GestureDetector(
                onTap: () {
                  if (glasses < 8) {
                    setState(() => state.addWaterGlass());
                    _animateWaterTo(state.waterGlasses / 8.0);
                    if (state.waterGlasses == 8) {
                      XpPopup.show(context, '+1 XP ⭐ Goal reached!', color: Colors.blue);
                    } else {
                      XpPopup.show(context, '+1 XP ⭐');
                    }
                  }
                },
                child: Stack(children: [
                  // Tank shell
                  Container(
                    width: width, height: height,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1.5)),
                  ),
                  // Water fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: width * animFill,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade500],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                    ),
                  ),
                  // Shimmer wave at fill edge
                  if (animFill > 0.01 && animFill < 0.99)
                    Positioned(
                      left: (width * animFill) - 14,
                      top: 0, bottom: 0,
                      child: Container(
                        width: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.35), Colors.transparent],
                            begin: Alignment.centerLeft, end: Alignment.centerRight),
                        ),
                      ),
                    ),
                  // Glass markers
                  ...List.generate(7, (i) {
                    final x = width * (i + 1) / 8;
                    return Positioned(
                      left: x - 0.5, top: 8, bottom: 8,
                      child: Container(width: 1,
                        color: (i + 1) <= glasses
                            ? Colors.white.withOpacity(0.45)
                            : Colors.blue.shade200.withOpacity(0.7)),
                    );
                  }),
                  // Centre label
                  Positioned.fill(child: Center(child: Text(
                    glasses == 0 ? 'Tap to log' : '$glasses of 8 glasses',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: animFill > 0.35 ? Colors.white : Colors.blue.shade400),
                  ))),
                ]),
              );
            });
          },
        ),

        const SizedBox(height: 8),
        // Bubble row
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
                      XpPopup.show(context, '+1 XP ⭐ Goal reached!', color: Colors.blue);
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
                  color: filled ? Colors.blue.shade400 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filled ? Colors.blue.shade600 : Colors.blue.shade200, width: 1.5)),
                child: Center(child: Text('💧',
                    style: TextStyle(fontSize: filled ? 11 : 9,
                        color: filled ? null : Colors.blue.shade200))),
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

  // ── Plate Card ────────────────────────────────────────
  Widget _buildPlateCard() {
    final breakfast = state.mealItems[MealType.breakfast]!;
    final lunch     = state.mealItems[MealType.lunch]!;
    final dinner    = state.mealItems[MealType.dinner]!;
    final snacks    = state.snackItems;

    return _Card(
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendDot(color: const Color(0xFFF7971E), label: 'Breakfast', count: breakfast.length),
            _LegendDot(color: const Color(0xFF2F80ED), label: 'Lunch',     count: lunch.length),
            _LegendDot(color: const Color(0xFF9D50BB), label: 'Dinner',    count: dinner.length),
            _LegendDot(color: const Color(0xFF43A047), label: 'Snacks',    count: snacks.length),
          ],
        ),
        const SizedBox(height: 10),

        // Plate fills remaining space
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final size = min(constraints.maxWidth * 0.88, constraints.maxHeight);
            return Center(
              child: SizedBox(
                width: size, height: size,
                child: GestureDetector(
                  onTapUp: (d) => _handlePlateTap(d.localPosition, size),
                  child: CustomPaint(
                    painter: _PlatePainter(
                      breakfastLogged: breakfast.isNotEmpty,
                      lunchLogged:     lunch.isNotEmpty,
                      dinnerLogged:    dinner.isNotEmpty,
                      snacksLogged:    snacks.isNotEmpty,
                    ),
                    child: Stack(children: [
                      _quadLabel(size, '🌅', 'Breakfast',
                          breakfast.isEmpty ? null : breakfast.map((f) => f.name).take(2).join(', '),
                          Alignment.topLeft,    breakfast.isNotEmpty),
                      _quadLabel(size, '☀️', 'Lunch',
                          lunch.isEmpty ? null : lunch.map((f) => f.name).take(2).join(', '),
                          Alignment.topRight,   lunch.isNotEmpty),
                      _quadLabel(size, '🌙', 'Dinner',
                          dinner.isEmpty ? null : dinner.map((f) => f.name).take(2).join(', '),
                          Alignment.bottomLeft,  dinner.isNotEmpty),
                      _quadLabel(size, '🍬', 'Snacks',
                          snacks.isEmpty ? null : snacks.map((f) => f.name).take(2).join(', '),
                          Alignment.bottomRight, snacks.isNotEmpty),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),
        Text('Tap a quarter to log  •  +2 XP per meal',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _quadLabel(double size, String emoji, String title, String? items,
      Alignment alignment, bool hasItems) {
    final half = size / 2;
    double left, top;
    if (alignment == Alignment.topLeft)     { left = 0;    top = 0; }
    else if (alignment == Alignment.topRight)    { left = half; top = 0; }
    else if (alignment == Alignment.bottomLeft)  { left = 0;    top = half; }
    else                                          { left = half; top = half; }

    return Positioned(
      left: left, top: top, width: half, height: half,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 3),
          Text(title,
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: hasItems ? Colors.white : Colors.white.withOpacity(0.65)),
              textAlign: TextAlign.center),
          if (hasItems && items != null) ...[
            const SizedBox(height: 3),
            Text(items,
                style: const TextStyle(fontSize: 8, color: Colors.white, height: 1.3),
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  void _handlePlateTap(Offset pos, double size) {
    final half   = size / 2;
    const inner  = 24.0;
    final centre = Offset(half, half);
    final dist   = (pos - centre).distance;
    if (dist < inner || dist > half) return;

    final isLeft = pos.dx < half;
    final isTop  = pos.dy < half;

    if      ( isTop &&  isLeft) _openMealDetail(MealType.breakfast);
    else if ( isTop && !isLeft) _openMealDetail(MealType.lunch);
    else if (!isTop &&  isLeft) _openMealDetail(MealType.dinner);
    else                        _openSnackDetail();
  }

  void _openSnackDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SnackDetailSheet(onChanged: () => setState(() {})),
    );
  }

  // ── Analyse button ────────────────────────────────────
  Widget _buildAnalyseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4826A), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MealAnalyzerPage())),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🔬', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text('Analyse My Meals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Plate Painter ─────────────────────────────────────────
class _PlatePainter extends CustomPainter {
  final bool breakfastLogged, lunchLogged, dinnerLogged, snacksLogged;

  static const _breakfastColor = Color(0xFFF7971E);
  static const _lunchColor     = Color(0xFF2F80ED);
  static const _dinnerColor    = Color(0xFF9D50BB);
  static const _snacksColor    = Color(0xFF43A047);
  static const _emptyColor     = Color(0xFFEEEEEE);

  const _PlatePainter({
    required this.breakfastLogged,
    required this.lunchLogged,
    required this.dinnerLogged,
    required this.snacksLogged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c    = Offset(size.width / 2, size.height / 2);
    final r    = size.width / 2;
    const inner = 26.0;
    final rect  = Rect.fromCircle(center: c, radius: r);

    // Shadow
    canvas.drawCircle(c + const Offset(0, 4), r,
        Paint()..color = Colors.black.withOpacity(0.08)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Plate base
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF5F5F5));

    // 4 quadrants
    final quads = [
      (breakfastLogged, _breakfastColor, -pi      ),
      (lunchLogged,     _lunchColor,     -pi / 2  ),
      (snacksLogged,    _snacksColor,     0.0     ),
      (dinnerLogged,    _dinnerColor,     pi / 2  ),
    ];

    for (final q in quads) {
      final paint = Paint()
        ..color = (q.$1 as bool) ? q.$2 as Color : _emptyColor
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, q.$3 as double, pi / 2, false)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Cross dividers
    final div = Paint()..color = Colors.white..strokeWidth = 2.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), div);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), div);

    // Inner hole
    canvas.drawCircle(c, inner, Paint()..color = Colors.white);

    // Outer ring
    canvas.drawCircle(c, r,
        Paint()..color = Colors.white..strokeWidth = 5..style = PaintingStyle.stroke);

    // Inner ring border
    canvas.drawCircle(c, inner,
        Paint()..color = Colors.grey.shade200..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.breakfastLogged != breakfastLogged || old.lunchLogged != lunchLogged ||
      old.dinnerLogged != dinnerLogged       || old.snacksLogged != snacksLogged;
}

// ── Legend Dot ────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _LegendDot({required this.color, required this.label, required this.count});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(count > 0 ? '$label ($count)' : label,
        style: TextStyle(fontSize: 11,
            fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w400,
            color: count > 0 ? Colors.grey.shade800 : Colors.grey.shade500)),
  ]);
}

// ── Meal Detail Sheet (bottom sheet modal) ──────────────
class _MealDetailSheet extends StatefulWidget {
  final MealType mealType;
  final VoidCallback onChanged;
  const _MealDetailSheet({required this.mealType, required this.onChanged});
  @override
  State<_MealDetailSheet> createState() => _MealDetailSheetState();
}

class _MealDetailSheetState extends State<_MealDetailSheet> {
  final state = AppState.instance;
  final _nameCtrl    = TextEditingController();
  final _portionCtrl = TextEditingController();

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

  void _addItem() {
    final name    = _nameCtrl.text.trim();
    final portion = _portionCtrl.text.trim();
    if (name.isEmpty || portion.isEmpty) return;
    final wasEmpty = state.mealItems[widget.mealType]!.isEmpty;
    setState(() => state.addFoodItem(widget.mealType, FoodItem(name: name, portion: portion)));
    widget.onChanged();
    _nameCtrl.clear(); _portionCtrl.clear();
    if (wasEmpty) {
      XpPopup.show(context, '+2 XP ⭐ \$_title logged!');
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _portionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = state.mealItems[widget.mealType]!;
    final maxH = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('$_emoji $_title',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, color: Colors.grey.shade400, size: 22)),
          ]),
        ),
        const SizedBox(height: 16),
        // Input row
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16,
              MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(children: [
            Expanded(flex: 3, child: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'Food name', filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: TextField(
              controller: _portionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'Portion', filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addItem,
              child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF4826A),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white))),
          ]),
        ),
        const Divider(height: 1),
        // Items list
        Flexible(child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text('No items yet', style: TextStyle(color: Colors.grey.shade400)),
                ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(item.portion, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ])),
                      GestureDetector(
                        onTap: () => setState(() { state.removeFoodItem(widget.mealType, i); widget.onChanged(); }),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade400)),
                    ]),
                  );
                })),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── Snack Detail Sheet ────────────────────────────────────
class _SnackDetailSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _SnackDetailSheet({required this.onChanged});
  @override
  State<_SnackDetailSheet> createState() => _SnackDetailSheetState();
}

class _SnackDetailSheetState extends State<_SnackDetailSheet> {
  final state = AppState.instance;
  final _nameCtrl    = TextEditingController();
  final _portionCtrl = TextEditingController();

  void _addItem() {
    final name    = _nameCtrl.text.trim();
    final portion = _portionCtrl.text.trim();
    if (name.isEmpty || portion.isEmpty) return;
    setState(() => state.addSnack(FoodItem(name: name, portion: portion)));
    widget.onChanged();
    _nameCtrl.clear(); _portionCtrl.clear();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _portionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = state.snackItems;
    final maxH = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('🍬 Snacks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, color: Colors.grey.shade400, size: 22)),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16,
              MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(children: [
            Expanded(flex: 3, child: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'Snack name', filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: TextField(
              controller: _portionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'Portion', filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addItem,
              child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF4826A),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white))),
          ]),
        ),
        const Divider(height: 1),
        Flexible(child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🍬', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text('No snacks yet', style: TextStyle(color: Colors.grey.shade400)),
                ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(item.portion, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ])),
                      GestureDetector(
                        onTap: () => setState(() { state.removeSnack(i); widget.onChanged(); }),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade400)),
                    ]),
                  );
                })),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── Shared ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String emoji;
  final Color emojiBackground;
  final String title;
  const _CardHeader({required this.emoji, required this.emojiBackground, required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 30, height: 30,
      decoration: BoxDecoration(color: emojiBackground, borderRadius: BorderRadius.circular(9)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 15)))),
    const SizedBox(width: 9),
    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}
