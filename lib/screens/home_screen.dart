import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final state = AppState.instance;

  // ── XP snackbar ───────────────────────────────────────
  void _showXpSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.deepPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Log movement bottom sheet ─────────────────────────
  void _showMovementDialog() {
    String selectedType = 'Walk';
    int selectedDuration = 30;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Log Movement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Text('Movement Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                {'label': 'Walk', 'emoji': '🚶'},
                {'label': 'Yoga', 'emoji': '🧘'},
                {'label': 'Stretch', 'emoji': '🤸'},
                {'label': 'Workout', 'emoji': '🏋️'},
                {'label': 'Cycle', 'emoji': '🚴'},
                {'label': 'Run', 'emoji': '🏃'},
              ].map((type) {
                final isSelected = selectedType == type['label'];
                return GestureDetector(
                  onTap: () => setSheet(() => selectedType = type['label']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12)),
                    child: Text('${type['emoji']} ${type['label']}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.deepPurple.shade700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Duration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [15, 20, 30, 45, 60].map((mins) {
                final isSelected = selectedDuration == mins;
                return GestureDetector(
                  onTap: () => setSheet(() => selectedDuration = mins),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12)),
                    child: Text('${mins}m',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.deepPurple.shade700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  setState(() => state.logMovement(type: selectedType, duration: selectedDuration));
                  Navigator.pop(context);
                  if (state.daysMovedThisWeek == 7) {
                    _showXpSnackbar('+3 XP + 🔥 Full week bonus! +5 XP');
                  } else {
                    _showXpSnackbar('+3 XP — Movement logged!');
                  }
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Open challenge detail page ────────────────────────
  void _openChallengeDetail() {
    if (state.activeChallenge == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ChallengeDetailScreen(onChanged: () => setState(() {})),
    ));
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Movement', style: TextStyle(fontWeight: FontWeight.w700)),
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
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row 1: Log Movement + Active Challenge (squares)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _buildLogMovementSquare()),
              const SizedBox(width: 12),
              Expanded(child: _buildActiveChallengeSquare()),
            ]),
          ),
          const SizedBox(height: 12),
          // Row 2: Weekly tracker
          _buildWeeklyCard(),
          const SizedBox(height: 12),
          // Row 3: Insight card
          _buildInsightCard(),
          const SizedBox(height: 12),
          // Row 4: Quests
          _buildQuestsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Log Movement Square ───────────────────────────────
  Widget _buildLogMovementSquare() {
    final logged = state.hasLoggedMovementToday;
    final count = state.todayMovements.length;
    return GestureDetector(
      onTap: _showMovementDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: logged ? Colors.deepPurple.shade200 : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: logged ? Colors.deepPurple : Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(logged ? '✅' : '🏃', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 12),
          const Text('Log Movement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            logged ? '$count logged today' : 'Tap to log',
            style: TextStyle(fontSize: 11,
                color: logged ? Colors.deepPurple.shade400 : Colors.grey.shade400),
          ),
          const SizedBox(height: 10),
          if (logged) ...[
            ...state.todayMovements.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Text(_movementEmoji(m.type), style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Expanded(child: Text('${m.type} • ${m.duration}m',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis)),
              ]),
            )),
            if (state.todayMovements.length > 2)
              Text('+${state.todayMovements.length - 2} more',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('+ Log',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
        ]),
      ),
    );
  }

  // ── Active Challenge Square ───────────────────────────
  Widget _buildActiveChallengeSquare() {
    final challenge = state.activeChallenge;
    return GestureDetector(
      onTap: challenge != null ? _openChallengeDetail : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: challenge != null ? Colors.orange.shade200 : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: challenge == null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 12),
                const Text('Active Challenge',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('No challenge active', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 10),
                Text('Pick a quest below to start',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade300, fontStyle: FontStyle.italic)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Big emoji
                Text(challenge['emoji'] as String, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(challenge['title'] as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (state.activeChallengeProgress / (challenge['target'] as int)).clamp(0.0, 1.0),
                    backgroundColor: Colors.orange.shade100,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade400),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${state.activeChallengeProgress} / ${challenge['target']} days',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('+${challenge['xp']} XP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade700)),
                ),
              ]),
      ),
    );
  }

  // ── Weekly Tracker Card ───────────────────────────────
  Widget _buildWeeklyCard() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDays = state.currentWeekDays;
    final movedDays = state.weeklyMovementDays;

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _CardHeader(emoji: '📅', emojiBackground: Colors.blue.shade50, title: 'This Week'),
        const Spacer(),
        Text('${state.daysMovedThisWeek} / 7 days',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade400)),
      ]),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final dayKey = weekDays[i];
          final isMoved = movedDays.contains(dayKey);
          final isToday = i == DateTime.now().weekday - 1;
          return Column(children: [
            Text(dayLabels[i],
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMoved ? Colors.deepPurple : isToday ? Colors.deepPurple.shade50 : Colors.grey.shade100,
                border: isToday && !isMoved ? Border.all(color: Colors.deepPurple, width: 2) : null,
              ),
              child: Center(child: isMoved
                  ? const Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))
                  : Text('·', style: TextStyle(color: Colors.grey.shade400, fontSize: 18))),
            ),
          ]);
        }),
      ),
      if (state.daysMovedThisWeek == 7) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🎉', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text('Full week! +5 XP bonus earned',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber)),
          ]),
        ),
      ],
    ]));
  }

  // ── Insight Card ──────────────────────────────────────
  Widget _buildInsightCard() {
    final days = state.daysMovedThisWeek;
    String insight;
    String insightEmoji;
    Color insightColor;

    if (days == 0) {
      insight = 'No movement logged this week yet. Even a short walk helps with PCOS symptoms!';
      insightEmoji = '💡';
      insightColor = Colors.blue;
    } else if (days <= 2) {
      insight = 'Good start! Research shows 150 min/week of moderate movement can improve insulin sensitivity in PCOS.';
      insightEmoji = '📈';
      insightColor = Colors.teal;
    } else if (days <= 4) {
      insight = 'You\'re building momentum! Consistent movement helps regulate cortisol, which is key for PCOS.';
      insightEmoji = '🌟';
      insightColor = Colors.deepPurple;
    } else if (days <= 6) {
      insight = 'Nearly there! Regular movement this week is supporting your hormonal balance. Keep it up!';
      insightEmoji = '🔥';
      insightColor = Colors.orange;
    } else {
      insight = 'Full week achieved! 🎉 Consistent weekly movement is one of the most impactful lifestyle changes for PCOS.';
      insightEmoji = '🏆';
      insightColor = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [insightColor.withOpacity(0.08), insightColor.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insightColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: insightColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(insightEmoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Weekly Insight',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8, color: insightColor)),
          const SizedBox(height: 5),
          Text(insight, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
        ])),
      ]),
    );
  }

  // ── Quests Card ───────────────────────────────────────
  Widget _buildQuestsCard() {
    final hasActive = state.activeChallenge != null;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardHeader(emoji: '🏆', emojiBackground: Colors.amber.shade50, title: 'Quests'),
      const SizedBox(height: 14),
      Row(
        children: AppState.presetChallenges.asMap().entries.map((entry) {
          final i = entry.key;
          final quest = entry.value;
          final isActive = state.activeChallengeId == quest['id'];
          final isCompleted = isActive && state.activeChallengeCompleted;

          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
            child: GestureDetector(
              onTap: (hasActive && !isActive) ? null : () {
                if (!isActive) {
                  setState(() => state.startChallenge(quest['id'] as String));
                  _showXpSnackbar('🎯 Quest started! Good luck!');
                } else {
                  _openChallengeDetail();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.deepPurple.shade50
                      : (hasActive ? Colors.grey.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? Colors.deepPurple.shade300 : Colors.grey.shade200,
                    width: isActive ? 1.5 : 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(quest['emoji'] as String, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(quest['title'] as String,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: (hasActive && !isActive) ? Colors.grey.shade400 : Colors.grey.shade800),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.deepPurple.withOpacity(0.1) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('+${quest['xp']} XP',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: isActive ? Colors.deepPurple : Colors.amber.shade700)),
                  ),
                  const SizedBox(height: 8),
                  if (isCompleted)
                    const Text('✅ Done!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green))
                  else if (isActive)
                    Text('${state.activeChallengeProgress}/${quest['target']} days',
                        style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade400, fontWeight: FontWeight.w600))
                  else
                    Text('${quest['target']} days',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ]),
              ),
            ),
          ));
        }).toList(),
      ),
      if (hasActive) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Text('ℹ️', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Text('Complete or tap your active quest to manage it',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
      ],
    ]));
  }

  String _movementEmoji(String type) {
    return const {
      'Walk': '🚶', 'Yoga': '🧘', 'Stretch': '🤸',
      'Workout': '🏋️', 'Cycle': '🚴', 'Run': '🏃',
    }[type] ?? '💪';
  }
}

