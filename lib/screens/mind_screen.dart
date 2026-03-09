import 'package:flutter/material.dart';
import '../widgets/xp_popup.dart';
import '../widgets/bottom_nav.dart';
import '../state/app_state.dart';

class MindScreen extends StatefulWidget {
  const MindScreen({super.key});
  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> {
  final state = AppState.instance;

  // ── Mood popup ────────────────────────────────────────
  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How are you feeling today?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AppState.moodOptions.map((mood) {
              final isSelected = state.todayMood == mood['label'];
              return GestureDetector(
                onTap: () {
                  setState(() => state.logMood(mood['label']!));
                  Navigator.pop(context);
                  XpPopup.show(context, '+2 XP ⭐ Mood logged!');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFD6CE) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFF4826A) : Colors.transparent, width: 2),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(mood['emoji']!, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text(mood['label']!, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF9E4A3A) : Colors.grey.shade600)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  // ── Sleep popup ───────────────────────────────────────
  void _showSleepPicker() {
    double selectedHours = state.sleepHours ?? 7.0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('How many hours did you sleep?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('${selectedHours.toStringAsFixed(1)} hrs',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                    color: const Color(0xFFB85A47))),
            Slider(
              value: selectedHours, min: 0, max: 12, divisions: 24,
              activeColor: const Color(0xFFF4826A),
              label: '${selectedHours.toStringAsFixed(1)} hrs',
              onChanged: (v) => setSheet(() => selectedHours = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4826A), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  setState(() => state.logSleep(selectedHours));
                  Navigator.pop(context);
                  XpPopup.show(context, '+2 XP ⭐ Sleep logged!');
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Journal ───────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openJournalForDate(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final existing = state.getEntryForDate(date);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _JournalScreen(
        date: date,
        initialText: existing?.text ?? '',
        existingEntry: existing,
        readOnly: !isToday,
        onSave: isToday ? (text) => setState(() => state.saveJournalEntry(text)) : null,
        onDelete: isToday ? (entry) => setState(() => state.deleteJournalEntry(entry)) : null,
      ),
    )).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // scaffold bg from theme
      appBar: AppBar(
        title: const Text('Mind', style: TextStyle(fontWeight: FontWeight.w700)),
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
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(children: [
          // Affirmation — small fixed height
          _buildAffirmationCard(),
          const SizedBox(height: 10),
          // Mood + Sleep side by side squares
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _buildMoodSquare()),
              const SizedBox(width: 10),
              Expanded(child: _buildSleepSquare()),
            ]),
          ),
          const SizedBox(height: 10),
          // Journal — takes all remaining space
          Expanded(child: _buildJournalCard()),
        ]),
      ),
    );
  }

  // ── Affirmation ───────────────────────────────────────
  Widget _buildAffirmationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF9E4A3A), const Color(0xFFF4826A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFF4826A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DAILY AFFIRMATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: Theme.of(context).cardColor.withOpacity(0.7))),
        const SizedBox(height: 6),
        Text('"${state.todayAffirmation}"',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontStyle: FontStyle.italic, height: 1.4),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Mood Square ───────────────────────────────────────
  Widget _buildMoodSquare() {
    final logged = state.moodLoggedToday;
    final mood = AppState.moodOptions.firstWhere(
      (m) => m['label'] == state.todayMood,
      orElse: () => {'emoji': '😊', 'label': ''},
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: logged ? Colors.orange.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Align(
          alignment: Alignment.topCenter,
          child: Text('Mood', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        if (logged) ...[
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => setState(() => state.logMood(state.todayMood!)),
              child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 4),
          Text(mood['emoji']!, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 4),
          Text(mood['label']!, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFFB85A47))),
        ] else ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showMoodPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4826A),
                borderRadius: BorderRadius.circular(12)),
              child: const Text('+ Log Mood',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ]),
    );
  }

  // ── Sleep Square ──────────────────────────────────────
  Widget _buildSleepSquare() {
    final logged = state.sleepLoggedToday;
    final hours = state.sleepHours;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: logged ? Colors.indigo.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Align(
          alignment: Alignment.topCenter,
          child: Text('Sleep', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        if (logged && hours != null) ...[
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => setState(() => state.clearSleep()),
              child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 4),
          Text('${hours.toStringAsFixed(1)} hrs',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade600, height: 1)),
          const SizedBox(height: 4),
          Text(state.sleepQualityLabel,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ] else ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showSleepPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4826A),
                borderRadius: BorderRadius.circular(12)),
              child: const Text('+ Log Sleep',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ]),
    );
  }

  // ── Journal Card with Calendar ────────────────────────
  Widget _buildJournalCard() {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        const hPad = 14.0;
        const vPad = 12.0;
        final innerWidth  = constraints.maxWidth  - hPad * 2;
        final innerHeight = constraints.maxHeight - vPad * 2;
        final cellSize    = innerWidth / 7;
        // Reserve: header(32) + gap(8) + dow-labels(16) + gap(6) = 62
        final gridHeight  = (innerHeight - 62).clamp(0.0, double.infinity);
        final rowHeight   = gridHeight / rowCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(width: 30, height: 30,
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(9)),
                child: const Center(child: Text('📓', style: TextStyle(fontSize: 15)))),
              const SizedBox(width: 9),
              const Text('Journal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_monthName(now.month)} ${now.year}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 8),
            // Day-of-week labels
            Row(children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) =>
              SizedBox(width: cellSize, child: Center(child: Text(d,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF555555)))))).toList()),
            const SizedBox(height: 6),
            // Grid
            SizedBox(
              height: rowHeight * rowCount,
              child: Column(
                children: List.generate(rowCount, (row) => SizedBox(
                  height: rowHeight,
                  child: Row(children: List.generate(7, (col) {
                    final day = row * 7 + col - startOffset + 1;
                    if (day < 1 || day > daysInMonth) return SizedBox(width: cellSize);

                    final date    = DateTime(now.year, now.month, day);
                    final isToday = day == now.day;
                    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
                    final hasEntry = state.getEntryForDate(date) != null;
                    final inner   = (rowHeight * 0.78).clamp(24.0, 46.0);

                    return GestureDetector(
                      onTap: isFuture ? null : () => _openJournalForDate(date),
                      child: SizedBox(
                        width: cellSize, height: rowHeight,
                        child: Center(child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: inner, height: inner,
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFFF4826A)
                                : hasEntry ? const Color(0xFFFFF0ED) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: hasEntry && !isToday
                                ? Border.all(color: const Color(0xFFF4826A).withOpacity(0.35), width: 1.5)
                                : null,
                          ),
                          child: Center(child: isToday
                              ? Text('✏️', style: TextStyle(fontSize: inner * 0.4))
                              : hasEntry
                                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text('$day', style: TextStyle(
                                          fontSize: inner * 0.34, fontWeight: FontWeight.w700,
                                          color: const Color(0xFFB85A47), height: 1.1)),
                                      Container(width: 4, height: 4,
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF4826A).withOpacity(0.5),
                                              shape: BoxShape.circle)),
                                    ])
                                  : Text('$day', style: TextStyle(
                                      fontSize: inner * 0.34, fontWeight: FontWeight.w600,
                                      color: isFuture
                                          ? const Color(0xFFBBBBBB)
                                          : const Color(0xFF444444)))),
                        )),
                      ),
                    );
                  })),
                )),
              ),
            ),
          ]),
        );
      }),
    );
  }

  String _monthName(int m) => const ['','January','February','March','April','May','June',
      'July','August','September','October','November','December'][m];
}

