import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'home_screen.dart';

const _bg   = Color(0xFFFFF7F2);
const _pink = Color(0xFFF4826A);
const _ink  = Color(0xFF1E1610);

// The 6 avatar asset paths
const _avatars = [
  'assets/images/avatar_1.png',
  'assets/images/avatar_2.png',
  'assets/images/avatar_3.png',
  'assets/images/avatar_4.png',
  'assets/images/avatar_5.png',
  'assets/images/avatar_6.png',
];

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});
  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  String? _selected;

  void _continue() {
    if (_selected == null) return;
    AppState.instance.saveAvatar(_selected!);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ── Header ────────────────────────────────────
              const Text('Welcome to the Cysterhood!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.5),
                  textAlign: TextAlign.center),

              const SizedBox(height: 8),

              Text(
                'Pick your avatar to continue',
                style: TextStyle(
                    fontSize: 14, color: _ink.withOpacity(0.45)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Avatar Grid ───────────────────────────────
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (_, i) {
                    final path       = _avatars[i];
                    final isSelected = _selected == path;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = path),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? _pink
                                : Colors.grey.shade200,
                            width: isSelected ? 3 : 1.5),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: _pink.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))]
                              : [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(path, fit: BoxFit.cover),
                              // Selected overlay checkmark
                              if (isSelected)
                                Positioned(
                                  top: 6, right: 6,
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: const BoxDecoration(
                                      color: _pink,
                                      shape: BoxShape.circle),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Join button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected != null
                        ? _pink
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _selected != null ? _continue : null,
                  child: const Text('Join the Cysterhood',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
