import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final state = AppState.instance;

  void _showXpSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.deepPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openMealDetail(MealType type) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _MealDetailScreen(mealType: type, onChanged: () => setState(() {})),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Meals', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3))),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          _buildWaterCard(),
          const SizedBox(height: 12),
          _buildPlateCard(),
          const SizedBox(height: 80), // space for button
        ],
      ),
      // Analyse button floated above bottom nav
      bottomSheet: _buildAnalyseButton(),
    );
  }

  // ── Water Tank Card ───────────────────────────────────
  Widget _buildWaterCard() {
    final glasses = state.waterGlasses;
    final fill = glasses / 8.0;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _CardHeader(emoji: '💧', emojiBackground: Colors.blue.shade50, title: 'Water Tracker'),
          const Spacer(),
          Text('$glasses / 8 glasses',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
        ]),
        const SizedBox(height: 14),

        // Animated water tank
        GestureDetector(
          onTapUp: (d) {
            final box = context.findRenderObject() as RenderBox?;
            // Tap right half = add, tap left half = remove last
            setState(() {
              if (glasses < 8) {
                state.addWaterGlass();
                if (state.waterGlasses == 8) {
                  _showXpSnackbar('💧 Goal reached! +1 XP 🎉');
                } else {
                  _showXpSnackbar('+1 XP — glass logged!');
                }
              }
            });
          },
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 72.0;
            return Stack(children: [
              // Tank shell
              Container(
                width: width, height: height,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
              ),
              // Water fill — animated
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: width * fill,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade500],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Wave shimmer overlay on the fill edge
              if (fill > 0 && fill < 1)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  left: width * fill - 12,
                  top: 0, bottom: 0,
                  child: Container(
                    width: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              // Glass markers
              ...List.generate(7, (i) {
                final x = width * (i + 1) / 8;
                return Positioned(
                  left: x - 0.5, top: 12, bottom: 12,
                  child: Container(
                    width: 1,
                    color: (i + 1) <= glasses
                        ? Colors.white.withOpacity(0.4)
                        : Colors.blue.shade200.withOpacity(0.6),
                  ),
                );
              }),
              // Glass count text centred
              Positioned.fill(child: Center(child: Text(
                glasses == 0 ? 'Tap to log water' : '$glasses of 8 glasses',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: fill > 0.35 ? Colors.white : Colors.blue.shade400),
              ))),
            ]);
          }),
        ),

        const SizedBox(height: 10),
        // Individual glass bubbles for remove
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(8, (i) {
            final filled = i < glasses;
            return GestureDetector(
              onTap: () => setState(() {
                if (!filled) {
                  state.addWaterGlass();
                  _showXpSnackbar(state.waterGlasses == 8
                      ? '💧 Goal reached! +1 XP 🎉' : '+1 XP — glass logged!');
                } else if (i == glasses - 1) {
                  state.removeWaterGlass();
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: filled ? Colors.blue.shade400 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filled ? Colors.blue.shade600 : Colors.blue.shade200, width: 1.5),
                ),
                child: Center(child: Text('💧',
                    style: TextStyle(fontSize: filled ? 13 : 10,
                        color: filled ? null : Colors.blue.shade200))),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text('Tap a bubble to add or remove  •  +1 XP per glass',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        if (state.waterGoalMetToday) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🎉', style: TextStyle(fontSize: 12)),
              SizedBox(width: 6),
              Text('Daily goal reached!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Plate Card (4 quadrants) ───────────────────────────
  Widget _buildPlateCard() {
    final breakfast = state.mealItems[MealType.breakfast]!;
    final lunch     = state.mealItems[MealType.lunch]!;
    final dinner    = state.mealItems[MealType.dinner]!;
    final snacks    = state.snackItems;

    return _Card(
      child: Column(children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendDot(color: const Color(0xFFF7971E), label: 'Breakfast', count: breakfast.length),
            _LegendDot(color: const Color(0xFF2F80ED), label: 'Lunch',     count: lunch.length),
            _LegendDot(color: const Color(0xFF9D50BB), label: 'Dinner',    count: dinner.length),
            _LegendDot(color: const Color(0xFF43A047), label: 'Snacks',    count: snacks.length),
          ],
        ),
        const SizedBox(height: 16),

        // Plate
        LayoutBuilder(builder: (context, constraints) {
          final size = constraints.maxWidth * 0.88;
          return SizedBox(
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
                  // Top-left: Breakfast
                  _quadLabel(size, '🌅', 'Breakfast',
                      breakfast.isEmpty ? null : breakfast.map((f) => f.name).take(2).join(', '),
                      Alignment.topLeft,    breakfast.isNotEmpty),
                  // Top-right: Lunch
                  _quadLabel(size, '☀️', 'Lunch',
                      lunch.isEmpty ? null : lunch.map((f) => f.name).take(2).join(', '),
                      Alignment.topRight,   lunch.isNotEmpty),
                  // Bottom-left: Dinner
                  _quadLabel(size, '🌙', 'Dinner',
                      dinner.isEmpty ? null : dinner.map((f) => f.name).take(2).join(', '),
                      Alignment.bottomLeft,  dinner.isNotEmpty),
                  // Bottom-right: Snacks
                  _quadLabel(size, '🍬', 'Snacks',
                      snacks.isEmpty ? null : snacks.map((f) => f.name).take(2).join(', '),
                      Alignment.bottomRight, snacks.isNotEmpty),
                ]),
              ),
            ),
          );
        }),

        const SizedBox(height: 10),
        Text('Tap a quarter to log  •  +2 XP per meal',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }

  // Places a label in the centre of each quadrant
  Widget _quadLabel(double size, String emoji, String title, String? items,
      Alignment alignment, bool hasItems) {
    final half = size / 2;
    // Offset from edge of full plate to centre of quadrant
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
    final half = size / 2;
    final inner = 24.0;
    final centre = Offset(half, half);
    final dist = (pos - centre).distance;
    if (dist < inner || dist > half) return;

    final isLeft  = pos.dx < half;
    final isTop   = pos.dy < half;

    if (isTop  &&  isLeft)  _openMealDetail(MealType.breakfast);
    else if (isTop  && !isLeft)  _openMealDetail(MealType.lunch);
    else if (!isTop &&  isLeft)  _openMealDetail(MealType.dinner);
    else                         _openSnackDetail();
  }

  void _openSnackDetail() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _SnackDetailScreen(onChanged: () => setState(() {})),
    ));
  }

  // ── Analyse button — bottomSheet so it never overlaps ─
  Widget _buildAnalyseButton() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 0),
          elevation: 4,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('🔬 GL analyser coming soon!',
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.deepPurple.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🔬', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text('Analyse My Meals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Plate Painter (4 quadrants) ─────────────────────────
class _PlatePainter extends CustomPainter {
  final bool breakfastLogged;
  final bool lunchLogged;
  final bool dinnerLogged;
  final bool snacksLogged;

  static const _breakfastColor = Color(0xFFF7971E);
  static const _lunchColor     = Color(0xFF2F80ED);
  static const _dinnerColor    = Color(0xFF9D50BB);
  static const _snacksColor    = Color(0xFF43A047);
  static const _emptyColor     = Color(0xFFEEEEEE);

  _PlatePainter({
    required this.breakfastLogged,
    required this.lunchLogged,
    required this.dinnerLogged,
    required this.snacksLogged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const inner = 26.0;
    final rect  = Rect.fromCircle(center: c, radius: r);

    // Shadow
    canvas.drawCircle(c + const Offset(0, 4), r,
        Paint()..color = Colors.black.withOpacity(0.08)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Plate base
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF5F5F5));

    // 4 quadrants (each 90°)
    // Top-left:     Breakfast  -180° → -90°
    // Top-right:    Lunch      -90°  →   0°
    // Bottom-right: Snacks       0°  →  90°
    // Bottom-left:  Dinner      90°  → 180°
    final quads = [
      (breakfastLogged, _breakfastColor, -pi,     ),  // top-left
      (lunchLogged,     _lunchColor,     -pi / 2, ),  // top-right
      (snacksLogged,    _snacksColor,     0.0,    ),  // bottom-right
      (dinnerLogged,    _dinnerColor,     pi / 2, ),  // bottom-left
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
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), div); // vertical
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), div); // horizontal

    // Inner hole cross mask
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
      old.breakfastLogged != breakfastLogged ||
      old.lunchLogged != lunchLogged ||
      old.dinnerLogged != dinnerLogged ||
      old.snacksLogged != snacksLogged;
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

