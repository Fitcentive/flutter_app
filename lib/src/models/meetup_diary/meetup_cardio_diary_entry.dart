import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_cardio_diary_entry.g.dart';

@JsonSerializable()
class MeetupCardioDiaryEntry extends Equatable {
  final String meetupId;
  final String userId;
  final String cardioEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;


  const MeetupCardioDiaryEntry(this.meetupId, this.userId, this.cardioEntryId, this.createdAt, this.updatedAt);

  factory MeetupCardioDiaryEntry.fromJson(Map<String, dynamic> json) => _$MeetupCardioDiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupCardioDiaryEntryToJson(this);

  @override
  List<Object?> get props => [
    meetupId,
    userId,
    cardioEntryId,
    createdAt,
    updatedAt,
  ];
}