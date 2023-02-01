import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_availability.g.dart';

@JsonSerializable()
class MeetupAvailability extends Equatable {
  final String id;
  final String meetupId;
  final String userId;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetupAvailability(
      this.id,
      this.meetupId,
      this.userId,
      this.availabilityStart,
      this.availabilityEnd,
      this.createdAt,
      this.updatedAt
  );

  factory MeetupAvailability.fromJson(Map<String, dynamic> json) => _$MeetupAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupAvailabilityToJson(this);

  @override
  List<Object?> get props => [
    id,
    meetupId,
    userId,
    availabilityStart,
    availabilityEnd,
    createdAt,
    updatedAt
  ];
}

// Bit of a misnomer, fix eventually
class MeetupAvailabilityUpsert extends Equatable {
  final DateTime availabilityStart;
  final DateTime availabilityEnd;

  const MeetupAvailabilityUpsert(this.availabilityStart, this.availabilityEnd);

  @override
  List<Object?> get props => [
    availabilityStart,
    availabilityEnd,
  ];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'availabilityStart': availabilityStart.toIso8601String(),
      'availabilityEnd': availabilityEnd.toIso8601String(),
    };
  }
}