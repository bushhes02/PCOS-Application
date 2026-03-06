import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static int levelFromPoints(int points) => (points / 50).floor() + 1;
  static int pointsForNextLevel(int level) => level * 50;
  static int pointsForCurrentLevel(int level) => (level - 1) * 50;

  static String levelTitle(int level) {
    if (level >= 10) return 'PCOS Champion 🏆';
    if (level >= 7)  return 'Wellness Warrior 💜';
    if (level >= 5)  return 'PCOS Warrior ⚔️';
    if (level >= 3)  return 'Rising Strong 🌱';
    return 'Getting Started ✨';
  }

  // 6 badges only
  static const List<Map<String, dynamic>> allBadges = [
    {'emoji': '🔥', 'label': '7-Day Streak',   'key': 'streak7'},
    {'emoji': '💧', 'label': 'Hydration Goal', 'key': 'hydrated'},
    {'emoji': '📓', 'label': 'First Journal',  'key': 'journaled'},
    {'emoji': '😊', 'label': 'Mood Tracker',   'key': 'moodLogged'},
    {'emoji': '📅', 'label': 'Full Week Move', 'key': 'fullWeek'},
    {'emoji': '🎯', 'label': 'Challenge Done', 'key': 'challengeDone'},
  ];

  Set<String> _earnedBadgeKeys(AppState state) {
    final earned = <String>{};
    if (state.streak >= 7) earned.add('streak7');
    if (state.waterGoalMetToday) earned.add('hydrated');
    if (state.todayJournalEntry != null) earned.add('journaled');
    if (state.moodLoggedToday) earned.add('moodLogged');
    if (state.daysMovedThisWeek == 7) earned.add('fullWeek');
    if (state.activeChallengeCompleted) earned.add('challengeDone');
    return earned;
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.deepPurple,
            label: 'Appearance',
            onTap: () {
              Navigator.pop(context);
              // Appearance settings — placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Appearance settings coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.help_outline,
            iconColor: Colors.teal,
            label: 'Help',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Help centre coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final state = AppState.instance;
    final level = levelFromPoints(state.points);
    final currentLevelPoints = pointsForCurrentLevel(level);
    final nextLevelPoints = pointsForNextLevel(level);
    final progressInLevel = state.points - currentLevelPoints;
    final pointsNeeded = nextLevelPoints - currentLevelPoints;
    final levelProgress = (progressInLevel / pointsNeeded).clamp(0.0, 1.0);
    final earned = _earnedBadgeKeys(state);

    final displayName = user?.displayName ?? user?.email ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    // Pillar progress
    final moveProgress = (state.daysMovedThisWeek / 7).clamp(0.0, 1.0);
    // Meals: count days this week where at least one meal was logged (approx via weeklyMovementDays as proxy — use mealItems as daily logged count capped at 7)
    final int mealsLoggedToday = () {
      int c = 0;
      for (final t in MealType.values) { if (state.mealItems[t]!.isNotEmpty) c++; }
      if (state.snackItems.isNotEmpty) c++;
      return c;
    }();
    // For weekly meals we show today's meal count out of 3 main meals + snacks (no week history stored yet)
    final mealsProgress = (mealsLoggedToday / 4).clamp(0.0, 1.0);
    // Mind: count days moved this week as proxy; for mind use logged items today shown as x/7
    final int mindLoggedToday = () {
      int c = 0;
      if (state.moodLoggedToday) c++;
      if (state.sleepLoggedToday) c++;
      if (state.todayJournalEntry != null) c++;
      return c;
    }();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 0,
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
      bottomNavigationBar: const BottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(children: [

          // ── Hero header ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Stack(alignment: Alignment.center, children: [
              // Settings gear — top right of card
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => _showSettingsSheet(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5)),
                  child: Center(child: Text(initial,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(height: 10),
                Text(user?.displayName ?? 'Hey there!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.4))),
                  child: Text('Level $level — ${levelTitle(level)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber)),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Stats row ─────────────────────────────────
          Row(children: [
            Expanded(child: _StatCard(icon: '🔥', value: '${state.streak}', label: 'Streak')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: '⭐', value: '${state.points}', label: 'Points')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: '🏅', value: '${earned.length}', label: 'Badges')),
          ]),

          const SizedBox(height: 12),

          // ── Level progress ────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Level $level', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${state.points} / $nextLevelPoints XP',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: levelProgress,
                backgroundColor: Colors.deepPurple.shade100,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF9D50BB)),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text('${pointsNeeded - progressInLevel} XP to Level ${level + 1}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ])),

          const SizedBox(height: 12),

          // ── Today's pillars — square boxes ────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('THIS WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: Colors.grey)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PillarBox(
                emoji: '🏃', label: 'Move',
                color: Colors.deepPurple,
                lightColor: Colors.deepPurple.shade50,
                progress: moveProgress,
                detail: '${state.daysMovedThisWeek}/7 days',
              )),
              const SizedBox(width: 10),
              Expanded(child: _PillarBox(
                emoji: '🍽️', label: 'Meals',
                color: const Color(0xFFF7971E),
                lightColor: const Color(0xFFFFF3E0),
                progress: mealsProgress,
                detail: '$mealsLoggedToday/7 days',
              )),
              const SizedBox(width: 10),
              Expanded(child: _PillarBox(
                emoji: '🧘', label: 'Mind',
                color: const Color(0xFF5A9E72),
                lightColor: const Color(0xFFE8F5E9),
                progress: mindLoggedToday / 7,
                detail: '$mindLoggedToday/7 days',
              )),
            ]),
          ])),

          const SizedBox(height: 12),

          // ── 6 Badges ──────────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('BADGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: Colors.grey)),
              Text('${earned.length} badges',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade400)),
            ]),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: allBadges.map((badge) {
                final isEarned = earned.contains(badge['key']);
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEarned ? Colors.amber.shade100 : Colors.grey.shade100,
                      border: Border.all(
                        color: isEarned ? Colors.amber.shade300 : Colors.grey.shade300, width: 2),
                      boxShadow: isEarned ? [BoxShadow(color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8, spreadRadius: 1)] : null,
                    ),
                    child: Center(child: Text(isEarned ? badge['emoji'] as String : '🔒',
                        style: TextStyle(fontSize: isEarned ? 22 : 16))),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 48,
                    child: Text(badge['label'] as String,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                            color: isEarned ? Colors.grey.shade700 : Colors.grey.shade400),
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ]);
              }).toList(),
            ),
          ])),

          const SizedBox(height: 12),

          // ── Sign out ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              ),
              title: const Text('Sign Out', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: Colors.redAccent)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Pillar square box ─────────────────────────────────────
class _PillarBox extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color lightColor;
  final double progress;
  final String detail;

  const _PillarBox({required this.emoji, required this.label, required this.color,
      required this.lightColor, required this.progress, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(detail, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.iconColor,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: Colors.grey.shade500, letterSpacing: 0.5)),
    ]),
  );
}

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
