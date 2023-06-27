import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_strength_diary_entry.g.dart';

@JsonSerializable()
class MeetupStrengthDiaryEntry extends Equatable {
  final String meetupId;
  final String userId;
  final String strengthEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;


  const MeetupStrengthDiaryEntry(this.meetupId, this.userId, this.strengthEntryId, this.createdAt, this.updatedAt);

  factory MeetupStrengthDiaryEntry.fromJson(Map<String, dynamic> json) => _$MeetupStrengthDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupStrengthDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    meetupId,
    userId,
    strengthEntryId,
    createdAt,
    updatedAt,
  ];
}