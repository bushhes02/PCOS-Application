import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _insightLoading = false;

  @override
  void initState() {
    super.initState();
    _maybeRefreshInsight();
  }

  Future<void> _maybeRefreshInsight() async {
    final state = AppState.instance;
    if (!state.hasEnoughDataForInsight) return;
    if (!state.shouldRefreshInsight) return;

    setState(() => _insightLoading = true);
    try {
      final mood7     = state.last7DaysMood;
      final sleep7    = state.last7DaysSleep;
      final water7    = state.last7DaysWater;
      final movement7 = state.last7DaysMovement;

      final payload = {
        'mood_logs':     mood7.map((e) => e['mood']).toList(),
        'sleep_logs':    sleep7.map((e) => e['hours']).toList(),
        'water_logs':    water7.map((e) => e['glasses']).toList(),
        'movement_logs': movement7.map((e) => e['type']).toList(),
      };

      final response = await http
          .post(
            Uri.parse('https://ovarrior-insight-api.onrender.com/insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insight = data['insight'] as String? ?? '';
        if (insight.isNotEmpty) state.saveInsightCache(insight);
      }
    } catch (_) {
      // Silently fail — show cached or placeholder
    } finally {
      if (mounted) setState(() => _insightLoading = false);
    }
  }

  static const int xpPerLevel = 300;
  static int levelFromPoints(int pts) => (pts / xpPerLevel).floor() + 1;
  static int pointsForCurrentLevel(int lvl) => (lvl - 1) * xpPerLevel;
  static int pointsForNextLevel(int lvl) => lvl * xpPerLevel;

  static String levelTitle(int level) {
    if (level >= 10) return 'PCOS Champion 🏆';
    if (level >= 7)  return 'Wellness Warrior 💜';
    if (level >= 5)  return 'PCOS Warrior ⚔️';
    if (level >= 3)  return 'Rising Strong 🌱';
    return 'Getting Started ✨';
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4826A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.dark_mode_outlined, color: Color(0xFFF4826A), size: 18)),
                const SizedBox(width: 14),
                const Expanded(child: Text('Dark Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                Switch(
                  value: ThemeState.instance.isDark,
                  activeColor: const Color(0xFFF4826A),
                  onChanged: (_) { ThemeState.instance.toggle(); setSheet(() {}); },
                ),
              ]),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.help_outline, iconColor: Colors.teal, label: 'Help',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Help centre coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user  = FirebaseAuth.instance.currentUser;
    final state = AppState.instance;
    final level              = levelFromPoints(state.points);
    final currentLevelPoints = pointsForCurrentLevel(level);
    final nextLevelPoints    = pointsForNextLevel(level);
    final progressInLevel    = state.points - currentLevelPoints;
    final pointsNeeded       = nextLevelPoints - currentLevelPoints;
    final levelProgress      = (progressInLevel / pointsNeeded).clamp(0.0, 1.0);

    final displayName = user?.displayName ?? user?.email ?? 'User';
    final initial     = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final moveProgress = (state.daysMovedThisWeek / 7).clamp(0.0, 1.0);

    // Meals: count distinct days this week where any meal was logged (via mealHistory)
    final weekKeys = state.currentWeekDays;
    final int mealsWeekDays = state.mealHistory.keys
        .where((d) => weekKeys.contains(d))
        .length;
    final mealsProgress = (mealsWeekDays / 7).clamp(0.0, 1.0);

    // Mind: count distinct days this week where mood OR sleep was logged
    final int mindWeekDays = weekKeys.where((d) =>
        state.moodHistory.any((e) => e['date'] == d) ||
        state.sleepHistory.any((e) => e['date'] == d)).length;
    final mindProgress = (mindWeekDays / 7).clamp(0.0, 1.0);

    final quests = AppState.presetChallenges;

    return ListenableBuilder(
      listenable: ThemeState.instance,
      builder: (context, _) { return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF4826A), foregroundColor: Colors.white, elevation: 0,
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
      bottomNavigationBar: const BottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(children: [

          // ── Hero ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => _showSettingsSheet(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4826A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.settings_outlined, color: Color(0xFFF4826A), size: 18),
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF4826A).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFFF4826A).withOpacity(0.35), width: 2.5)),
                  child: Center(child: Text(initial,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFFF4826A)))),
                ),
                const SizedBox(height: 10),
                Text(user?.displayName ?? 'Hey there!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.35))),
                  child: Text('Level $level — ${levelTitle(level)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB8960A))),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Stats row ─────────────────────────────────
          Row(children: [
            Expanded(child: _StatCard(icon: '🔥', value: '${state.streak}', label: 'Streak')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: '⭐', value: '${state.points}', label: 'Total Points')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: '🏅',
                value: '${quests.where((q) => state.activeChallengeId == q['id'] && state.activeChallengeCompleted).length}',
                label: 'Badges')),
          ]),

          const SizedBox(height: 12),

          // ── Level progress ────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Level $level', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('$progressInLevel / $xpPerLevel XP',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: levelProgress,
                backgroundColor: const Color(0xFFFFD6CE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF9D50BB)),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text('${pointsNeeded - progressInLevel} XP to Level ${level + 1}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ])),

          const SizedBox(height: 12),

          // ── Pillar progress ───────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('THIS WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: Colors.grey)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PillarBox(
                emoji: '🏃', label: 'Move', color: const Color(0xFFF4826A),
                lightColor: const Color(0xFFFFF0ED), progress: moveProgress,
                detail: '${state.daysMovedThisWeek}/7 days',
              )),
              const SizedBox(width: 10),
              Expanded(child: _PillarBox(
                emoji: '🍽️', label: 'Meals', color: const Color(0xFFF7971E),
                lightColor: const Color(0xFFFFF3E0), progress: mealsProgress,
                detail: '$mealsWeekDays/7 days',
              )),
              const SizedBox(width: 10),
              Expanded(child: _PillarBox(
                emoji: '🧘', label: 'Mind', color: const Color(0xFF5A9E72),
                lightColor: const Color(0xFFE8F5E9), progress: mindProgress,
                detail: '$mindWeekDays/7 days',
              )),
            ]),
          ])),

          const SizedBox(height: 12),

          // ── Weekly Insight ────────────────────────────
          _InsightCard(
            hasEnoughData: state.hasEnoughDataForInsight,
            insight: state.cachedInsight,
            onRefresh: _maybeRefreshInsight,
          ),

          const SizedBox(height: 12),

          // ── Badges ────────────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('BADGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: Colors.grey)),
              Text(
                '${quests.where((q) => state.activeChallengeId == q['id'] && state.activeChallengeCompleted).length} / ${quests.length} earned',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFFF4826A).withOpacity(0.7))),
            ]),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: quests.asMap().entries.map((entry) {
                final i     = entry.key;
                final quest = entry.value;
                final isActive    = state.activeChallengeId == quest['id'];
                final isCompleted = isActive && state.activeChallengeCompleted;
                final isLocked    = !isActive && !isCompleted;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFFFFBE6)
                          : isLocked ? Colors.grey.shade50 : const Color(0xFFFFF0ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted ? const Color(0xFFFFCC00)
                            : isLocked ? Colors.grey.shade200
                            : const Color(0xFFF4826A).withOpacity(0.4),
                        width: isCompleted ? 1.5 : 1),
                      boxShadow: isCompleted ? [BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 8, offset: const Offset(0, 2))] : null,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isCompleted ? '🏅' : isLocked ? '🔒' : '🏆',
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 8),
                      Text(quest['title'] as String,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: isLocked ? Colors.grey.shade400 : Colors.grey.shade800),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFFFCC00)
                              : isLocked ? Colors.grey.shade200 : const Color(0xFFFFD6CE),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isCompleted ? 'Earned' : isLocked ? 'Locked' : 'Active',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                              color: isCompleted ? Colors.white
                                  : isLocked ? Colors.grey.shade400
                                  : const Color(0xFFB85A47))),
                      ),
                    ]),
                  ),
                ));
              }).toList(),
            ),
          ])),

          const SizedBox(height: 12),

          // ── Sign out ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
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
                await AppState.resetForSignOut();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
              },
            ),
          ),
        ]),
      ),
    ); },
    );
  }
}

