import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fitness_user_profile.g.dart';

@JsonSerializable()
class FitnessUserProfile extends Equatable {
  @JsonKey(required: true)
  final String userId;

  final double heightInCm;
  final double weightInLbs;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String goal;
  final String activityLevel;
  final int? stepGoalPerDay;
  final double? goalWeightInLbs;

  const FitnessUserProfile(
      this.userId,
      this.heightInCm,
      this.weightInLbs,
      this.createdAt,
      this.updatedAt,
      this.goal,
      this.activityLevel,
      this.stepGoalPerDay,
      this.goalWeightInLbs,
      );

  factory FitnessUserProfile.fromJson(Map<String, dynamic> json) => _$FitnessUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessUserProfileToJson(this);

  @override
  List<Object?> get props => [
    userId,
    heightInCm,
    weightInLbs,
    createdAt,
    updatedAt,
    goal,
    activityLevel,
    stepGoalPerDay,
    goalWeightInLbs,
  ];
}

class FitnessUserProfileUpdate {
  final double heightInCm;
  final double weightInLbs;
  final String goal;
  final String activityLevel;
  final int? stepGoalPerDay;
  final double? goalWeightInLbs;

  const FitnessUserProfileUpdate({
    required this.heightInCm,
    required this.weightInLbs,
    required this.goal,
    required this.activityLevel,
    required this.stepGoalPerDay,
    required this.goalWeightInLbs,
  });
}