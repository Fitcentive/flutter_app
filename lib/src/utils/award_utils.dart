import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/milestone_types.dart';

class AwardUtils {

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
    TenThousandSteps().name(): "10,000",
    FiftyThousandSteps().name(): "50,000",
    HundredThousandSteps().name(): "100,000",
    TwoFiftyThousandSteps().name(): "250,000",
    FiveHundredThousandSteps().name(): "500,000",
    OneMillionStepsSteps().name(): "1 million",
    TwoMillionStepsSteps().name():  "2 million",
    FiveMillionStepsSteps().name(): "5 million",
    TenMillionStepsSteps().name(): "10 million",
  };

  static Map<String, String> milestoneCategoryToDisplayNames = {
    StepData().name(): "steps",
  };


}