// ── Journal Screen ────────────────────────────────────────
class _JournalScreen extends StatefulWidget {
  final DateTime date;
  final String initialText;
  final JournalEntry? existingEntry;
  final bool readOnly;
  final void Function(String)? onSave;
  final void Function(JournalEntry)? onDelete;

  const _JournalScreen({required this.date, required this.initialText,
      required this.existingEntry, required this.readOnly, this.onSave, this.onDelete});

  @override
  State<_JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<_JournalScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _save() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSave?.call(_controller.text.trim());
    Navigator.pop(context);
    XpPopup.show(context, '+5 XP ⭐ Journal saved!');
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete entry?'),
      content: const Text('This will remove today\'s journal entry and deduct 5 XP.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            widget.onDelete?.call(widget.existingEntry!);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // scaffold bg from theme
      appBar: AppBar(
        title: Text(_fmt(widget.date),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        backgroundColor: const Color(0xFFF4826A), foregroundColor: Colors.white, elevation: 0,
        actions: [
          if (!widget.readOnly && widget.existingEntry != null)
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: _confirmDelete),
          if (!widget.readOnly)
            TextButton(onPressed: _save,
                child: const Text('Save', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: widget.readOnly
            ? (widget.existingEntry == null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📓', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No entry for this day',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                  ]))
                : Container(width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: SingleChildScrollView(child: Text(widget.existingEntry!.text,
                        style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF333333))))))
            : TextField(
                controller: _controller, maxLines: null, expands: true,
                autofocus: true, textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write freely — this is your space...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: const Color(0xFFF4826A), width: 1.5)),
                  filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(16)),
                style: const TextStyle(fontSize: 15, height: 1.6)),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
