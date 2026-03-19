import 'package:flutter/material.dart';

/// Shows a bold centred XP toast that pops in, holds, then fades.
/// Usage: XpPopup.show(context, '+3 XP ⭐');
///        XpPopup.show(context, '+5 XP ⭐', color: Colors.amber);

class XpPopup {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String label, {
    Color color = const Color(0xFFF4826A),
  }) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpPopupWidget(
        label: label,
        color: color,
        screenW: screenW,
        screenH: screenH,
        onDone: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _XpPopupWidget extends StatefulWidget {
  final String label;
  final Color color;
  final double screenW;
  final double screenH;
  final VoidCallback onDone;

  const _XpPopupWidget({
    required this.label,
    required this.color,
    required this.screenW,
    required this.screenH,
    required this.onDone,
  });

  @override
  State<_XpPopupWidget> createState() => _XpPopupWidgetState();
}

class _XpPopupWidgetState extends State<_XpPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  // Square size
  static const double _size = 130;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // 3 seconds total
    );

    // Fade in (0–8%), hold (8–85%), fade out (85–100%)
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 77),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_ctrl);

    // Pop-in scale (0–10%), settle (10–100%)
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.12), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 88),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Centre of screen
    final left = (widget.screenW - _size) / 2;
    final top  = (widget.screenH - _size) / 2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: left,
        top:  top,
        child: IgnorePointer(
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.3,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
