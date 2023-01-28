import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup.g.dart';

@JsonSerializable()
class Meetup extends Equatable {
  final String id;
  final String ownerId;
  final String meetupType;
  final String meetupStatus;
  final String? name;
  final DateTime? time;
  final int? durationInMinutes;
  final String? locationId;
  final DateTime createdAt;
  final DateTime updatedAt;


  const Meetup(
      this.id,
      this.ownerId,
      this.meetupType,
      this.meetupStatus,
      this.name,
      this.time,
      this.durationInMinutes,
      this.locationId,
      this.createdAt,
      this.updatedAt
  );

  factory Meetup.fromJson(Map<String, dynamic> json) => _$MeetupFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerId,
    meetupType,
    meetupStatus,
    name,
    time,
    durationInMinutes,
    locationId,
    createdAt,
    updatedAt,
  ];
}