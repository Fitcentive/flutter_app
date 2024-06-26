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
  final String? chatRoomId;
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
      this.chatRoomId,
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
    chatRoomId,
    createdAt,
    updatedAt,
  ];
}

class MeetupCreate extends Equatable {

  final String ownerId;
  final String meetupType;
  final String? name;
  final DateTime? time;
  final int? durationInMinutes;
  final String? locationId;


  const MeetupCreate({
    required this.ownerId,
    required this.meetupType,
    this.name,
    this.time,
    this.durationInMinutes,
    this.locationId
  });

  @override
  List<Object?> get props => [
    ownerId,
    meetupType,
    name,
    time,
    durationInMinutes,
    locationId,
  ];

}

class MeetupUpdate extends Equatable {

  final String meetupType;
  final String? name;
  final DateTime? time;
  final int? durationInMinutes;
  final String? locationId;
  final String? chatRoomId;


  const MeetupUpdate({
    required this.meetupType,
    this.name,
    this.time,
    this.durationInMinutes,
    this.locationId,
    this.chatRoomId
  });

  @override
  List<Object?> get props => [
    meetupType,
    name,
    time,
    durationInMinutes,
    locationId,
    chatRoomId,
  ];

}