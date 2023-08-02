import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';

abstract class AchievementsHomeState extends Equatable {
  const AchievementsHomeState();

  @override
  List<Object?> get props => [];
}

class AchievementsStateInitial extends AchievementsHomeState {

  const AchievementsStateInitial();

  @override
  List<Object?> get props => [];
}

class AchievementsLoading extends AchievementsHomeState {

  const AchievementsLoading();

  @override
  List<Object?> get props => [];
}

class AchievementsLoadedSuccess extends AchievementsHomeState {
  final List<UserMilestone> userMilestones;

  const AchievementsLoadedSuccess({
    required this.userMilestones,
  });

  @override
  List<Object?> get props => [
    userMilestones,
  ];
}