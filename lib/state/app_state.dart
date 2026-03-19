import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MealType { breakfast, lunch, dinner }

class MovementLog {
  final String type;
  final int duration;
  final int points;
  MovementLog({required this.type, required this.duration, required this.points});
}

class JournalEntry {
  final String text;
  final DateTime date;
  JournalEntry({required this.text, required this.date});

  Map<String, dynamic> toMap() => {
    'text': text,
    'date': date.toIso8601String(),
  };
  static JournalEntry fromMap(Map map) => JournalEntry(
    text: map['text'] as String,
    date: DateTime.parse(map['date'] as String),
  );
}

class FoodItem {
  final String name;
  final String portion;
  final bool   fromDatabase; // true = selected from USDA lookup, false = manually typed

  FoodItem({
    required this.name,
    required this.portion,
    this.fromDatabase = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'portion': portion,
    'fromDatabase': fromDatabase,
  };

  static FoodItem fromMap(Map map) => FoodItem(
    name:         map['name']         as String,
    portion:      map['portion']      as String,
    fromDatabase: (map['fromDatabase'] ?? false) as bool,
  );
}

class AppState {
  // ── Singleton ─────────────────────────────────────────
  static AppState? _instance;
  static AppState get instance {
    assert(_instance != null,
        'AppState not initialised — call AppState.initForUser() after login');
    return _instance!;
  }

  static Future<void> initForUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    assert(uid != null, 'No Firebase user when initForUser() was called');
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('data')
        .doc('state');
    final snap = await doc.get();
    _instance = AppState._load(doc, snap.data() ?? {});
  }

  static Future<void> resetForSignOut() async {
    _instance = null;
  }

  // ── Private fields ─────────────────────────────────────
  late final DocumentReference _doc;

