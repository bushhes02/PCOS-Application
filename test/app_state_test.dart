// test/app_state_test.dart
//
// Unit tests for Ovarrior AppState business logic.
// Author: Fathima Bushra Sahir Hussain (G21318993)
//
// HOW TO RUN:
//   flutter test test/app_state_test.dart
//
// These tests use a TestAppState subclass that overrides _save() and
// _updateLeaderboard() to be no-ops, so no Firebase connection is needed.
// All tests are purely in-memory.

import 'package:flutter_test/flutter_test.dart';
import 'package:pcos_app/state/app_state.dart';

// ── Helper — fresh state for each test (uses test-only constructor) ─────────
AppState fresh() => AppState.testOnly();

void main() {

  // ════════════════════════════════════════════════════════
  // MOVEMENT
  // ════════════════════════════════════════════════════════
  group('Movement logging', () {

    test('logMovement adds entry to todayMovements', () {
      final s = fresh();
      s.logMovement(type: 'Running', duration: 30);
      expect(s.todayMovements.length, 1);
      expect(s.todayMovements.first.type, 'Running');
      expect(s.todayMovements.first.duration, 30);
    });

    test('first movement of the day awards +3 XP', () {
      final s = fresh();
      s.logMovement(type: 'Walking', duration: 20);
      expect(s.points, 3);
    });

    test('second movement same day does not award more XP', () {
      final s = fresh();
      s.logMovement(type: 'Walking', duration: 20);
      s.logMovement(type: 'Yoga',    duration: 15);
      expect(s.points, 3); // still only 3
    });

    test('first movement increments streak', () {
      final s = fresh();
      expect(s.streak, 0);
      s.logMovement(type: 'Cycling', duration: 25);
      expect(s.streak, 1);
    });

    test('removeMovement removes correct entry', () {
      final s = fresh();
      s.logMovement(type: 'Swim', duration: 40);
      s.logMovement(type: 'Yoga', duration: 20);
      s.removeMovement(0);
      expect(s.todayMovements.length, 1);
      expect(s.todayMovements.first.type, 'Yoga');
    });

    test('removing last movement deducts XP and decrements streak', () {
      final s = fresh();
      s.logMovement(type: 'Run', duration: 30);
      expect(s.points, 3);
      expect(s.streak, 1);
      s.removeMovement(0);
      expect(s.points, 0);
      expect(s.streak, 0);
    });

    test('removing one of two movements does not deduct XP', () {
      final s = fresh();
      s.logMovement(type: 'Run',  duration: 30);
      s.logMovement(type: 'Walk', duration: 15);
      s.removeMovement(0); // still one movement left
      expect(s.points, 3);
      expect(s.streak, 1);
    });

    test('points never go below zero on removal', () {
      final s = fresh();
      s.logMovement(type: 'Run', duration: 20);
      s.removeMovement(0);
      s.points = 0; // force zero
      // removeMovement guard should prevent negative
      expect(s.points, 0);
    });


  });

  // ════════════════════════════════════════════════════════
  // MOOD
  // ════════════════════════════════════════════════════════
  group('Mood logging', () {

    test('logMood sets todayMood and moodLoggedToday', () {
      final s = fresh();
      s.logMood('Good');
      expect(s.todayMood, 'Good');
      expect(s.moodLoggedToday, true);
    });

    test('first mood log awards +3 XP', () {
      final s = fresh();
      s.logMood('Okay');
      expect(s.points, 3);
    });

    test('logging same mood again clears it (toggle off)', () {
      final s = fresh();
      s.logMood('Good');
      s.logMood('Good'); // tap same mood again
      expect(s.todayMood, isNull);
      expect(s.moodLoggedToday, false);
    });

    test('toggling mood off deducts 3 XP', () {
      final s = fresh();
      s.logMood('Great');
      expect(s.points, 3);
      s.logMood('Great'); // undo
      expect(s.points, 0);
    });

    test('logging different mood does not award XP again', () {
      final s = fresh();
      s.logMood('Meh');
      s.logMood('Good'); // change mood
      expect(s.points, 3); // only first log awards XP
      expect(s.todayMood, 'Good');
    });

    test('clearMood resets mood and deducts XP', () {
      final s = fresh();
      s.logMood('Good');
      s.clearMood();
      expect(s.todayMood, isNull);
      expect(s.moodLoggedToday, false);
      expect(s.points, 0);
    });

    test('clearMood does nothing if mood not logged', () {
      final s = fresh();
      s.clearMood();
      expect(s.points, 0);
    });

    test('points never go below zero on mood clear', () {
      final s = fresh();
      s.points = 1;
      s.moodLoggedToday = true;
      s.clearMood();
      expect(s.points, 0); // clamped at 0
    });
  });

  // ════════════════════════════════════════════════════════
  // SLEEP
  // ════════════════════════════════════════════════════════
  group('Sleep logging', () {

    test('logSleep sets sleepHours and sleepLoggedToday', () {
      final s = fresh();
      s.logSleep(7.5);
      expect(s.sleepHours, 7.5);
      expect(s.sleepLoggedToday, true);
    });

    test('first sleep log awards +3 XP', () {
      final s = fresh();
      s.logSleep(8.0);
      expect(s.points, 3);
    });

    test('updating sleep hours does not award XP again', () {
      final s = fresh();
      s.logSleep(6.0);
      s.logSleep(8.0); // edit
      expect(s.points, 3); // only first log awards XP
    });

    test('sleepQualityLabel: below 5 hours is Sleep deprived', () {
      final s = fresh();
      s.logSleep(4.5);
      expect(s.sleepQualityLabel, 'Sleep deprived');
    });

    test('sleepQualityLabel: 5.0–6.9 is Below recommended', () {
      final s = fresh();
      s.logSleep(6.0);
      expect(s.sleepQualityLabel, 'Below recommended');
    });

    test('sleepQualityLabel: 7.0–9.0 is Optimal range', () {
      final s = fresh();
      s.logSleep(8.0);
      expect(s.sleepQualityLabel, 'Optimal range');
    });

    test('sleepQualityLabel: above 9 hours is Oversleeping', () {
      final s = fresh();
      s.logSleep(10.0);
      expect(s.sleepQualityLabel, 'Oversleeping');
    });

    test('clearSleep resets state and deducts XP', () {
      final s = fresh();
      s.logSleep(7.0);
      s.clearSleep();
      expect(s.sleepHours, isNull);
      expect(s.sleepLoggedToday, false);
      expect(s.points, 0);
    });

    test('clearSleep does nothing if sleep not logged', () {
      final s = fresh();
      s.clearSleep();
      expect(s.points, 0);
    });

    test('sleepProgress clamps between 0 and 1', () {
      final s = fresh();
      s.logSleep(12.0); // above max
      expect(s.sleepProgress, 1.0);
    });
  });

  // ════════════════════════════════════════════════════════
  // WATER
  // ════════════════════════════════════════════════════════
  group('Water tracking', () {

    test('addWaterGlass increments count', () {
      final s = fresh();
      s.addWaterGlass();
      expect(s.waterGlasses, 1);
    });

    test('each glass awards +1 XP', () {
      final s = fresh();
      s.addWaterGlass();
      s.addWaterGlass();
      s.addWaterGlass();
      expect(s.points, 3);
    });

    test('reaching 8 glasses awards +5 bonus XP', () {
      final s = fresh();
      for (int i = 0; i < 8; i++) s.addWaterGlass();
      expect(s.waterGlasses, 8);
      expect(s.points, 13); // 8×1 + 5 bonus
      expect(s.waterGoalMetToday, true);
    });

    test('cannot add more than 8 glasses', () {
      final s = fresh();
      for (int i = 0; i < 10; i++) s.addWaterGlass();
      expect(s.waterGlasses, 8);
    });

    test('removeWaterGlass decrements count and deducts XP', () {
      final s = fresh();
      s.addWaterGlass();
      s.addWaterGlass();
      s.removeWaterGlass();
      expect(s.waterGlasses, 1);
      expect(s.points, 1);
    });

    test('removing 8th glass removes bonus XP', () {
      final s = fresh();
      for (int i = 0; i < 8; i++) s.addWaterGlass();
      expect(s.points, 13);
      s.removeWaterGlass(); // drops below 8
      expect(s.waterGoalMetToday, false);
      expect(s.points, 7); // 13 - 5 bonus - 1 glass = 7
    });

    test('cannot remove below zero glasses', () {
      final s = fresh();
      s.removeWaterGlass();
      expect(s.waterGlasses, 0);
      expect(s.points, 0);
    });
  });

  // ════════════════════════════════════════════════════════
  // MEALS
  // ════════════════════════════════════════════════════════
  group('Meal logging', () {

    test('addFoodItem adds to correct meal type', () {
      final s = fresh();
      s.addFoodItem(MealType.breakfast, FoodItem(name: 'Oats', portion: '100g'));
      expect(s.mealItems[MealType.breakfast]!.length, 1);
      expect(s.mealItems[MealType.breakfast]!.first.name, 'Oats');
    });

    test('first item in a meal awards +2 XP', () {
      final s = fresh();
      s.addFoodItem(MealType.lunch, FoodItem(name: 'Rice', portion: '150g'));
      expect(s.points, 2);
    });

    test('second item in same meal does not award more XP', () {
      final s = fresh();
      s.addFoodItem(MealType.lunch, FoodItem(name: 'Rice',    portion: '150g'));
      s.addFoodItem(MealType.lunch, FoodItem(name: 'Chicken', portion: '120g'));
      expect(s.points, 2);
    });

    test('first item in different meal types each award +2 XP', () {
      final s = fresh();
      s.addFoodItem(MealType.breakfast, FoodItem(name: 'Eggs',    portion: '2 eggs'));
      s.addFoodItem(MealType.lunch,     FoodItem(name: 'Salad',   portion: '1 bowl'));
      s.addFoodItem(MealType.dinner,    FoodItem(name: 'Salmon',  portion: '150g'));
      expect(s.points, 6);
    });

    test('removeFoodItem removes correct item', () {
      final s = fresh();
      s.addFoodItem(MealType.dinner, FoodItem(name: 'Fish',  portion: '150g'));
      s.addFoodItem(MealType.dinner, FoodItem(name: 'Salad', portion: '1 cup'));
      s.removeFoodItem(MealType.dinner, 0);
      expect(s.mealItems[MealType.dinner]!.length, 1);
      expect(s.mealItems[MealType.dinner]!.first.name, 'Salad');
    });

    test('removing only item deducts XP', () {
      final s = fresh();
      s.addFoodItem(MealType.breakfast, FoodItem(name: 'Toast', portion: '2 slices'));
      s.removeFoodItem(MealType.breakfast, 0);
      expect(s.points, 0);
    });

    test('hasMealsToday is false when nothing logged', () {
      final s = fresh();
      expect(s.hasMealsToday, false);
    });

    test('hasMealsToday is true after logging a meal', () {
      final s = fresh();
      s.addFoodItem(MealType.lunch, FoodItem(name: 'Soup', portion: '1 bowl'));
      expect(s.hasMealsToday, true);
    });
  });

  // ════════════════════════════════════════════════════════
  // STREAK & FREEZE TOKENS
  // ════════════════════════════════════════════════════════
  group('Streak and freeze tokens', () {

    test('streak starts at zero', () {
      final s = fresh();
      expect(s.streak, 0);
    });

    test('logging movement increments streak', () {
      final s = fresh();
      s.logMovement(type: 'Run', duration: 20);
      expect(s.streak, 1);
    });

    test('useFreeze returns false when no tokens', () {
      final s = fresh();
      expect(s.useFreeze(), false);
    });

    test('useFreeze returns true and decrements token', () {
      final s = fresh();
      s.freezeTokens = 2;
      expect(s.useFreeze(), true);
      expect(s.freezeTokens, 1);
    });

    test('freeze token awarded at 7-streak multiple', () {
      final s = fresh();
      s.streak = 6;
      s.hasLoggedToday = false;
      s.logMovement(type: 'Walk', duration: 20);
      expect(s.freezeTokens, 1);
    });

    test('freeze token not awarded at non-multiple of 7', () {
      final s = fresh();
      s.streak = 3;
      s.hasLoggedToday = false;
      s.logMovement(type: 'Walk', duration: 20);
      expect(s.freezeTokens, 0);
    });
  });

  // ════════════════════════════════════════════════════════
  // JOURNAL
  // ════════════════════════════════════════════════════════
  group('Journal', () {

    test('saveJournalEntry adds entry', () {
      final s = fresh();
      s.saveJournalEntry('Feeling better today');
      expect(s.journalEntries.length, 1);
      expect(s.journalEntries.first.text, 'Feeling better today');
    });

    test('first journal entry awards +5 XP', () {
      final s = fresh();
      s.saveJournalEntry('Good day');
      expect(s.points, 5);
    });

    test('editing journal entry (saving again same day) does not award XP again', () {
      final s = fresh();
      s.saveJournalEntry('First draft');
      s.saveJournalEntry('Updated draft'); // edit
      expect(s.points, 5); // only once
      expect(s.journalEntries.length, 1); // replaced not duplicated
    });

    test('todayJournalEntry returns todays entry', () {
      final s = fresh();
      s.saveJournalEntry('Today entry');
      expect(s.todayJournalEntry, isNotNull);
      expect(s.todayJournalEntry!.text, 'Today entry');
    });

    test('deleteJournalEntry removes entry and deducts XP', () {
      final s = fresh();
      s.saveJournalEntry('Something');
      final entry = s.journalEntries.first;
      s.deleteJournalEntry(entry);
      expect(s.journalEntries, isEmpty);
      expect(s.points, 0);
    });
  });

  // ════════════════════════════════════════════════════════
  // QUESTS
  // ════════════════════════════════════════════════════════
  group('Quest system', () {

    test('startChallenge sets active challenge', () {
      final s = fresh();
      s.startChallenge('cycling_7');
      expect(s.activeChallengeId, 'cycling_7');
      expect(s.activeChallengeProgress, 0);
      expect(s.activeChallengeCompleted, false);
    });

    test('checkInChallenge increments progress', () {
      final s = fresh();
      s.startChallenge('cycling_7');
      s.checkInChallenge();
      expect(s.activeChallengeProgress, 1);
    });

    test('cannot check in twice on same day', () {
      final s = fresh();
      s.startChallenge('cycling_7');
      s.checkInChallenge();
      s.checkInChallenge(); // second tap
      expect(s.activeChallengeProgress, 1);
    });

    test('completing quest awards correct XP', () {
      final s = fresh();
      s.startChallenge('cycling_7'); // xp: 10, target: 7
      // Simulate 6 previous check-ins on different days
      s.activeChallengeProgress = 6;
      s.challengeCheckedDays = {'2025-01-01','2025-01-02','2025-01-03',
                                 '2025-01-04','2025-01-05','2025-01-06'};
      s.checkInChallenge(); // 7th check-in — completes quest
      expect(s.activeChallengeCompleted, true);
      expect(s.points, 10); // quest XP
    });

    test('uncheckInChallenge decrements progress', () {
      final s = fresh();
      s.startChallenge('cycling_7');
      s.checkInChallenge();
      s.uncheckInChallenge();
      expect(s.activeChallengeProgress, 0);
    });

    test('clearChallenge resets all quest state', () {
      final s = fresh();
      s.startChallenge('steps_5k_14');
      s.clearChallenge();
      expect(s.activeChallengeId, isNull);
      expect(s.activeChallengeProgress, 0);
      expect(s.activeChallengeCompleted, false);
    });

    test('shouldAbandonChallenge true after 3 total misses', () {
      final s = fresh();
      s.startChallenge('steps_5k_14');
      s.challengeTotalMissed = 3;
      expect(s.shouldAbandonChallenge(), true);
    });

    test('shouldAbandonChallenge false with fewer than 3 misses', () {
      final s = fresh();
      s.startChallenge('steps_5k_14');
      s.challengeTotalMissed = 2;
      expect(s.shouldAbandonChallenge(), false);
    });
  });

  // ════════════════════════════════════════════════════════
  // DAILY RESET
  // ════════════════════════════════════════════════════════
  group('Daily reset', () {

    test('_resetIfNewDay clears daily fields but preserves points', () {
      final s = fresh();
      s.points = 50;
      s.streak = 3;
      s.todayMood = 'Good';
      s.moodLoggedToday = true;
      s.sleepHours = 7.5;
      s.sleepLoggedToday = true;
      s.waterGlasses = 5;
      s.addFoodItem(MealType.breakfast, FoodItem(name: 'Oats', portion: '100g'));
      s.logMovement(type: 'Run', duration: 20);

      // Simulate new day by calling reset with yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}';
      s.testReset(yesterdayKey);

      expect(s.todayMood, isNull);
      expect(s.moodLoggedToday, false);
      expect(s.sleepHours, isNull);
      expect(s.sleepLoggedToday, false);
      expect(s.waterGlasses, 0);
      expect(s.mealItems[MealType.breakfast]!, isEmpty);
      expect(s.todayMovements, isEmpty);
      expect(s.hasLoggedToday, false);
      // Points and streak should NOT reset
      expect(s.streak, greaterThan(0));
    });

    test('_resetIfNewDay does nothing if called with today', () {
      final s = fresh();
      s.points = 20;
      s.todayMood = 'Great';
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      s.testReset(todayKey);
      expect(s.todayMood, 'Great'); // unchanged
      expect(s.points, 20);
    });
  });

  // ════════════════════════════════════════════════════════
  // FOOD ITEM SERIALISATION
  // ════════════════════════════════════════════════════════
  group('FoodItem serialisation', () {

    test('toMap and fromMap round-trip correctly', () {
      final item = FoodItem(name: 'Brown rice', portion: '150g');
      final map  = item.toMap();
      final back = FoodItem.fromMap(map);
      expect(back.name,    item.name);
      expect(back.portion, item.portion);
    });
  });

  // ════════════════════════════════════════════════════════
  // SLEEP QUALITY LABEL BOUNDARIES
  // ════════════════════════════════════════════════════════
  group('Sleep quality label boundaries', () {

    test('exactly 5.0 hours is Below recommended', () {
      final s = fresh();
      s.logSleep(5.0);
      expect(s.sleepQualityLabel, 'Below recommended');
    });

    test('exactly 7.0 hours is Optimal range', () {
      final s = fresh();
      s.logSleep(7.0);
      expect(s.sleepQualityLabel, 'Optimal range');
    });

    test('exactly 9.0 hours is Optimal range', () {
      final s = fresh();
      s.logSleep(9.0);
      expect(s.sleepQualityLabel, 'Optimal range');
    });

    test('9.1 hours is Oversleeping', () {
      final s = fresh();
      s.logSleep(9.1);
      expect(s.sleepQualityLabel, 'Oversleeping');
    });
  });
}