import 'dart:math';

import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';

class ExerciseUtils {

  // Data manually sourced from https://golf.procon.org/met-values-for-800-activities/
  // Refined data available at https://docs.google.com/spreadsheets/d/1jod_5zM_7WbNugK7jykKIF7eeQ2Be-t1NQODvrbSunA/edit#gid=672201482
  static const Map<String, double> activityMETMap = {
    "bag training":	5.5,
    "cycling":	8.5,
    "elliptical":	6,
    "high knees":	7,
    "high knee jumps":	8,
    "jogging":	8,
    "jump rope":	11.8,
    "rowing machine":	5.8,
    "run":	10,
    "run interval training":	12,
    "run treadmill":	9,
    "skipping standard":	12,
    "stationary bike":	8,
    "suspended crosses":	5,
    "swimming 50m sprints":	9,
    "walking":	4.5,
    "zone 2 running":	12,
  };

  static const double defaultActivityMETValue = 5.0;
  static const double defaultTimePerSetInMins = 2;
  static const double kilosToPoundsConversion = 2.20462;

  static const double sedentaryAMRConstant = 1.2;
  static const double lightlyActiveAMRConstant = 1.375;
  static const double moderatelyActiveAMRConstant = 1.55;
  static const double activeAMRConstant = 1.725;
  static const double veryActiveAMRConstant = 1.9;

  static const String notVeryActive = "Not very active";
  static const String lightlyActive ="Lightly active";
  static const String moderatelyActive = "Moderately active";
  static const String active = "Active";
  static const String veryActive = "Very active";

  static const List<String> allActivityLevels = [
    notVeryActive,
    lightlyActive,
    moderatelyActive,
    active,
    veryActive
  ];

  // Constants taken from https://www.verywellfit.com/how-many-calories-do-i-need-each-day-2506873
  static const Map<String, double> activityLevelsToAMRConstants = {
    notVeryActive: sedentaryAMRConstant,
    lightlyActive: lightlyActiveAMRConstant,
    moderatelyActive: moderatelyActiveAMRConstant,
    active:  activeAMRConstant,
    veryActive: veryActiveAMRConstant,
  };

  static const String loseHalfPoundPerWeekGoal = "Lose 0.5 lbs per week";
  static const String loseOnePoundPerWeekGoal = "Lose 1 lbs per week";
  static const String loseOneAndHalfPoundsPerWeekGoal = "Lose 1.5 lbs per week";
  static const String loseTwoPoundsPerWeekGoal = "Lose 2 lbs per week";
  static const String maintainWeight = "Maintain weight";
  static const String gainHalfPoundPerWeekGoal = "Gain 0.5 lbs per week";
  static const String gainOnePoundPerWeekGoal = "Gain 1 lbs per week";
  static const String gainOneAndHalfPoundsPerWeekGoal = "Gain 1.5 lbs per week";
  static const String gainTwoPoundsPerWeekGoal = "Gain 2 lbs per week";

  static const List<String> allGoals = [
    loseHalfPoundPerWeekGoal,
    loseOnePoundPerWeekGoal,
    loseOneAndHalfPoundsPerWeekGoal,
    loseTwoPoundsPerWeekGoal,
    maintainWeight,
    gainHalfPoundPerWeekGoal,
    gainOnePoundPerWeekGoal,
    gainOneAndHalfPoundsPerWeekGoal,
    gainTwoPoundsPerWeekGoal,
  ];

  // This all stems from the simple fact that 3500 calories = 1 Lb
  static const Map<String, double> goalsToCaloricDifferencePerDayMap = {
    loseHalfPoundPerWeekGoal: -250,
    loseOnePoundPerWeekGoal: -500,
    loseOneAndHalfPoundsPerWeekGoal: -750,
    loseTwoPoundsPerWeekGoal: -1000,
    maintainWeight: 0,
    gainHalfPoundPerWeekGoal: 250,
    gainOnePoundPerWeekGoal: 500,
    gainOneAndHalfPoundsPerWeekGoal: 750,
    gainTwoPoundsPerWeekGoal: 1000,
  };

  static const int defaultStepGoal = 10000;
  static const int maxStepGoal = 25000;

  static const Duration backgroundStepCountSyncDuration = Duration(minutes: 1);

  static double _getMetValueForActivity(String activityName) =>
      activityMETMap[activityName.toLowerCase()] ?? defaultActivityMETValue;

  // More info on formula at https://www.calculator.net/calories-burned-calculator.html
  static double calculateCaloriesBurnedForCardioActivity(FitnessUserProfile user, String activityName, int durationInMins) {
    return (durationInMins * _getMetValueForActivity(activityName) * (user.weightInLbs / kilosToPoundsConversion)) / 200;
  }

  static double calculateCaloriesBurnedForNonCardioActivity(FitnessUserProfile user, String activityName, int sets, int reps) {
    final durationInMins = sets * defaultTimePerSetInMins * reps;
    return (durationInMins * _getMetValueForActivity(activityName) * (user.weightInLbs / kilosToPoundsConversion)) / 200;
  }

  /// Returns the calorie goal needed per day for the user based on their fitnessUserProfile
  /// Formula taken from https://www.calculator.net/calorie-calculator.html and https://www.verywellfit.com/how-many-calories-do-i-need-each-day-2506873
  static double calculateCalorieGoalPerDayForUserToMaintainWeight(FitnessUserProfile user, int userAge, String? userGender) {
    if (userGender != null && userGender == "Male") {
      final bmr = (13.379 * (user.weightInLbs / kilosToPoundsConversion)) + (4.799 * user.heightInCm) - (5.677 * userAge) + 88.362;
      return bmr * activityLevelsToAMRConstants[user.activityLevel]!;
    }
    else {
      final bmr = (9.247 * (user.weightInLbs / kilosToPoundsConversion)) + (3.098 * user.heightInCm) - (4.33 * userAge) + 447.593;
      return bmr * activityLevelsToAMRConstants[user.activityLevel]!;
    }
  }

  static double calculateCalorieGoalPerDayForUserToAttainGoal(FitnessUserProfile user, int userAge, String? userGender) {
    final regularGoalPerDay = calculateCalorieGoalPerDayForUserToMaintainWeight(user, userAge, userGender);
    return regularGoalPerDay + goalsToCaloricDifferencePerDayMap[user.goal]!;
  }

  /// Calculation is as follows
  /// 4 seconds per rep
  /// 30 seconds between reps
  static int getMinutesFromSetsAndReps(int sets, int reps) {
    if (sets == 0 || reps == 0) {
      return 0;
    }
    else {
      return ((reps * 4) * sets) + (max((sets - 1), 1) * 30);
    }
  }
}