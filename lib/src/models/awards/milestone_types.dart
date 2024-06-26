import 'package:flutter_app/src/models/awards/award_categories.dart';

abstract class MilestoneType {
  AwardCategory category();
  String name();
}

///-------------------------------------------------
/// Milestone types
///-------------------------------------------------

abstract class StepMilestone extends MilestoneType{
  @override
  AwardCategory category() => StepData();
}

abstract class DiaryEntryMilestone extends MilestoneType{
  @override
  AwardCategory category() => DiaryEntryData();
}

abstract class ActivityMilestone extends MilestoneType{
  @override
  AwardCategory category() => ActivityData();
}

abstract class WeightMilestone extends MilestoneType{
  @override
  AwardCategory category() => WeightData();
}

///-------------------------------------------------
/// Step milestones
///-------------------------------------------------

class TenThousandSteps extends StepMilestone {
  @override
  String name() => "TenThousandSteps";
}
class FiftyThousandSteps extends StepMilestone {
  @override
  String name() => "FiftyThousandSteps";
}
class HundredThousandSteps extends StepMilestone {
  @override
  String name() => "HundredThousandSteps";
}
class TwoFiftyThousandSteps extends StepMilestone {
  @override
  String name() => "TwoFiftyThousandSteps";
}
class FiveHundredThousandSteps extends StepMilestone {
  @override
  String name() => "FiveHundredThousandSteps";
}
class OneMillionStepsSteps extends StepMilestone {
  @override
  String name() => "OneMillionStepsSteps";
}
class TwoMillionStepsSteps extends StepMilestone {
  @override
  String name() => "TwoMillionStepsSteps";
}
class FiveMillionStepsSteps extends StepMilestone {
  @override
  String name() => "FiveMillionStepsSteps";
}
class TenMillionStepsSteps extends StepMilestone {
  @override
  String name() => "TenMillionStepsSteps";
}

///-------------------------------------------------
/// Diary entry milestones
///-------------------------------------------------
class TenEntries extends DiaryEntryMilestone {
  @override
  String name() => "TenEntries";
}
class FiftyEntries extends DiaryEntryMilestone {
  @override
  String name() => "FiftyEntries";
}
class HundredEntries extends DiaryEntryMilestone {
  @override
  String name() => "HundredEntries";
}
class TwoHundredFiftyEntries extends DiaryEntryMilestone {
  @override
  String name() => "TwoHundredFiftyEntries";
}
class FiveHundredEntries extends DiaryEntryMilestone {
  @override
  String name() => "FiveHundredEntries";
}
class ThousandEntries extends DiaryEntryMilestone {
  @override
  String name() => "ThousandEntries";
}
class TwoThousandEntries extends DiaryEntryMilestone {
  @override
  String name() => "TwoThousandEntries";
}
class FiveThousandEntries extends DiaryEntryMilestone {
  @override
  String name() => "FiveThousandEntries";
}
class TenThousandEntries extends DiaryEntryMilestone {
  @override
  String name() => "TenThousandEntries";
}
class TwentyFiveThousandEntries extends DiaryEntryMilestone {
  @override
  String name() => "TwentyFiveThousandEntries";
}

///-------------------------------------------------
/// Activity milestones
///-------------------------------------------------
class OneHour extends ActivityMilestone {
  @override
  String name() => "OneHour";
}
class TwoHours extends ActivityMilestone {
  @override
  String name() => "TwoHours";
}
class FiveHours extends ActivityMilestone {
  @override
  String name() => "FiveHours";
}
class TenHours extends ActivityMilestone {
  @override
  String name() => "TenHours";
}
class TwentyFiveHours extends ActivityMilestone {
  @override
  String name() => "TwentyFiveHours";
}
class FiftyHours extends ActivityMilestone {
  @override
  String name() => "FiftyHours";
}
class HundredHours extends ActivityMilestone {
  @override
  String name() => "HundredHours";
}
class TwoHundredFiftyHours extends ActivityMilestone {
  @override
  String name() => "TwoHundredFiftyHours";
}
class FiveHundredHours extends ActivityMilestone {
  @override
  String name() => "FiveHundredHours";
}
class ThousandHours extends ActivityMilestone {
  @override
  String name() => "ThousandHours";
}

///-------------------------------------------------
/// Weight milestones
///-------------------------------------------------
class ThreeDayStreak extends WeightMilestone {
  @override
  String name() => "ThreeDayStreak";
}
class OneWeekStreak extends WeightMilestone {
  @override
  String name() => "OneWeekStreak";
}
class TenDayStreak extends WeightMilestone {
  @override
  String name() => "TenDayStreak";
}
class TwoWeekStreak extends WeightMilestone {
  @override
  String name() => "TwoWeekStreak";
}
class ThreeWeekStreak extends WeightMilestone {
  @override
  String name() => "ThreeWeekStreak";
}
class OneMonthStreak extends WeightMilestone {
  @override
  String name() => "OneMonthStreak";
}
class TwoMonthStreak extends WeightMilestone {
  @override
  String name() => "TwoMonthStreak";
}
class ThreeMonthStreak extends WeightMilestone {
  @override
  String name() => "ThreeMonthStreak";
}
class SixMonthStreak extends WeightMilestone {
  @override
  String name() => "SixMonthStreak";
}
class OneYearStreak extends WeightMilestone {
  @override
  String name() => "OneYearStreak";
}