  AppState._load(DocumentReference doc, Map<String, dynamic> data) {
    _doc = doc;

    points            = (data['points']            ?? 0) as int;
    streak            = (data['streak']            ?? 0) as int;
    hasLoggedToday    = (data['hasLoggedToday']    ?? false) as bool;
    freezeTokens      = (data['freezeTokens']      ?? 0) as int;
    lastStreakDate     = data['lastStreakDate']     as String?;
    waterGlasses      = (data['waterGlasses']      ?? 0) as int;
    waterGoalMetToday = (data['waterGoalMetToday'] ?? false) as bool;
    waterXpToday      = (data['waterXpToday']      ?? 0) as int;

    todayMood        = data['todayMood']        as String?;
    moodLoggedToday  = (data['moodLoggedToday']  ?? false) as bool;
    sleepHours       = (data['sleepHours']  as num?)?.toDouble();
    sleepLoggedToday = (data['sleepLoggedToday'] ?? false) as bool;

    final rawEntries = data['journalEntries'] as List? ?? [];
    journalEntries = rawEntries
        .map((e) => JournalEntry.fromMap(Map.from(e as Map)))
        .toList();

    final rawWeekly = data['weeklyMovementDays'] as List? ?? [];
    weeklyMovementDays = List<String>.from(rawWeekly);
    weeklyBonusAwarded = (data['weeklyBonusAwarded'] ?? false) as bool;

    activeChallengeId        = data['activeChallengeId']        as String?;
    activeChallengeProgress  = (data['activeChallengeProgress']  ?? 0) as int;
    activeChallengeCompleted = (data['activeChallengeCompleted'] ?? false) as bool;
    challengeStartDate       = data['challengeStartDate']       as String?;
    challengeCheckedDays = Set<String>.from(
        (data['challengeCheckedDays'] as List? ?? []));
    challengeMissedDays = List<String>.from(
        (data['challengeMissedDays'] as List? ?? []));
    challengeTotalMissed = (data['challengeTotalMissed'] ?? 0) as int;

    final rawMoodHistory = data['moodHistory'] as List? ?? [];
    moodHistory = rawMoodHistory
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawMovementHistory = data['movementHistory'] as List? ?? [];
    movementHistory = rawMovementHistory
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawSleepHistory = data['sleepHistory'] as List? ?? [];
    sleepHistory = rawSleepHistory
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawWaterHistory = data['waterHistory'] as List? ?? [];
    waterHistory = rawWaterHistory
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawMealHistory = data['mealHistory'] as Map? ?? {};
    mealHistory = Map<String, bool>.from(rawMealHistory);

    final rawMealDayHistory = data['mealDayHistory'] as Map? ?? {};
    mealDayHistory = rawMealDayHistory.map((date, meals) {
      final mealsMap = Map<String, dynamic>.from(meals as Map);
      return MapEntry(date as String, mealsMap.map((mealType, items) {
        final itemList = (items as List).map((e) => FoodItem.fromMap(Map.from(e as Map))).toList();
        return MapEntry(mealType as String, itemList);
      }));
    });

    cachedInsight     = data['cachedInsight']     as String?;
    cachedInsightDate = data['cachedInsightDate'] as String?;
    selectedAvatar    = data['selectedAvatar']    as String?;

    for (final type in MealType.values) {
      final raw = data['meal_${type.name}'] as List? ?? [];
      mealItems[type] = raw
          .map((e) => FoodItem.fromMap(Map.from(e as Map))).toList();
    }
    final rawSnacks = data['snackItems'] as List? ?? [];
    snackItems = rawSnacks
        .map((e) => FoodItem.fromMap(Map.from(e as Map))).toList();

    final rawTodayMov = data['todayMovements'] as List? ?? [];
    todayMovements = rawTodayMov.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return MovementLog(
        type:     m['type']     as String,
        duration: m['duration'] as int,
        points:   m['points']   as int,
      );
    }).toList();

    _resetIfNewDay(data['lastActiveDate'] as String?);
  }

  // ── Save — fire and forget, UI stays instant ───────────
  void _updateLeaderboard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('leaderboard').doc(user.uid).set({
      'name':      user.displayName ?? 'Warrior',
      'points':    points,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _save() {
    _doc.set(_toMap(), SetOptions(merge: true));
    _updateLeaderboard();
  }

  Map<String, dynamic> _toMap() => {
    'points':                  points,
    'streak':                  streak,
    'hasLoggedToday':          hasLoggedToday,
    'freezeTokens':            freezeTokens,
    'lastStreakDate':           lastStreakDate,
    'waterGlasses':            waterGlasses,
    'waterGoalMetToday':       waterGoalMetToday,
    'waterXpToday':            waterXpToday,
    'todayMood':               todayMood,
    'moodLoggedToday':         moodLoggedToday,
    'sleepHours':              sleepHours,
    'sleepLoggedToday':        sleepLoggedToday,
    'journalEntries':          journalEntries.map((e) => e.toMap()).toList(),
    'weeklyMovementDays':      weeklyMovementDays,
    'weeklyBonusAwarded':      weeklyBonusAwarded,
    'activeChallengeId':       activeChallengeId,
    'activeChallengeProgress': activeChallengeProgress,
    'activeChallengeCompleted':activeChallengeCompleted,
    'challengeStartDate':      challengeStartDate,
    'challengeCheckedDays':    challengeCheckedDays.toList(),
    'challengeMissedDays':     challengeMissedDays,
    'challengeTotalMissed':    challengeTotalMissed,
    'moodHistory':             moodHistory,
    'movementHistory':         movementHistory,
    'sleepHistory':            sleepHistory,
    'waterHistory':            waterHistory,
    'mealHistory':             mealHistory,
    'mealDayHistory':          mealDayHistory.map((date, meals) =>
        MapEntry(date, meals.map((type, items) =>
            MapEntry(type, items.map((e) => e.toMap()).toList())))),
    'cachedInsight':           cachedInsight,
    'cachedInsightDate':       cachedInsightDate,
    'selectedAvatar':          selectedAvatar,
    'todayMovements':          todayMovements.map((m) => {
      'type': m.type, 'duration': m.duration, 'points': m.points,
    }).toList(),
    for (final type in MealType.values)
      'meal_${type.name}': mealItems[type]!.map((e) => e.toMap()).toList(),
    'snackItems': snackItems.map((e) => e.toMap()).toList(),
  };

  // ---------- CORE ----------
  int  points = 0;
  int  streak = 0;
  bool hasLoggedToday = false;
  int  freezeTokens = 0;
  String? lastStreakDate;

  // ---------- MOVEMENT ----------
  List<MovementLog> todayMovements    = [];
  List<String>      weeklyMovementDays = [];
  bool              weeklyBonusAwarded = false;

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  bool get hasLoggedMovementToday => weeklyMovementDays.contains(_todayKey());

  List<String> get currentWeekDays {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    });
  }

  int get daysMovedThisWeek =>
      currentWeekDays.where((d) => weeklyMovementDays.contains(d)).length;

  void logMovement({required String type, required int duration}) {
    final today = _todayKey();
    final alreadyLoggedToday = weeklyMovementDays.contains(today);
    todayMovements.add(MovementLog(type: type, duration: duration, points: 3));
    movementHistory.removeWhere((e) => e['date'] == today);
    movementHistory.add({'date': today, 'type': type, 'duration_minutes': duration});
    if (!alreadyLoggedToday) {
      weeklyMovementDays.add(today);
      points += 3;
      if (daysMovedThisWeek == 7 && !weeklyBonusAwarded) {
        points += 5;
        weeklyBonusAwarded = true;
      }
      if (!hasLoggedToday) {
        streak += 1;
        hasLoggedToday = true;
        lastStreakDate = _todayKey();
        _checkFreezeReward();
      }
    }
    _save();
  }

  void removeMovement(int index) {
    todayMovements.removeAt(index);
    if (todayMovements.isEmpty) {
      weeklyMovementDays.remove(_todayKey());
      points -= 3;
      if (points < 0) points = 0;
      if (hasLoggedToday) {
        hasLoggedToday = false;
        if (streak > 0) streak -= 1;
      }
    }
    _save();
  }

  // ---------- CHALLENGES ----------
  static const List<Map<String, dynamic>> presetChallenges = [
    {
      'id': 'steps_5k_14',
      'title': '5K Steps for 14 Days',
      'description': 'Log a 5K steps walk every day for 14 days',
      'emoji': '🚶',
      'target': 14,
      'durationDays': 14,
      'xp': 20,
    },
    {
      'id': 'cycling_7',
      'title': 'Cycling Every Day for 7 Days',
      'description': 'Log cycling as your movement every day for a week',
      'emoji': '🚴',
      'target': 7,
      'durationDays': 7,
      'xp': 10,
    },
    {
      'id': 'variety_7',
      'title': 'Different Movement Every Day',
      'description': 'Try a different type of movement each day for 7 days',
      'emoji': '🌀',
      'target': 7,
      'durationDays': 7,
      'xp': 10,
    },
  ];

  String?      activeChallengeId;
  int          activeChallengeProgress = 0;
  bool         activeChallengeCompleted = false;
  String?      challengeStartDate;
  Set<String>  challengeCheckedDays = {};
  List<String> challengeMissedDays  = [];
  int          challengeTotalMissed  = 0;

  bool get checkedInToday => challengeCheckedDays.contains(_todayKey());

  Map<String, dynamic>? get activeChallenge {
    if (activeChallengeId == null) return null;
    try {
      return presetChallenges.firstWhere((c) => c['id'] == activeChallengeId);
    } catch (_) { return null; }
  }

  void startChallenge(String id) {
    activeChallengeId        = id;
    activeChallengeProgress  = 0;
    activeChallengeCompleted = false;
    challengeStartDate       = _todayKey();
    challengeCheckedDays     = {};
    challengeMissedDays      = [];
    challengeTotalMissed     = 0;
    _save();
  }

  void checkInChallenge() {
    if (activeChallengeId == null || activeChallengeCompleted) return;
    if (checkedInToday) return;
    final challenge = activeChallenge;
    if (challenge == null) return;
    challengeCheckedDays.add(_todayKey());
    activeChallengeProgress += 1;
    if (activeChallengeProgress >= (challenge['target'] as int)) {
      activeChallengeCompleted = true;
      points += challenge['xp'] as int;
    }
    _save();
  }

  void checkMissedChallengeDays() {
    if (activeChallengeId == null || activeChallengeCompleted) return;
    if (challengeStartDate == null) return;
    final now   = DateTime.now();
    final start = DateTime.parse(challengeStartDate!);
    final daysSinceStart = now.difference(start).inDays;
    for (int i = 1; i < daysSinceStart; i++) {
      final day = start.add(Duration(days: i));
      if (day.year == now.year && day.month == now.month && day.day == now.day) break;
      final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
      if (!challengeCheckedDays.contains(key) && !challengeMissedDays.contains(key)) {
        markChallengeMissed(key);
        if (activeChallengeId == null) return;
      }
    }
  }

  void markChallengeMissed(String dayKey) {
    if (activeChallengeId == null || activeChallengeCompleted) return;
    if (challengeCheckedDays.contains(dayKey)) return;
    if (challengeMissedDays.contains(dayKey)) return;
    challengeMissedDays.add(dayKey);
    challengeTotalMissed++;
    points -= 2;
    if (points < 0) points = 0;
    _save();
    if (shouldAbandonChallenge()) clearChallenge();
  }

  void uncheckInChallenge() {
    if (activeChallengeId == null || !checkedInToday) return;
    challengeCheckedDays.remove(_todayKey());
    activeChallengeProgress = (activeChallengeProgress - 1).clamp(0, 999);
    _save();
  }

  bool shouldAbandonChallenge() {
    if (challengeTotalMissed >= 3) return true;
    if (challengeMissedDays.length >= 3) {
      final sorted = List<String>.from(challengeMissedDays)..sort();
      for (int i = 0; i <= sorted.length - 3; i++) {
        final a = DateTime.parse(sorted[i]);
        final b = DateTime.parse(sorted[i + 1]);
        final c = DateTime.parse(sorted[i + 2]);
        if (b.difference(a).inDays == 1 && c.difference(b).inDays == 1) return true;
      }
    }
    return false;
  }

  void clearChallenge() {
    activeChallengeId        = null;
    activeChallengeProgress  = 0;
    activeChallengeCompleted = false;
    challengeStartDate       = null;
    challengeCheckedDays     = {};
    challengeMissedDays      = [];
    challengeTotalMissed     = 0;
    _save();
  }

  // ---------- WATER ----------
  int  waterGlasses     = 0;
  bool waterGoalMetToday = false;
  int  waterXpToday     = 0;

  void addWaterGlass() {
    if (waterGlasses < 8) {
      waterGlasses++;
      points += 1;
      waterXpToday += 1;
      if (waterGlasses == 8 && !waterGoalMetToday) {
        points += 5;
        waterXpToday += 5;
        waterGoalMetToday = true;
      }
    }
    _saveWaterHistory();
    _save();
  }

  void removeWaterGlass() {
    if (waterGlasses > 0) {
      if (waterGlasses == 8 && waterGoalMetToday) {
        points -= 5;
        waterXpToday -= 5;
        waterGoalMetToday = false;
      }
      waterGlasses--;
      points -= 1;
      waterXpToday -= 1;
      if (points < 0) points = 0;
      if (waterXpToday < 0) waterXpToday = 0;
    }
    _saveWaterHistory();
    _save();
  }

  // ---------- MEALS ----------
  Map<MealType, List<FoodItem>> mealItems = {
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
  };
  List<FoodItem> snackItems = [];

  void addFoodItem(MealType meal, FoodItem item) {
    final wasEmpty = mealItems[meal]!.isEmpty;
    mealItems[meal]!.add(item);
    if (wasEmpty) points += 2;
    mealHistory[_todayKey()] = true;
    _save();
  }

  void removeFoodItem(MealType meal, int index) {
    final wasOnlyItem = mealItems[meal]!.length == 1;
    mealItems[meal]!.removeAt(index);
    if (wasOnlyItem) {
      points -= 2;
      if (points < 0) points = 0;
    }
    _save();
  }

  void addSnack(FoodItem item)  { snackItems.add(item);       _save(); }
  void removeSnack(int index)   { snackItems.removeAt(index); _save(); }

  bool get hasMealsToday =>
      mealItems.values.any((list) => list.isNotEmpty) || snackItems.isNotEmpty;

  // Legacy
  Map<MealType, Map<String, int>> mealsToday = {
    MealType.breakfast: {}, MealType.lunch: {}, MealType.dinner: {},
  };
  void saveMeal({required MealType mealType, required Map<String, int> macros}) {
    mealsToday[mealType] = macros; _save();
  }
  void resetMeal(MealType mealType) {
    mealsToday[mealType]!.clear(); mealItems[mealType]!.clear(); _save();
  }

  // ---------- MOOD ----------
  String? todayMood;
  bool    moodLoggedToday = false;

  static const List<Map<String, String>> moodOptions = [
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😐', 'label': 'Meh'},
    {'emoji': '🙂', 'label': 'Okay'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '🤩', 'label': 'Great'},
  ];

  void logMood(String mood) {
    if (todayMood == mood && moodLoggedToday) {
      todayMood = null; moodLoggedToday = false;
      points -= 3; if (points < 0) points = 0;
    } else {
      final wasLogged = moodLoggedToday;
      todayMood = mood; moodLoggedToday = true;
      if (!wasLogged) points += 3;
      final today = _todayKey();
      moodHistory.removeWhere((e) => e['date'] == today);
      moodHistory.add({'date': today, 'mood': mood});
    }
    _save();
  }

  // ---------- SLEEP ----------
  double? sleepHours;
  bool    sleepLoggedToday = false;

  void logSleep(double hours) {
    final isFirstLog = !sleepLoggedToday;
    sleepHours = hours; sleepLoggedToday = true;
    final today = _todayKey();
    sleepHistory.removeWhere((e) => e['date'] == today);
    sleepHistory.add({'date': today, 'hours': hours});
    if (isFirstLog) points += 3;
    _save();
  }

  void clearMood() {
    if (!moodLoggedToday) return;
    todayMood = null; moodLoggedToday = false;
    points -= 3; if (points < 0) points = 0;
    _save();
  }

  void clearSleep() {
    if (!sleepLoggedToday) return;
    sleepHours = null; sleepLoggedToday = false;
    points -= 3; if (points < 0) points = 0;
    _save();
  }

  String get sleepQualityLabel {
    if (sleepHours == null) return 'Not logged';
    if (sleepHours! < 5)  return 'Sleep deprived';
    if (sleepHours! < 7)  return 'Below recommended';
    if (sleepHours! <= 9) return 'Optimal range';
    return 'Oversleeping';
  }

  double get sleepProgress =>
      sleepHours == null ? 0.0 : (sleepHours! / 9.0).clamp(0.0, 1.0);

  // ---------- JOURNAL ----------
  List<JournalEntry> journalEntries = [];

  JournalEntry? get todayJournalEntry {
    final today = DateTime.now();
    try {
      return journalEntries.lastWhere((e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day);
    } catch (_) { return null; }
  }

  JournalEntry? getEntryForDate(DateTime date) {
    try {
      return journalEntries.lastWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    } catch (_) { return null; }
  }

  void saveJournalEntry(String text) {
    final today = DateTime.now();
    final hadEntryToday = todayJournalEntry != null;
    journalEntries.removeWhere((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
    journalEntries.add(JournalEntry(text: text, date: DateTime.now()));
    if (!hadEntryToday) points += 5;
    _save();
  }

  void deleteJournalEntry(JournalEntry entry) {
    journalEntries.remove(entry);
    final today = DateTime.now();
    if (entry.date.year == today.year &&
        entry.date.month == today.month &&
        entry.date.day == today.day) {
      points -= 5; if (points < 0) points = 0;
    }
    _save();
  }

  // ---------- AFFIRMATIONS ----------
  static const List<String> _affirmations = [
    "My body is doing its best, and so am I.",
    "Every small step I take is progress worth celebrating.",
    "I am more than my diagnosis. I am strong, capable, and worthy.",
    "Healing is not linear, and that is okay.",
    "I choose to nourish my body with kindness today.",
    "Rest is productive. Taking care of myself is enough.",
    "I trust my body's ability to find balance.",
    "I am patient with myself and my journey.",
    "Small consistent actions create lasting change.",
    "My worth is not measured by my productivity.",
    "I give myself permission to feel and to heal.",
    "Today I choose progress over perfection.",
    "I am learning to listen to what my body needs.",
    "Strength is showing up for myself, even on hard days.",
    "I deserve the same compassion I give to others.",
    "My journey is unique and valid.",
    "I celebrate every win, no matter how small.",
    "Taking care of my health is an act of self-love.",
    "I am resilient. I have overcome challenges before.",
    "Today is a new opportunity to take care of myself.",
    "I am not alone in this journey.",
    "My body deserves rest, nourishment, and movement.",
    "I release what I cannot control and focus on what I can.",
    "Consistency is more powerful than perfection.",
    "I am proud of how far I have come.",
    "Every day I choose myself is a victory.",
    "I am kind to my body even when it feels difficult.",
    "Wellness is a lifelong journey, not a destination.",
    "I honour my body by listening to its needs.",
    "I am capable of building habits that support my health.",
  ];

  String get todayAffirmation {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _affirmations[dayOfYear % _affirmations.length];
  }

  // ---------- ACHIEVEMENTS ----------
  Set<String> achievements = {'First Movement'};
  void unlockAchievement(String achievement) => achievements.add(achievement);

  // ---------- HISTORICAL LOGS ----------
  List<Map<String, dynamic>> moodHistory     = [];
  List<Map<String, dynamic>> movementHistory = [];
  List<Map<String, dynamic>> sleepHistory    = [];
  List<Map<String, dynamic>> waterHistory    = [];
  Map<String, bool> mealHistory = {};
  Map<String, Map<String, List<FoodItem>>> mealDayHistory = {}; // date -> mealType -> items

  List<Map<String, dynamic>> _last7Days(List<Map<String, dynamic>> history) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return history.where((e) {
      try {
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(cutoff);
      } catch (_) { return false; }
    }).toList();
  }

  List<Map<String, dynamic>> get last7DaysMood     => _last7Days(moodHistory);
  List<Map<String, dynamic>> get last7DaysMovement => _last7Days(movementHistory);
  List<Map<String, dynamic>> get last7DaysSleep    => _last7Days(sleepHistory);
  List<Map<String, dynamic>> get last7DaysWater    => _last7Days(waterHistory);

  bool get hasEnoughDataForInsight {
    final allDates = <String>{};
    for (final e in moodHistory)     allDates.add(e['date'] as String);
    for (final e in movementHistory) allDates.add(e['date'] as String);
    for (final e in sleepHistory)    allDates.add(e['date'] as String);
    for (final e in waterHistory)    allDates.add(e['date'] as String);
    return allDates.length >= 7;
  }

  void _saveWaterHistory() {
    final today = _todayKey();
    waterHistory.removeWhere((e) => e['date'] == today);
    waterHistory.add({'date': today, 'glasses': waterGlasses});
  }

  // ---------- INSIGHT CACHE ----------
  String? cachedInsight;
  String? cachedInsightDate;

  bool get shouldRefreshInsight {
    if (cachedInsight == null || cachedInsightDate == null) return true;
    try {
      final lastDate = DateTime.parse(cachedInsightDate!);
      return DateTime.now().difference(lastDate).inDays >= 7;
    } catch (_) { return true; }
  }

  void saveInsightCache(String insight) {
    cachedInsight     = insight;
    cachedInsightDate = _todayKey();
    _save();
  }

  // ---------- AVATAR ----------
  String? selectedAvatar;

  void saveAvatar(String assetPath) {
    selectedAvatar = assetPath;
    _save();
  }

  // ---------- STREAK FREEZE ----------
  bool checkStreakOnOpen() {
    final yesterday  = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (hasLoggedToday || streak == 0) return false;
    if (lastStreakDate == yesterday) return false;
    final twoDaysAgo = _dateKey(DateTime.now().subtract(const Duration(days: 2)));
    final today      = _todayKey();
    if (lastStreakDate == twoDaysAgo ||
        (lastStreakDate != null && lastStreakDate != today)) {
      if (freezeTokens > 0) {
        freezeTokens -= 1;
        _save();
        return true;
      } else {
        streak = 0;
        _save();
        return false;
      }
    }
    return false;
  }

  bool useFreeze() {
    if (freezeTokens <= 0) return false;
    freezeTokens -= 1;
    _save();
    return true;
  }

  void _checkFreezeReward() {
    if (streak > 0 && streak % 7 == 0) {
      freezeTokens += 1;
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // ---------- DAILY RESET ----------
  void _resetIfNewDay(String? lastActiveDate) {
    final today = _todayKey();
    if (lastActiveDate == today) return;

    // Snapshot yesterday's meals into history before clearing
    if (lastActiveDate != null) {
      final snapshot = <String, List<FoodItem>>{};
      for (final type in MealType.values) {
        if (mealItems[type]!.isNotEmpty) {
          snapshot[type.name] = List.from(mealItems[type]!);
        }
      }
      if (snackItems.isNotEmpty) snapshot['snacks'] = List.from(snackItems);
      if (snapshot.isNotEmpty) mealDayHistory[lastActiveDate] = snapshot;
      // Keep only last 7 days
      final keys = mealDayHistory.keys.toList()..sort();
      while (keys.length > 7) { mealDayHistory.remove(keys.removeAt(0)); }
    }

    todayMood        = null;
    moodLoggedToday  = false;
    sleepHours       = null;
    sleepLoggedToday = false;
    waterGlasses     = 0;
    waterGoalMetToday = false;
    waterXpToday     = 0;
    for (final type in MealType.values) { mealItems[type] = []; }
    snackItems     = [];
    todayMovements = [];
    hasLoggedToday = false;

    _doc.set({'lastActiveDate': today}, SetOptions(merge: true));
  }
}
