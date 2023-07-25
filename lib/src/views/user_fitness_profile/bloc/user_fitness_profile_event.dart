import 'package:equatable/equatable.dart';

abstract class UserFitnessProfileEvent extends Equatable {
  const UserFitnessProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpsertUserFitnessProfile extends UserFitnessProfileEvent {
  final String userId;
  final double heightInCm;
  final double weightInLbs;
  final String goal;
  final String activityLevel;
  final int? stepGoalPerDay;
  final double? goalWeightInLbs;

  const UpsertUserFitnessProfile({
    required this.userId,
    required this.heightInCm,
    required this.weightInLbs,
    required this.goal,
    required this.activityLevel,
    required this.stepGoalPerDay,
    required this.goalWeightInLbs,
  });

  @override
  List<Object?> get props => [
    userId,
    heightInCm,
    weightInLbs,
    goal,
    activityLevel,
    stepGoalPerDay,
    goalWeightInLbs,
  ];
}
