import 'package:hive_flutter/hive_flutter.dart';
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
  FoodItem({required this.name, required this.portion});

  Map<String, dynamic> toMap() => {'name': name, 'portion': portion};
  static FoodItem fromMap(Map map) =>
      FoodItem(name: map['name'] as String, portion: map['portion'] as String);
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
    final boxName = 'user_$uid';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    _instance = AppState._load(Hive.box(boxName));
  }

  static Future<void> resetForSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final boxName = 'user_$uid';
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    }
    _instance = null;
  }

  // ── Private constructor ────────────────────────────────
  late final Box _box;

  AppState._load(Box box) {
    _box = box;

    points        = _box.get('points',        defaultValue: 0);
    streak        = _box.get('streak',        defaultValue: 0);
    hasLoggedToday= _box.get('hasLoggedToday',defaultValue: false);
    freezeTokens  = _box.get('freezeTokens',  defaultValue: 0);
    lastStreakDate = _box.get('lastStreakDate', defaultValue: null);
    waterGlasses  = _box.get('waterGlasses',  defaultValue: 0);
    waterGoalMetToday = _box.get('waterGoalMetToday', defaultValue: false);
    waterXpToday  = _box.get('waterXpToday',  defaultValue: 0);

    todayMood      = _box.get('todayMood',      defaultValue: null);
    moodLoggedToday= _box.get('moodLoggedToday',defaultValue: false);

    sleepHours     = _box.get('sleepHours',     defaultValue: null);
    sleepLoggedToday = _box.get('sleepLoggedToday', defaultValue: false);

    final rawEntries = _box.get('journalEntries', defaultValue: []);
    journalEntries = (rawEntries as List)
        .map((e) => JournalEntry.fromMap(Map.from(e)))
        .toList();

    final rawWeekly = _box.get('weeklyMovementDays', defaultValue: []);
    weeklyMovementDays = List<String>.from(rawWeekly);
    weeklyBonusAwarded = _box.get('weeklyBonusAwarded', defaultValue: false);

    activeChallengeId       = _box.get('activeChallengeId',       defaultValue: null);
    activeChallengeProgress = _box.get('activeChallengeProgress', defaultValue: 0);
    activeChallengeCompleted= _box.get('activeChallengeCompleted',defaultValue: false);
    challengeStartDate      = _box.get('challengeStartDate',      defaultValue: null);
    challengeCheckedDays    = Set<String>.from(_box.get('challengeCheckedDays', defaultValue: []));
    challengeMissedDays     = List<String>.from(_box.get('challengeMissedDays', defaultValue: []));
    challengeTotalMissed    = _box.get('challengeTotalMissed',    defaultValue: 0);

    // ── Historical logs (new) ──────────────────────────
    final rawMoodHistory = _box.get('moodHistory', defaultValue: []);
    moodHistory = List<Map<String, dynamic>>.from(
        (rawMoodHistory as List).map((e) => Map<String, dynamic>.from(e)));

    final rawMovementHistory = _box.get('movementHistory', defaultValue: []);
    movementHistory = List<Map<String, dynamic>>.from(
        (rawMovementHistory as List).map((e) => Map<String, dynamic>.from(e)));

    final rawSleepHistory = _box.get('sleepHistory', defaultValue: []);
    sleepHistory = List<Map<String, dynamic>>.from(
        (rawSleepHistory as List).map((e) => Map<String, dynamic>.from(e)));

    final rawWaterHistory = _box.get('waterHistory', defaultValue: []);
    waterHistory = List<Map<String, dynamic>>.from(
        (rawWaterHistory as List).map((e) => Map<String, dynamic>.from(e)));

    final rawMealHistory = _box.get('mealHistory', defaultValue: {});
    mealHistory = Map<String, bool>.from(rawMealHistory);

    // ── Insight cache (new) ────────────────────────────
    cachedInsight        = _box.get('cachedInsight',        defaultValue: null);
    cachedInsightDate    = _box.get('cachedInsightDate',    defaultValue: null);

    _loadMeals();
    _loadSnacks();
    _loadTodayMovements();
    _resetIfNewDay();  // clears daily fields if date has changed
  }

  // ---------- CORE ----------
  int  points = 0;
  int  streak = 0;
  bool hasLoggedToday = false;
  int  freezeTokens = 0;
  String? lastStreakDate;

  // ---------- MOVEMENT ----------
  List<MovementLog> todayMovements   = [];
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
    _saveTodayMovements();

    // Save to movement history
    movementHistory.removeWhere((e) => e['date'] == today);
    movementHistory.add({'date': today, 'type': type, 'duration_minutes': duration});
    _saveMovementHistory();

    if (!alreadyLoggedToday) {
      weeklyMovementDays.add(today);
      points += 3;
      if (daysMovedThisWeek == 7 && !weeklyBonusAwarded) {
        points += 5;
        weeklyBonusAwarded = true;
        _box.put('weeklyBonusAwarded', true);
      }
      if (!hasLoggedToday) {
        streak += 1;
        hasLoggedToday = true;
        lastStreakDate = _todayKey();
        _checkFreezeReward();
      }
    }
    _box.put('weeklyMovementDays', weeklyMovementDays);
    _saveCore();
  }

  void removeMovement(int index) {
    todayMovements.removeAt(index);
    _saveTodayMovements();
    if (todayMovements.isEmpty) {
      weeklyMovementDays.remove(_todayKey());
      points -= 3;
      if (points < 0) points = 0;
      if (hasLoggedToday) {
        hasLoggedToday = false;
        if (streak > 0) streak -= 1;
      }
      _box.put('weeklyMovementDays', weeklyMovementDays);
    }
    _saveCore();
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
    _box.put('activeChallengeId',        id);
    _box.put('activeChallengeProgress',  0);
    _box.put('activeChallengeCompleted', false);
    _box.put('challengeStartDate',       challengeStartDate);
    _box.put('challengeCheckedDays',     []);
    _box.put('challengeMissedDays',      []);
    _box.put('challengeTotalMissed',     0);
  }

  void checkInChallenge() {
    if (activeChallengeId == null || activeChallengeCompleted) return;
    if (checkedInToday) return;
    final challenge = activeChallenge;
    if (challenge == null) return;
    challengeCheckedDays.add(_todayKey());
    _box.put('challengeCheckedDays', challengeCheckedDays.toList());
    activeChallengeProgress += 1;
    _box.put('activeChallengeProgress', activeChallengeProgress);
    if (activeChallengeProgress >= (challenge['target'] as int)) {
      activeChallengeCompleted = true;
      points += challenge['xp'] as int;
      _box.put('activeChallengeCompleted', true);
      _saveCore();
    }
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
    _box.put('challengeMissedDays',  challengeMissedDays);
    _box.put('challengeTotalMissed', challengeTotalMissed);
    _saveCore();
    if (shouldAbandonChallenge()) clearChallenge();
  }

  void uncheckInChallenge() {
    if (activeChallengeId == null || !checkedInToday) return;
    challengeCheckedDays.remove(_todayKey());
    activeChallengeProgress = (activeChallengeProgress - 1).clamp(0, 999);
    _box.put('activeChallengeProgress',  activeChallengeProgress);
    _box.put('challengeCheckedDays',     challengeCheckedDays.toList());
    _saveCore();
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
    _box.delete('activeChallengeId');
    _box.delete('activeChallengeProgress');
    _box.delete('activeChallengeCompleted');
    _box.delete('challengeStartDate');
    _box.delete('challengeCheckedDays');
    _box.delete('challengeMissedDays');
    _box.delete('challengeTotalMissed');
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
    _saveWater();
    _saveCore();
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
    _saveWater();
    _saveCore();
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
    if (wasEmpty) { points += 2; _box.put('points', points); }
    // Mark this day as having a meal logged
    mealHistory[_todayKey()] = true;
    _box.put('mealHistory', mealHistory);
    _saveMeals();
  }

  void removeFoodItem(MealType meal, int index) {
    final wasOnlyItem = mealItems[meal]!.length == 1;
    mealItems[meal]!.removeAt(index);
    if (wasOnlyItem) {
      points -= 2;
      if (points < 0) points = 0;
      _box.put('points', points);
    }
    _saveMeals();
  }

  void addSnack(FoodItem item)    { snackItems.add(item);         _saveSnacks(); }
  void removeSnack(int index)     { snackItems.removeAt(index);   _saveSnacks(); }

  bool get hasMealsToday =>
      mealItems.values.any((list) => list.isNotEmpty) || snackItems.isNotEmpty;

  void _loadMeals() {
    for (final type in MealType.values) {
      final raw = _box.get('meal_${type.name}', defaultValue: []);
      mealItems[type] = (raw as List).map((e) => FoodItem.fromMap(Map.from(e))).toList();
    }
  }

  void _saveMeals() {
    for (final type in MealType.values) {
      _box.put('meal_${type.name}', mealItems[type]!.map((e) => e.toMap()).toList());
    }
  }

  void _loadSnacks() {
    final raw = _box.get('snackItems', defaultValue: []);
    snackItems = (raw as List).map((e) => FoodItem.fromMap(Map.from(e))).toList();
  }

  void _saveSnacks() {
    _box.put('snackItems', snackItems.map((e) => e.toMap()).toList());
  }

  // Legacy
  Map<MealType, Map<String, int>> mealsToday = {
    MealType.breakfast: {}, MealType.lunch: {}, MealType.dinner: {},
  };
  void saveMeal({required MealType mealType, required Map<String, int> macros}) {
    mealsToday[mealType] = macros; _saveCore();
  }
  void resetMeal(MealType mealType) {
    mealsToday[mealType]!.clear(); mealItems[mealType]!.clear(); _saveMeals();
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
      // Save to mood history
      final today = _todayKey();
      moodHistory.removeWhere((e) => e['date'] == today);
      moodHistory.add({'date': today, 'mood': mood});
      _saveMoodHistory();
    }
    _box.put('todayMood',       todayMood);
    _box.put('moodLoggedToday', moodLoggedToday);
    _saveCore();
  }

  // ---------- SLEEP ----------
  double? sleepHours;
  bool    sleepLoggedToday = false;

  void logSleep(double hours) {
    final isFirstLog = !sleepLoggedToday;
    sleepHours = hours; sleepLoggedToday = true;
    _box.put('sleepHours',      sleepHours);
    _box.put('sleepLoggedToday', sleepLoggedToday);
    // Save to sleep history
    final today = _todayKey();
    sleepHistory.removeWhere((e) => e['date'] == today);
    sleepHistory.add({'date': today, 'hours': hours});
    _saveSleepHistory();
    if (isFirstLog) { points += 3; _saveCore(); }
  }

  void clearSleep() {
    if (!sleepLoggedToday) return;
    sleepHours = null; sleepLoggedToday = false;
    points -= 3; if (points < 0) points = 0;
    _box.put('sleepHours',       null);
    _box.put('sleepLoggedToday', false);
    _saveCore();
  }

  String get sleepQualityLabel {
    if (sleepHours == null) return 'Not logged';
    if (sleepHours! < 5)  return 'Poor sleep 😴';
    if (sleepHours! < 7)  return 'Could be better';
    if (sleepHours! <= 9) return 'Good rest 🌟';
    return 'Great sleep! ✨';
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
    _saveJournal();
    if (!hadEntryToday) { points += 5; _saveCore(); }
  }

  void deleteJournalEntry(JournalEntry entry) {
    journalEntries.remove(entry);
    _saveJournal();
    final today = DateTime.now();
    if (entry.date.year == today.year &&
        entry.date.month == today.month &&
        entry.date.day == today.day) {
      points -= 5; if (points < 0) points = 0; _saveCore();
    }
  }

  void _saveJournal() {
    _box.put('journalEntries', journalEntries.map((e) => e.toMap()).toList());
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

  // ---------- HISTORICAL LOGS (new) ----------
  List<Map<String, dynamic>> moodHistory     = [];
  List<Map<String, dynamic>> movementHistory = [];
  List<Map<String, dynamic>> sleepHistory    = [];
  List<Map<String, dynamic>> waterHistory    = [];
  /// date string → true, marks days where any meal was logged
  Map<String, bool> mealHistory = {};

  /// Returns entries from the last 7 days only
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

  /// True if user has at least 7 days of any data logged
  bool get hasEnoughDataForInsight {
    final allDates = <String>{};
    for (final e in moodHistory)     allDates.add(e['date'] as String);
    for (final e in movementHistory) allDates.add(e['date'] as String);
    for (final e in sleepHistory)    allDates.add(e['date'] as String);
    for (final e in waterHistory)    allDates.add(e['date'] as String);
    return allDates.length >= 7;
  }

  void _saveMoodHistory() {
    _box.put('moodHistory', moodHistory);
  }

  void _saveMovementHistory() {
    _box.put('movementHistory', movementHistory);
  }

  void _saveSleepHistory() {
    _box.put('sleepHistory', sleepHistory);
  }

  void _saveWaterHistory() {
    final today = _todayKey();
    waterHistory.removeWhere((e) => e['date'] == today);
    waterHistory.add({'date': today, 'glasses': waterGlasses});
    _box.put('waterHistory', waterHistory);
  }

  // ---------- INSIGHT CACHE (new) ----------
  String? cachedInsight;
  String? cachedInsightDate; // yyyy-MM-dd of when insight was last generated

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
    _box.put('cachedInsight',     cachedInsight);
    _box.put('cachedInsightDate', cachedInsightDate);
  }

  // ---------- SAVE HELPERS ----------
  void _saveCore() {
    _box.put('points',         points);
    _box.put('streak',         streak);
    _box.put('hasLoggedToday', hasLoggedToday);
    _box.put('freezeTokens',   freezeTokens);
    if (lastStreakDate != null) _box.put('lastStreakDate', lastStreakDate);
  }

  // ---------- STREAK FREEZE ----------
  bool checkStreakOnOpen() {
    final today     = _todayKey();
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (hasLoggedToday || streak == 0) return false;
    if (lastStreakDate == yesterday) return false;
    final twoDaysAgo = _dateKey(DateTime.now().subtract(const Duration(days: 2)));
    if (lastStreakDate == twoDaysAgo || (lastStreakDate != null && lastStreakDate != today)) {
      if (freezeTokens > 0) {
        freezeTokens -= 1;
        _saveCore();
        return true;
      } else {
        streak = 0;
        _saveCore();
        return false;
      }
    }
    return false;
  }

  bool useFreeze() {
    if (freezeTokens <= 0) return false;
    freezeTokens -= 1;
    _saveCore();
    return true;
  }

  void _checkFreezeReward() {
    if (streak > 0 && streak % 7 == 0) {
      freezeTokens += 1;
      _saveCore();
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  void _saveWater() {
    _box.put('waterGlasses',      waterGlasses);
    _box.put('waterGoalMetToday', waterGoalMetToday);
    _box.put('waterXpToday',      waterXpToday);
  }

  // ---------- TODAY MOVEMENTS PERSISTENCE (new) ----------
  void _loadTodayMovements() {
    final raw = _box.get('todayMovements', defaultValue: []);
    todayMovements = (raw as List).map((e) {
      final m = Map<String, dynamic>.from(e);
      return MovementLog(
        type:     m['type']     as String,
        duration: m['duration'] as int,
        points:   m['points']   as int,
      );
    }).toList();
  }

  void _saveTodayMovements() {
    _box.put('todayMovements', todayMovements.map((m) => {
      'type':     m.type,
      'duration': m.duration,
      'points':   m.points,
    }).toList());
  }

  // ---------- DAILY RESET (new) ----------
  /// Called once on app open. Clears all per-day fields if the date has changed.
  void _resetIfNewDay() {
    final today      = _todayKey();
    final lastActive = _box.get('lastActiveDate', defaultValue: '');

    if (lastActive == today) return; // same day — nothing to reset

    // ── Mood ──────────────────────────────────────────
    todayMood       = null;
    moodLoggedToday = false;
    _box.put('todayMood',       null);
    _box.put('moodLoggedToday', false);

    // ── Sleep ─────────────────────────────────────────
    sleepHours       = null;
    sleepLoggedToday = false;
    _box.put('sleepHours',       null);
    _box.put('sleepLoggedToday', false);

    // ── Water ─────────────────────────────────────────
    waterGlasses      = 0;
    waterGoalMetToday = false;
    waterXpToday      = 0;
    _saveWater();

    // ── Meals & snacks ────────────────────────────────
    for (final type in MealType.values) {
      mealItems[type] = [];
    }
    snackItems = [];
    _saveMeals();
    _saveSnacks();

    // ── Today's movements ─────────────────────────────
    todayMovements = [];
    _saveTodayMovements();

    // ── Streak: if no log yesterday, handled by checkStreakOnOpen ─
    // (hasLoggedToday intentionally NOT reset here — checkStreakOnOpen uses it)
    hasLoggedToday = false;
    _box.put('hasLoggedToday', false);

    // ── Record today as last active date ──────────────
    _box.put('lastActiveDate', today);
  }
}
