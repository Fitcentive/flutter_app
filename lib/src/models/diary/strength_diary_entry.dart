import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'strength_diary_entry.g.dart';

@JsonSerializable()
class StrengthDiaryEntry extends Equatable {
  final String id;
  final String userId;
  final String workoutId;
  final String name;
  final DateTime exerciseDate;
  final int sets;
  final int reps;
  final List<int> weightsInLbs;
  final double caloriesBurned;
  final String? meetupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StrengthDiaryEntry(
      this.id,
      this.userId,
      this.workoutId,
      this.name,
      this.exerciseDate,
      this.sets,
      this.reps,
      this.weightsInLbs,
      this.caloriesBurned,
      this.meetupId,
      this.createdAt,
      this.updatedAt
  );

  factory StrengthDiaryEntry.fromJson(Map<String, dynamic> json) => _$StrengthDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$StrengthDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    workoutId,
    name,
    exerciseDate,
    sets,
    reps,
    weightsInLbs,
    caloriesBurned,
    meetupId,
    createdAt,
    updatedAt,
  ];

}

class StrengthDiaryEntryCreate extends Equatable {
  final String workoutId;
  final String name;
  final DateTime exerciseDate;
  final int sets;
  final int reps;
  final List<int> weightsInLbs;
  final double caloriesBurned;
  final String? meetupId;

  const StrengthDiaryEntryCreate({
    required this.workoutId,
    required this.name,
    required this.exerciseDate,
    required this.sets,
    required this.reps,
    required this.weightsInLbs,
    required this.caloriesBurned,
    required this.meetupId
  });

  @override
  List<Object?> get props => [
    workoutId,
    name,
    exerciseDate,
    sets,
    reps,
    weightsInLbs,
    caloriesBurned,
    meetupId,
  ];

}