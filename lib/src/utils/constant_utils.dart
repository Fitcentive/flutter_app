class ConstantUtils {
  static const int DEFAULT_LIMIT = 20;
  static const int DEFAULT_OFFSET = 0;

  static const List<String> genderTypes = ['Male', 'Female', 'Other'];
  static const String defaultGender = 'Male';

  static const List<String> transportTypes = ['Walking', 'Biking', 'Transit', 'Driving'];
  static const String defaultTransport = 'Driving';

  static const int defaultMinimumAge = 18;
  static const int defaultMaximumAge = 100;

  static const double defaultSelectedHoursPerWeek = 4.0;

  static const List<String> activityTypes = [
    "Walking",
    "Running",
    "Hiking",
    "Biking",
    "Rock Climbing",
    "Swimming",
    "Football",
    "Basketball",
    "Lifting Weights",
    "Hockey",
  ];

  static const List<String> days = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  static const List<String> genders = [
    "Male",
    "Female",
    "Other",
  ];

  static const List<String> fitnessGoals = [
    "Lose Weight",
    "Gain Muscle",
    "Improve Cardio",
    "Strength Training",
    "Keeping Active",
  ];

  static const Map<String, String> bodyTypes = {
    "Lean": "assets/images/lean_body_type.png",
    "Hybrid": "assets/images/hybrid_body_type.png",
    "Bulky": "assets/images/bulky_body_type.png",
  };
}