import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_fitness_preferences.g.dart';

@JsonSerializable()
class UserFitnessPreferences extends Equatable {
  final String userId;
  final List<String> activitiesInterestedIn;
  final List<String> fitnessGoals;
  final List<String> desiredBodyTypes;
  final DateTime createdAt;
  final DateTime updatedAt;


  const UserFitnessPreferences(
      this.userId,
      this.activitiesInterestedIn,
      this.fitnessGoals,
      this.desiredBodyTypes,
      this.createdAt,
      this.updatedAt
      );

  factory UserFitnessPreferences.fromJson(Map<String, dynamic> json) => _$UserFitnessPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserFitnessPreferencesToJson(this);

  @override
  List<Object?> get props => [
    userId,
    activitiesInterestedIn,
    fitnessGoals,
    desiredBodyTypes,
    createdAt,
    updatedAt,
  ];
}

class UserFitnessPreferencesPost extends Equatable {
  final String userId;
  final List<String> activitiesInterestedIn;
  final List<String> fitnessGoals;
  final List<String> desiredBodyTypes;

  const UserFitnessPreferencesPost({
    required this.userId,
    required this.activitiesInterestedIn,
    required this.fitnessGoals,
    required this.desiredBodyTypes
  });

  @override
  List<Object?> get props => [
    userId,
    activitiesInterestedIn,
    fitnessGoals,
    desiredBodyTypes,
  ];

}