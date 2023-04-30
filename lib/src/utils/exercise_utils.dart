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
}