import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_steps_data.g.dart';

@JsonSerializable()
class UserStepsData extends Equatable {
  final String id;
  final String userId;
  final int steps;
  final double caloriesBurned;
  final String entryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStepsData(
      this.id,
      this.userId,
      this.steps,
      this.caloriesBurned,
      this.entryDate,
      this.createdAt,
      this.updatedAt,
      );

  factory UserStepsData.fromJson(Map<String, dynamic> json) => _$UserStepsDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserStepsDataToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    steps,
    caloriesBurned,
    entryDate,
    createdAt,
    updatedAt,
  ];

}

class UserStepsDataUpsert extends Equatable {
  final int stepsTaken;
  final String dateString;

  const UserStepsDataUpsert({
    required this.stepsTaken,
    required this.dateString,
  });

  @override
  List<Object?> get props => [
    stepsTaken,
    dateString,
  ];

}

