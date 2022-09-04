class ConstantUtils {
  static const String API_HOST_URL = "https://api.vid.app";
  static const String API_HOSTNAME = "api.vid.app";

  static const String TERMS_AND_CONDITIONS_URL = "https://www.freeprivacypolicy.com/live/c9701c0e-9f64-4080-b73d-5594defd36f5";
  static const String PRIVACY_POLICY_URL = "https://www.freeprivacypolicy.com/live/0b5bf195-1fc5-4f99-b42c-8d22b17d6738";

  static const int DEFAULT_LIMIT = 20;
  static const int DEFAULT_NEWSFEED_LIMIT = 10;
  static const int DEFAULT_CHAT_MESSAGES_LIMIT = 50;
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

  static const String staticDeletedUserId = "aaaaaaaa-aaaa-8bbb-8bbb-aaaaaaaaaaaa";

  static const String timestampFormat = "hh:mm a     yyyy-MM-dd";
}