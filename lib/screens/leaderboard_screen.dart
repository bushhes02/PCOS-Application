import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('points', descending: true)
          .limit(20)
          .get();
      setState(() {
        _entries = snap.docs.map((d) => {
          'uid':    d.id,
          'name':   d['name']   ?? 'Warrior',
          'points': d['points'] ?? 0,
        }).toList();
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Leaderboard error: $e');
      setState(() => _loading = false);
    }
  }

  // Find current user's rank
  int get _myRank {
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i]['uid'] == _myUid) return i + 1;
    }
    return -1;
  }

  int get _myPoints {
    for (final e in _entries) {
      if (e['uid'] == _myUid) return e['points'] as int;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF4826A)))
          : RefreshIndicator(
              color: const Color(0xFFF4826A),
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── Hero header ──────────────────────────────
                  SliverToBoxAdapter(
                    child: _Header(
                      myRank: _myRank,
                      myPoints: _myPoints,
                      onRefresh: _load,
                    ),
                  ),

                  // ── Top 3 podium ─────────────────────────────
                  if (_entries.length >= 3)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _Podium(
                            entries: _entries,
                            myUid: _myUid,
                            anim: _animCtrl),
                      ),
                    ),

                  // ── List ─────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          // Skip top 3 if podium is shown
                          final listEntries = _entries.length >= 3
                              ? _entries.sublist(3)
                              : _entries;
                          if (i >= listEntries.length) return null;
                          final entry = listEntries[i];
                          final rank = _entries.length >= 3 ? i + 4 : i + 1;
                          final isMe = entry['uid'] == _myUid;
                          final delay = i * 0.06;
                          return AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (_, child) {
                              final t = ((_animCtrl.value - delay) / (1 - delay))
                                  .clamp(0.0, 1.0);
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - t)),
                                  child: child,
                                ),
                              );
                            },
                            child: _ListTile(
                              rank: rank,
                              entry: entry,
                              isMe: isMe,
                            ),
                          );
                        },
                        childCount: _entries.length >= 3
                            ? _entries.length - 3
                            : _entries.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

// ── Header with your rank ─────────────────────────────────
class _Header extends StatelessWidget {
  final int myRank;
  final int myPoints;
  final VoidCallback onRefresh;
  const _Header(
      {required this.myRank,
      required this.myPoints,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4826A), Color(0xFFE8604A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Leaderboard',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Cysterhood rankings',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 0.2)),
              const SizedBox(height: 20),

              // Your rank card
              if (myRank > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(children: [
                    const Text('🏅',
                        style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your rank',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500)),
                          Text('#$myRank',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1)),
                        ]),
                    const Spacer(),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total XP',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500)),
                          Text('$myPoints ⭐',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1)),
                        ]),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final String? myUid;
  final AnimationController anim;
  const _Podium(
      {required this.entries, required this.myUid, required this.anim});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFFFCC00),
      const Color(0xFFB0BEC5),
      const Color(0xFFCD7F32),
    ];
    final heights = [110.0, 80.0, 60.0];
    // Order: 2nd, 1st, 3rd
    final order = [1, 0, 2];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF4826A).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: order.map((idx) {
            final entry = entries[idx];
            final isMe = entry['uid'] == myUid;
            final color = colors[idx];
            final delay = idx * 0.15;
            return Expanded(
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, child) {
                  final t =
                      ((anim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, 30 * (1 - t)), child: child),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(medals[idx],
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    CircleAvatar(
                      radius: idx == 0 ? 24 : 20,
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(
                        (entry['name'] as String).isNotEmpty
                            ? (entry['name'] as String)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontSize: idx == 0 ? 20 : 16,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMe
                          ? 'You'
                          : (entry['name'] as String).split(' ').first,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isMe
                              ? const Color(0xFFF4826A)
                              : const Color(0xFF1E1610)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text('${entry['points']} XP',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    const SizedBox(height: 6),
                    Container(
                      height: heights[idx],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.1)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        border: Border.all(
                            color: color.withOpacity(0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text('#${idx + 1}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: color)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ── List tile ─────────────────────────────────────────────
class _ListTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  const _ListTile(
      {required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFF4826A).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? const Color(0xFFF4826A).withOpacity(0.35)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Rank badge
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFFF4826A).withOpacity(0.15)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('#$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isMe
                        ? const Color(0xFFF4826A)
                        : const Color(0xFF888888))),
          ),
        ),
        const SizedBox(width: 12),
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor:
              const Color(0xFFF4826A).withOpacity(0.12),
          child: Text(
            (entry['name'] as String).isNotEmpty
                ? (entry['name'] as String)[0].toUpperCase()
                : '?',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF4826A)),
          ),
        ),
        const SizedBox(width: 12),
        // Name
        Expanded(
          child: Text(
            isMe ? '${entry['name']} (you)' : entry['name'],
            style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isMe ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1E1610)),
          ),
        ),
        // XP
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFFFCC00).withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text('${entry['points']} XP',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8960A))),
          ]),
        ),
      ]),
    );
  }
}
