import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cardio_diary_entry.g.dart';

@JsonSerializable()
class CardioDiaryEntry extends Equatable {
  final String id;
  final String userId;
  final String workoutId;
  final String name;
  final DateTime cardioDate;
  final int durationInMinutes;
  final double caloriesBurned;
  final String? meetupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardioDiaryEntry(
      this.id,
      this.userId,
      this.workoutId,
      this.name,
      this.cardioDate,
      this.durationInMinutes,
      this.caloriesBurned,
      this.meetupId,
      this.createdAt,
      this.updatedAt
  );

  factory CardioDiaryEntry.fromJson(Map<String, dynamic> json) => _$CardioDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CardioDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    workoutId,
    name,
    cardioDate,
    durationInMinutes,
    caloriesBurned,
    meetupId,
    createdAt,
    updatedAt,
  ];

}

class CardioDiaryEntryCreate extends Equatable {
  final String workoutId;
  final String name;
  final DateTime cardioDate;
  final int durationInMinutes;
  final double caloriesBurned;
  final String? meetupId;

  const CardioDiaryEntryCreate(
      this.workoutId,
      this.name,
      this.cardioDate,
      this.durationInMinutes,
      this.caloriesBurned,
      this.meetupId
  );

  @override
  List<Object?> get props => [
    workoutId,
    name,
    cardioDate,
    durationInMinutes,
    caloriesBurned,
    meetupId,
  ];
}