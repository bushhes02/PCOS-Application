import 'package:flutter/material.dart';
import '../widgets/xp_popup.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final state = AppState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => state.checkMissedChallengeDays());
      final frozeUsed = state.checkStreakOnOpen();
      if (frozeUsed) {
        XpPopup.show(context, '🧊 Freeze used!', 
            color: const Color(0xFF5B9BD5));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Top notification banner ───────────────────────────

  void _showMovementDialog() {
    String selectedType = 'Walk';
    int selectedDuration = 30;
    String customType = '';
    bool useCustom = false;
    final customCtrl = TextEditingController();
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
            const Text('Log Movement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Text('Movement Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              {'label': 'Walk',    'emoji': '🚶'},
              {'label': 'Yoga',    'emoji': '🧘'},
              {'label': 'Stretch', 'emoji': '🤸'},
              {'label': 'Workout', 'emoji': '🏋️'},
              {'label': 'Cycle',   'emoji': '🚴'},
              {'label': 'Run',     'emoji': '🏃'},
              {'label': 'Other',   'emoji': ''},
            ].map((type) {
              final isSel = useCustom ? type['label'] == 'Other' : selectedType == type['label'];
              return GestureDetector(
                onTap: () => setSheet(() {
                  if (type['label'] == 'Other') {
                    useCustom = true;
                    selectedType = 'Other';
                  } else {
                    useCustom = false;
                    selectedType = type['label']!;
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFF4826A) : const Color(0xFFFFF0ED),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(type['emoji']!.isEmpty ? type['label']! : '${type['emoji']} ${type['label']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF9E4A3A))),
                ),
              );
            }).toList()),
            if (useCustom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: customCtrl,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) => customType = v,
                decoration: InputDecoration(
                  hintText: 'e.g. Swimming, Dancing...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true, fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Duration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Center(
              child: Text('$selectedDuration min',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                      color: Color(0xFFB85A47))),
            ),
            Slider(
              value: selectedDuration.toDouble(),
              min: 5, max: 120, divisions: 23,
              activeColor: const Color(0xFFF4826A),
              label: '$selectedDuration min',
              onChanged: (v) => setSheet(() => selectedDuration = v.round()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4826A), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  final finalType = useCustom
                      ? (customType.trim().isNotEmpty ? customType.trim() : 'Other')
                      : selectedType;
                  setState(() => state.logMovement(type: finalType, duration: selectedDuration));
                  Navigator.pop(context);
                  XpPopup.show(context, state.daysMovedThisWeek == 7 ? '+8 XP ⭐' : '+3 XP ⭐');
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

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
      // scaffold bg from theme
      appBar: AppBar(
        title: const Text('Movement', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF4826A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Freeze token pill
          if (state.freezeTokens > 0)
            Container(
              margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5B9BD5).withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5B9BD5).withOpacity(0.5))),
              child: Row(children: [
                const Text('🧊', style: TextStyle(fontSize: 14)), const SizedBox(width: 4),
                Text('${state.freezeTokens}', style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              ]),
            ),
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
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      // ── No scroll — everything fits in Column with Expanded
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(children: [
          // Row 1: Log Movement + Active Challenge squares
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
          // Row 4: Quests — Expanded to fill remaining space
          Expanded(child: _buildQuestsCard()),
        ]),
      ),
    );
  }

  // ── Log Movement Square ───────────────────────────────
  Widget _buildLogMovementSquare() {
    final movements = state.todayMovements;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: movements.isNotEmpty
            ? const Color(0xFFF4826A).withOpacity(0.4) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          const Text('Movement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          if (movements.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...movements.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${e.value.type} · ${e.value.duration} min',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => state.removeMovement(e.key)),
                    child: Icon(Icons.close, size: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _showMovementDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4826A),
                borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('+ Log',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Challenge Square ───────────────────────────
  Widget _buildActiveChallengeSquare() {
    final challenge = state.activeChallenge;
    return GestureDetector(
      onTap: challenge != null ? _openChallengeDetail : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: challenge != null ? Colors.orange.shade200 : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: challenge == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 10),
                  const Text('Active Quest',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Pick a quest below',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      textAlign: TextAlign.center),
                ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(challenge['emoji'] as String,
                      style: const TextStyle(fontSize: 38), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(challenge['title'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (state.activeChallengeProgress / (challenge['target'] as int)).clamp(0.0, 1.0),
                      backgroundColor: Colors.orange.shade100,
                      valueColor: AlwaysStoppedAnimation(Colors.orange.shade400),
                      minHeight: 6)),
                  const SizedBox(height: 5),
                  Text('${state.activeChallengeProgress} / ${challenge['target']} days',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6), borderRadius: BorderRadius.circular(8)),
                    child: Text('+${challenge['xp']} XP',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: const Color(0xFFB8960A)))),
                ]),
      ),
    );
  }

  // ── Weekly Tracker ────────────────────────────────────
  Widget _buildWeeklyCard() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDays  = state.currentWeekDays;
    final movedDays = state.weeklyMovementDays;

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('This Week', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('${state.daysMovedThisWeek} / 7 days',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF4826A).withOpacity(0.7))),
      ]),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final dayKey  = weekDays[i];
          final isMoved = movedDays.contains(dayKey);
          final isToday = i == DateTime.now().weekday - 1;
          return Column(children: [
            Text(dayLabels[i],
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMoved ? const Color(0xFFF4826A) : isToday ? const Color(0xFFFFF0ED) : Colors.grey.shade100,
                border: isToday && !isMoved ? Border.all(color: const Color(0xFFF4826A), width: 2) : null),
              child: Center(child: isMoved
                  ? Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))
                  : Text('·', style: TextStyle(color: Colors.grey.shade400, fontSize: 16))),
            ),
          ]);
        }),
      ),
      if (state.daysMovedThisWeek == 7) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBE6), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE566))),
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
    final (insight, emoji, color) = switch (days) {
      0         => ('No movement yet this week. Even a short walk helps with PCOS symptoms!', '💡', Colors.blue),
      1 || 2    => ('Good start! 150 min/week of moderate movement improves insulin sensitivity in PCOS.', '📈', Colors.teal),
      3 || 4    => ('Building momentum! Consistent movement helps regulate cortisol — key for PCOS.', '🌟', const Color(0xFFF4826A)),
      5 || 6    => ('Nearly a full week! Movement is supporting your hormonal balance. Keep going!', '🔥', Colors.orange),
      _         => ('Full week! 🎉 Consistent movement is one of the most impactful changes for PCOS.', '🏆', Colors.green),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Weekly Insight', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 0.8, color: color)),
          const SizedBox(height: 4),
          Text(insight, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ── Quests Card ───────────────────────────────────────
  Widget _buildQuestsCard() {
    final hasActive = state.activeChallenge != null;
    // Can't use _Card here — Expanded inside a Container with no height constraint overflows.
    // Use a raw Container that fills the Expanded slot from the parent Column.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: AppState.presetChallenges.asMap().entries.map((entry) {
            final i      = entry.key;
            final quest  = entry.value;
            final isActive    = state.activeChallengeId == quest['id'];
            final isCompleted = isActive && state.activeChallengeCompleted;
            final isDisabled  = hasActive && !isActive;

            return Expanded(child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
              child: GestureDetector(
                onTap: isDisabled ? null : () {
                  if (!isActive) {
                    setState(() => state.startChallenge(quest['id'] as String));
                    // no popup on quest start
                  } else {
                    _openChallengeDetail();
                  }
                },
                child: Opacity(
                  opacity: isDisabled ? 0.45 : 1.0,
                  child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFFF0ED)
                        : isDisabled ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFFF4826A).withOpacity(0.6) : Colors.grey.shade200,
                      width: isActive ? 1.5 : 1)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quest['emoji'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(quest['title'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade800),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFF4826A).withOpacity(0.1) : const Color(0xFFFFFBE6),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text('+${quest['xp']} XP',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: isActive ? const Color(0xFFF4826A) : const Color(0xFFB8960A))),
                      ),
                      const SizedBox(height: 6),
                      if (isCompleted)
                        const Text('✅ Done!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green))
                      else if (isActive)
                        Text('${state.activeChallengeProgress}/${quest['target']} days',
                            style: TextStyle(fontSize: 10, color: const Color(0xFFF4826A).withOpacity(0.7), fontWeight: FontWeight.w600))
                      else
                        Text('${quest['target']} days',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                ), // end Opacity
              ),
            ));
          }).toList(),
        ),
      ),
    ]));
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


  @override
  void dispose() {
    super.dispose();
  }

  void _checkIn() {
    final challenge = state.activeChallenge!;
    setState(() => state.checkInChallenge());
    widget.onChanged();
    if (state.activeChallengeCompleted) {
      XpPopup.show(context, '+${challenge['xp']} XP ⭐', color: const Color(0xFFFFCC00));
    }
  }

  void _uncheckIn() {
    setState(() => state.uncheckInChallenge());
    widget.onChanged();
    // no popup on undo
  }

  void _confirmAbandon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🚩', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(height: 16),
          const Text('Abandon quest?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1610))),
          const SizedBox(height: 8),
          Text('Your progress will be lost. You can start a new quest anytime.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Cancel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1610)))),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () {
                setState(() => state.clearChallenge());
                widget.onChanged();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Abandon',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = state.activeChallenge;
    if (challenge == null) return Scaffold(appBar: AppBar(title: const Text('Quest')));

    final target   = challenge['target'] as int;
    final progress = state.activeChallengeProgress;
    final missed   = state.challengeMissedDays.length;

    return Scaffold(
      // scaffold bg from theme
      appBar: AppBar(
        title: Text(challenge['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        backgroundColor: const Color(0xFFF4826A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _confirmAbandon,
            child: const Text('Abandon', style: TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Hero banner
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF9E4A3A), const Color(0xFFF4826A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Text(challenge['emoji'] as String, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(challenge['title'] as String,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(challenge['description'] as String,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).cardColor.withOpacity(0.7)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StatPill(label: 'Progress', value: '$progress / $target'),
                const SizedBox(width: 10),
                _StatPill(label: 'Reward',   value: '+${challenge['xp']} XP'),
                const SizedBox(width: 10),
                _StatPill(label: 'Missed',   value: '$missed days'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Progress bar
          _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('$progress / $target days',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (progress / target).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFFD6CE),
                valueColor: AlwaysStoppedAnimation(const Color(0xFFF4826A)),
                minHeight: 12)),
            const SizedBox(height: 6),
            Text('${target - progress} days remaining',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ])),
          const SizedBox(height: 12),

          // Day tracker grid
          _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Day Tracker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: List.generate(target, (i) {
                final isChecked = i < progress;
                final isMissed  = i < state.challengeMissedDays.length && !isChecked;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFFF4826A)
                        : isMissed ? Colors.red.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked ? const Color(0xFFF4826A)
                          : isMissed ? Colors.red.shade300 : Colors.grey.shade300,
                      width: 1),
                  ),
                  child: Center(child: isChecked
                      ? const Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))
                      : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: isMissed ? Colors.red.shade400 : Colors.grey.shade400))),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _DotLegend(color: const Color(0xFFF4826A), label: 'Checked in'),
              const SizedBox(width: 12),
              _DotLegend(color: Colors.red.shade300, label: 'Missed (−2 XP)'),
              const SizedBox(width: 12),
              _DotLegend(color: Colors.grey.shade300, label: 'Upcoming'),
            ]),
          ])),
          const SizedBox(height: 12),

          // Abandonment warning
          if (missed > 0) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                const Text('⚠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '$missed missed ${missed == 1 ? 'day' : 'days'}. '
                  '${missed >= 3 ? 'Quest will be abandoned soon!' : '${3 - missed} more and the quest is abandoned.'}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Check-in / uncheck / completed
          if (state.activeChallengeCompleted)
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
            )
          else
            Column(children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.checkedInToday ? Colors.grey.shade200 : const Color(0xFFF4826A),
                    foregroundColor: state.checkedInToday ? Colors.grey.shade600 : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: state.checkedInToday ? _uncheckIn : _checkIn,
                  child: Text(
                    state.checkedInToday ? 'Undo' : 'Mark today as done!',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).cardColor.withOpacity(0.7))),
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

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)),
    child: child,
  );
}

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