// ── Challenge Detail Screen ───────────────────────────────
class _ChallengeDetailScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const _ChallengeDetailScreen({required this.onChanged});
  @override
  State<_ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<_ChallengeDetailScreen> {
  final state = AppState.instance;

  void _checkIn() {
    if (state.checkedInToday || state.activeChallengeCompleted) return;
    final challenge = state.activeChallenge!;
    setState(() => state.checkInChallenge());
    widget.onChanged();
    if (state.activeChallengeCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 Quest complete! +${challenge['xp']} XP'),
        backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Day checked in!', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurple, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _confirmAbandon() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Abandon quest?'),
      content: const Text('Your progress will be lost. You can start a new quest anytime.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            setState(() => state.clearChallenge());
            widget.onChanged();
            Navigator.pop(context); // dialog
            Navigator.pop(context); // detail screen
          },
          child: Text('Abandon', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final challenge = state.activeChallenge;
    if (challenge == null) {
      return Scaffold(appBar: AppBar(title: const Text('Quest')));
    }

    final target = challenge['target'] as int;
    final progress = state.activeChallengeProgress;
    final missed = state.challengeMissedDays.length;
    final progressFraction = (progress / target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(challenge['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _confirmAbandon,
            child: const Text('Abandon', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Hero
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Text(challenge['emoji'] as String, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(challenge['title'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(challenge['description'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StatPill(label: 'Progress', value: '$progress / $target'),
                const SizedBox(width: 12),
                _StatPill(label: 'Reward', value: '+${challenge['xp']} XP'),
                const SizedBox(width: 12),
                _StatPill(label: 'Missed', value: '$missed days'),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Progress bar
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('$progress / $target days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  backgroundColor: Colors.deepPurple.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.deepPurple.shade400),
                  minHeight: 12)),
              const SizedBox(height: 8),
              Text('${target - progress} days remaining',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ),

          const SizedBox(height: 16),

          // Day tracker grid
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Day Tracker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: List.generate(target, (i) {
                  final dayNum = i + 1;
                  final isChecked = i < progress;
                  final isMissed = state.challengeMissedDays.length > i &&
                      !isChecked;

                  return Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? Colors.deepPurple
                          : isMissed ? Colors.red.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChecked
                            ? Colors.deepPurple
                            : isMissed ? Colors.red.shade300 : Colors.grey.shade300),
                    ),
                    child: Center(child: isChecked
                        ? const Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))
                        : Text('$dayNum', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: isMissed ? Colors.red.shade400 : Colors.grey.shade400))),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _DotLegend(color: Colors.deepPurple, label: 'Completed'),
                const SizedBox(width: 14),
                _DotLegend(color: Colors.red.shade300, label: 'Missed (−2 XP)'),
                const SizedBox(width: 14),
                _DotLegend(color: Colors.grey.shade300, label: 'Upcoming'),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Abandonment warning
          if (missed > 0)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                const Text('⚠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  missed == 1
                      ? '1 missed day. Miss 2 more or 3 in a row and the quest will be abandoned.'
                      : '$missed missed days. ${3 - missed} more and the quest will be abandoned.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, height: 1.4))),
              ]),
            ),

          // Check-in button
          if (!state.activeChallengeCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.checkedInToday ? Colors.grey.shade200 : Colors.deepPurple,
                  foregroundColor: state.checkedInToday ? Colors.grey : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: state.checkedInToday ? null : _checkIn,
                child: Text(
                  state.checkedInToday ? '✓ Checked in today' : '✅ Mark today as done',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            )
          else
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🎉', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Text('Quest Complete!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7))),
    ]),
  );
}

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _DotLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
  ]);
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
