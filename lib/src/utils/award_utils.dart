import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/milestone_types.dart';

class AwardUtils {

  static Map<String, String> awardCategoryToIconAssetPathMap = {
    StepData().name(): "assets/icons/boot_icon.png",
    DiaryEntryData().name(): "assets/icons/diary_icon.png",
    ActivityData().name(): "assets/icons/activity_icon.png",
  };

  static List<AwardCategory> allAchievementCategories = [
    StepData(),
    DiaryEntryData(),
    ActivityData(),
  ];

  static List<MilestoneType> allAchievementMilestonesForSteps = [
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

  static final Map<String, List<MilestoneType>> achievementCategoryToAllMilestonesMap = {
    StepData().name(): allAchievementMilestonesForSteps,
    DiaryEntryData().name(): [],
    ActivityData().name(): [],
  };

  static Map<String, String> allMilestoneNameToDisplayNames = {
    ..._stepMilestoneNameToDisplayNames
  };

  static List<MilestoneType> allAchievementMilestones = [
    ...allAchievementMilestonesForSteps
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

  static Map<String, String> milestoneCategoryToDisplayNames = {
    StepData().name(): "steps",
  };


}