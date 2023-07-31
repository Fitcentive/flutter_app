abstract class AwardCategory {
  String name();
}

class StepData extends AwardCategory {
  @override
  String name() => "StepData";
}

class DiaryEntryData extends AwardCategory {
  @override
  String name() => "DiaryEntryData";
}

class ActivityData extends AwardCategory {
  @override
  String name() => "ActivityData";
}

