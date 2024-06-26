import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/milestone_types.dart';

class AwardUtils {

  static Map<String, String> awardCategoryToIconAssetPathMap = {
    StepData().name(): "assets/icons/boot_icon.png",
    DiaryEntryData().name(): "assets/icons/diary_icon.png",
    ActivityData().name(): "assets/icons/activity_icon.png",
    WeightData().name(): "assets/icons/scale_icon.png",
  };

  static List<AwardCategory> allAchievementCategories = [
    StepData(),
    DiaryEntryData(),
    ActivityData(),
    WeightData(),
  ];

  static List<AwardCategory> allProgressCategories = [
    StepData(),
    DiaryEntryData(),
    ActivityData(),
    WeightData(),
  ];

  static final List<MilestoneType> _allAchievementMilestonesForSteps = [
    TenThousandSteps(),
    FiftyThousandSteps(),
    HundredThousandSteps(),
    TwoFiftyThousandSteps(),
    FiveHundredThousandSteps(),
    OneMillionStepsSteps(),
    TwoMillionStepsSteps(),
    FiveMillionStepsSteps(),
    TenMillionStepsSteps(),
  ];

  static final List<MilestoneType> _allAchievementMilestonesForDiaryEntries = [
    TenEntries(),
    FiftyEntries(),
    HundredEntries(),
    TwoHundredFiftyEntries(),
    FiveHundredEntries(),
    ThousandEntries(),
    TwoThousandEntries(),
    FiveThousandEntries(),
    TenThousandEntries(),
    TwentyFiveThousandEntries(),
  ];

  static final List<MilestoneType> _allAchievementMilestonesForActivityMinutes = [
    OneHour(),
    TwoHours(),
    FiveHours(),
    TenHours(),
    TwentyFiveHours(),
    FiftyHours(),
    HundredHours(),
    TwoHundredFiftyHours(),
    FiveHundredHours(),
    ThousandHours(),
  ];

  static final List<MilestoneType> _allAchievementMilestonesForUserWeightData = [
    ThreeDayStreak(),
    OneWeekStreak(),
    TenDayStreak(),
    TwoWeekStreak(),
    ThreeWeekStreak(),
    OneMonthStreak(),
    TwoMonthStreak(),
    ThreeMonthStreak(),
    SixMonthStreak(),
    OneYearStreak(),
  ];

  static final Map<String, List<MilestoneType>> achievementCategoryToAllMilestonesMap = {
    StepData().name(): _allAchievementMilestonesForSteps,
    DiaryEntryData().name(): _allAchievementMilestonesForDiaryEntries,
    ActivityData().name(): _allAchievementMilestonesForActivityMinutes,
    WeightData().name(): _allAchievementMilestonesForUserWeightData,
  };

  static Map<String, String> allMilestoneNameToDisplayNames = {
    ..._stepMilestoneNameToDisplayNames,
    ..._diaryEntryMilestoneNameToDisplayNames,
    ..._activityMilestoneNameToDisplayNames,
    ..._weightMilestoneNameToDisplayNames,
  };

  static List<MilestoneType> allAchievementMilestones = [
    ..._allAchievementMilestonesForSteps,
    ..._allAchievementMilestonesForDiaryEntries,
    ..._allAchievementMilestonesForActivityMinutes,
    ..._allAchievementMilestonesForUserWeightData,
  ];

  static final Map<String, String> _stepMilestoneNameToDisplayNames = {
    TenThousandSteps().name(): "10,000 steps",
    FiftyThousandSteps().name(): "50,000 steps",
    HundredThousandSteps().name(): "100,000 steps",
    TwoFiftyThousandSteps().name(): "250,000 steps",
    FiveHundredThousandSteps().name(): "500,000 steps",
    OneMillionStepsSteps().name(): "1 million steps",
    TwoMillionStepsSteps().name():  "2 million steps",
    FiveMillionStepsSteps().name(): "5 million steps",
    TenMillionStepsSteps().name(): "10 million steps",
  };

  static final Map<String, String> _diaryEntryMilestoneNameToDisplayNames = {
    TenEntries().name(): "10 diary entries",
    FiftyEntries().name(): "50 diary entries",
    HundredEntries().name(): "100 diary entries",
    TwoHundredFiftyEntries().name(): "250 diary entries",
    FiveHundredEntries().name(): "500 diary entries",
    ThousandEntries().name(): "1000 diary entries",
    TwoThousandEntries().name():  "2000 diary entries",
    FiveThousandEntries().name(): "5000 diary entries",
    TenThousandEntries().name(): "10,000 diary entries",
    TwentyFiveThousandEntries().name(): "25,000 diary entries",
  };

  static final Map<String, String> _activityMilestoneNameToDisplayNames = {
    OneHour().name(): "1 active hour",
    TwoHours().name(): "2 active hours",
    FiveHours().name(): "5 active hours",
    TenHours().name(): "10 active hours",
    TwentyFiveHours().name(): "25 active hours",
    FiftyHours().name(): "50 active hours",
    HundredHours().name():  "100 active hours",
    TwoHundredFiftyHours().name(): "250 active hours",
    FiveHundredHours().name(): "500 active hours",
    ThousandHours().name(): "1000 active hours",
  };

  static final Map<String, String> _weightMilestoneNameToDisplayNames = {
    ThreeDayStreak().name(): "a 3 day streak",
    OneWeekStreak().name(): "a 1 week streak",
    TenDayStreak().name(): "a 10 day streak",
    TwoWeekStreak().name(): "a 2 week streak",
    ThreeWeekStreak().name(): "a 3 week streak",
    OneMonthStreak().name(): "a 1 month streak",
    TwoMonthStreak().name():  "a 2 month streak",
    ThreeMonthStreak().name(): "a 3 month streak",
    SixMonthStreak().name(): "a 6 month streak",
    OneYearStreak().name(): "a 1 year streak",
  };

  static Map<String, String> milestoneCategoryToDisplayNames = {
    StepData().name(): "steps",
    DiaryEntryData().name(): "diary entries",
    ActivityData().name(): "active hours",
    WeightData().name(): "logging your weight",
  };


}