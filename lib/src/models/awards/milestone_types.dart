import 'package:flutter_app/src/models/awards/award_categories.dart';

abstract class MilestoneType {
  AwardCategory category();
  String name();
}

abstract class StepMilestone extends MilestoneType{
  @override
  AwardCategory category() => StepData();
}

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