// ── Meal Detail Screen ────────────────────────────────────
class _MealDetailScreen extends StatefulWidget {
  final MealType mealType;
  final VoidCallback onChanged;
  const _MealDetailScreen({required this.mealType, required this.onChanged});
  @override
  State<_MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<_MealDetailScreen> {
  final state = AppState.instance;
  final _nameCtrl = TextEditingController();
  final _portionCtrl = TextEditingController();

  String get _title => switch (widget.mealType) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.dinner => 'Dinner',
  };
  String get _emoji => switch (widget.mealType) {
    MealType.breakfast => '🌅',
    MealType.lunch => '☀️',
    MealType.dinner => '🌙',
    MealType.dinner => '🌙',
  };

  void _addItem() {
    final name = _nameCtrl.text.trim();
    final portion = _portionCtrl.text.trim();
    if (name.isEmpty || portion.isEmpty) return;
    final wasEmpty = state.mealItems[widget.mealType]!.isEmpty;
    setState(() => state.addFoodItem(widget.mealType, FoodItem(name: name, portion: portion)));
    widget.onChanged();
    _nameCtrl.clear();
    _portionCtrl.clear();
    if (wasEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('+2 XP — $_title logged! 🎉',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurple, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _portionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = state.mealItems[widget.mealType]!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('$_emoji $_title', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add food item',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(flex: 3, child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Food name', filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(
                controller: _portionCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Portion', filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addItem,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white))),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No items yet', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
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
                  }),
        ),
      ]),
    );
  }
}

// ── Snack Detail Screen ───────────────────────────────────
class _SnackDetailScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const _SnackDetailScreen({required this.onChanged});
  @override
  State<_SnackDetailScreen> createState() => _SnackDetailScreenState();
}

class _SnackDetailScreenState extends State<_SnackDetailScreen> {
  final state = AppState.instance;
  final _nameCtrl = TextEditingController();
  final _portionCtrl = TextEditingController();

  void _addItem() {
    final name = _nameCtrl.text.trim();
    final portion = _portionCtrl.text.trim();
    if (name.isEmpty || portion.isEmpty) return;
    setState(() => state.addSnack(FoodItem(name: name, portion: portion)));
    widget.onChanged();
    _nameCtrl.clear();
    _portionCtrl.clear();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _portionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = state.snackItems;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🍬 Snacks', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add snack',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(flex: 3, child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Snack name', filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(
                controller: _portionCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Portion', filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addItem,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white))),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🍬', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No snacks logged yet', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
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
                  }),
        ),
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
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
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
    Container(width: 32, height: 32,
      decoration: BoxDecoration(color: emojiBackground, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16)))),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}
