import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_food_diary_entry.g.dart';

@JsonSerializable()
class MeetupFoodDiaryEntry extends Equatable {
  final String meetupId;
  final String userId;
  final String foodEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;


  const MeetupFoodDiaryEntry(this.meetupId, this.userId, this.foodEntryId, this.createdAt, this.updatedAt);

  factory MeetupFoodDiaryEntry.fromJson(Map<String, dynamic> json) => _$MeetupFoodDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupFoodDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    meetupId,
    userId,
    foodEntryId,
    createdAt,
    updatedAt,
  ];
}