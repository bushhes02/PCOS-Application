enum MealType { breakfast, lunch, dinner }

class MovementLog {
  final String type;
  final int duration;
  final int points;

  MovementLog({
    required this.type,
    required this.duration,
    required this.points,
  });
}

class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // ---------- CORE ----------
  int points = 0;
  int streak = 0;
  bool hasLoggedToday = false;

  // ---------- MOVEMENT ----------
  List<MovementLog> todayMovements = [];

  int _movementPoints(int duration) => duration >= 30 ? 15 : 10;

  void logMovement({required String type, required int duration}) {
    final earned = _movementPoints(duration);
    points += earned;

    if (!hasLoggedToday) {
      streak += 1;
      hasLoggedToday = true;
    }

    todayMovements.add(
      MovementLog(type: type, duration: duration, points: earned),
    );
  }

  void removeMovement(int index) {
    final removed = todayMovements.removeAt(index);
    points -= removed.points;
    if (points < 0) points = 0;

    if (todayMovements.isEmpty && hasLoggedToday) {
      hasLoggedToday = false;
      if (streak > 0) streak -= 1;
    }
  }

  // ---------- WATER ----------
  int waterGlasses = 0;
  bool waterGoalMetToday = false;

  void addWaterGlass() {
    if (waterGlasses < 8) {
      waterGlasses++;
      if (waterGlasses == 8 && !waterGoalMetToday) {
        points += 20;
        waterGoalMetToday = true;
      }
    }
  }

  void removeWaterGlass() {
    if (waterGlasses > 0) {
      waterGlasses--;
      if (waterGoalMetToday && waterGlasses < 8) {
        points -= 20;
        if (points < 0) points = 0;
        waterGoalMetToday = false;
      }
    }
  }

  // ---------- MEALS ----------
  Map<MealType, Map<String, int>> mealsToday = {
    MealType.breakfast: {},
    MealType.lunch: {},
    MealType.dinner: {},
  };

  final Map<MealType, Map<String, List<int>>> healthyRanges = {
    MealType.breakfast: {
      'Carbs': [40, 60],
      'Protein': [20, 30],
      'Fats': [10, 20],
    },
    MealType.lunch: {
      'Carbs': [50, 70],
      'Protein': [25, 35],
      'Fats': [15, 25],
    },
    MealType.dinner: {
      'Carbs': [30, 50],
      'Protein': [25, 35],
      'Fats': [10, 20],
    },
  };

  int calculateMealScore(MealType mealType) {
    final macros = mealsToday[mealType]!;
    int score = 0;
    final ranges = healthyRanges[mealType]!;

    for (final macro in ranges.keys) {
      if (macros.containsKey(macro)) {
        final g = macros[macro]!;
        if (g >= ranges[macro]![0] && g <= ranges[macro]![1]) {
          score++;
        }
      }
    }
    return score;
  }

  int calculateMealPoints(MealType mealType) {
    final score = calculateMealScore(mealType);
    if (score == 3) return 15;
    if (score == 2) return 10;
    if (score == 1) return 5;
    return 0;
  }

  void saveMeal({
    required MealType mealType,
    required Map<String, int> macros,
  }) {
    mealsToday[mealType] = macros;
    points += calculateMealPoints(mealType);
  }

  void resetMeal(MealType mealType) {
    mealsToday[mealType]!.clear();
  }

  // ---------- MOOD ----------
  String? todayMood;
  bool moodLoggedToday = false;

  void logMood(String mood) {
    if (!moodLoggedToday) {
      todayMood = mood;
      points += 5;
      moodLoggedToday = true;
    }
  }
}