import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConstantUtils {
  static final String stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";

  static const String APP_BASE_URL = "https://app.fitcentive.xyz";
  static const String API_HOST_URL = "https://api.fitcentive.xyz";
  static const String AUTH_HOST_URL = "https://auth.fitcentive.xyz";

  static const String API_HOSTNAME = "api.fitcentive.xyz";
  static const String AUTH_HOSTNAME = "auth.fitcentive.xyz";

  static const String WGER_API_HOST = "https://wger.de";

  static const String NEWSFEED_INTRO_POST_PHOTO_URL = "https://images.pexels.com/photos/40751/running-runner-long-distance-fitness-40751.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1";

  static const String TERMS_AND_CONDITIONS_URL = "https://www.freeprivacypolicy.com/live/c9701c0e-9f64-4080-b73d-5594defd36f5";
  static const String PRIVACY_POLICY_URL = "https://www.freeprivacypolicy.com/live/0b5bf195-1fc5-4f99-b42c-8d22b17d6738";

  static const String FALLBACK_URL = "https://www.google.ca";

  static const String FATSECRET_ATTRIBUTION_URL = "https://platform.fatsecret.com";
  static const String WGER_ATTRIBUTION_URL = "https://wger.de/en/software/api";

  static const double WEB_APP_MAX_WIDTH = 600;

  static const int MAX_LOGIN_FAILURES_BEFORE_PWD_RESET_PROMPT = 3;

  static const int DEFAULT_LIMIT = 20;
  static const int DEFAULT_MEETUP_LIMIT = 5;
  static const int DEFAULT_MAX_LIMIT = 100000;
  static const int DEFAULT_NEWSFEED_LIMIT = 10;
  static const int DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT = 20;
  static const int DEFAULT_DISCOVER_RECOMMENDATIONS_LIMIT = 10;
  static const int DEFAULT_CHAT_MESSAGES_LIMIT = 50;
  static const int DEFAULT_CHAT_ROOMS_LIMIT = 20;
  static const int DEFAULT_OFFSET = 0;

  static const EARLIEST_YEAR = 1970;
  static const LATEST_YEAR = 2050;

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

  static const String premiumFeatures = """
  - #### No ads
  - #### Discover unlimited users
  - #### Unlimited meetups per month
  - #### Multi user meetups
  - #### Group chats
  - #### Support the developer
  """;

  static const String passwordRules = """
  ### Password rules
  - At least one uppercase character
  - At least one lowercase character
  - At least one digit
  - At least one special character
  - At least 8 characters in length
  """;

  static const String staticDeletedUserId = "aaaaaaaa-aaaa-8bbb-8bbb-aaaaaaaaaaaa";

  static const String timestampFormat = "hh:mm a     yyyy-MM-dd";

  static const int CARDIO_EXERCISE_CATEGORY_DEFINITION = 15;

  // 7 + 1 = 8
  static const int MAX_OTHER_MEETUP_PARTICIPANTS_PREMIUM = 7;
  static const int MAX_OTHER_CHAT_PARTICIPANTS_PREMIUM = 7;

  static const int MAX_OTHER_MEETUP_PARTICIPANTS_FREE = 1;
  static const int MAX_OTHER_CHAT_PARTICIPANTS_FREE = 1;

  static const int MAX_FREE_USER_MEETUPS_PER_MONTH_LIMIT = 4;

  static const int MAX_DISCOVERABLE_USERS_PER_MONTH_FREE = 5;

  static const String baseCardNumbers = "4242 4242 4242 ";
}