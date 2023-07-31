import 'package:equatable/equatable.dart';

abstract class AchievementsHomeEvent extends Equatable {
  const AchievementsHomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllUserAchievements extends AchievementsHomeEvent {
  final String userId;

  const FetchAllUserAchievements({
    required this.userId
  });

  @override
  List<Object> get props => [
    userId
  ];
}