// ── Weekly Insight Card ───────────────────────────────────
class _InsightCard extends StatelessWidget {
  final bool hasEnoughData;
  final String? insight;
  final VoidCallback onRefresh;
  const _InsightCard({required this.hasEnoughData,
      required this.insight, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0ED), Color(0xFFFCE4EC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4826A).withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('🔮', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text('WEEKLY INSIGHT', style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.grey)),
          ]),
          if (hasEnoughData)
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4826A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: const Text('Refresh', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: Color(0xFFB85A47))),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (!hasEnoughData || insight == null || insight!.isEmpty)
          Text('Keep logging for 7 days to unlock your personalised weekly insight! 🌸',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey.shade600))
        else
          Text(insight!, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4A3728))),
      ]),
    );
  }
}

// ── Pillar Box ────────────────────────────────────────────
class _PillarBox extends StatelessWidget {
  final String emoji, label, detail;
  final Color color, lightColor;
  final double progress;
  const _PillarBox({required this.emoji, required this.label, required this.color,
      required this.lightColor, required this.progress, required this.detail});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: lightColor, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.15))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: progress, minHeight: 5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color))),
      const SizedBox(height: 5),
      Text(detail, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Settings Tile ─────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.iconColor,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F5), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
      ]),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
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
      color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}
