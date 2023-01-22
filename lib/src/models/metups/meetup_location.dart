import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meetup_location.g.dart';

@JsonSerializable()
class MeetupLocation extends Equatable {
  final String id;
  final String fsqId;
  final String? locationName;
  final String? website;
  final String? phone;
  final Coordinates coordinates;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetupLocation(
      this.id,
      this.fsqId,
      this.locationName,
      this.website,
      this.phone,
      this.coordinates,
      this.createdAt,
      this.updatedAt
  );

  factory MeetupLocation.fromJson(Map<String, dynamic> json) => _$MeetupLocationFromJson(json);

  Map<String, dynamic> toJson() => _$MeetupLocationToJson(this);

  @override
  List<Object?> get props => [
    id,
    fsqId,
    locationName,
    website,
    phone,
    coordinates,
    createdAt,
    updatedAt,
  ];
}

class MeetupLocationPost extends Equatable {
  final String id;
  final String fsqId;
  final String? locationName;
  final String? website;
  final String? phone;
  final Coordinates coordinates;

  const MeetupLocationPost(
      this.id,
      this.fsqId,
      this.locationName,
      this.website,
      this.phone,
      this.coordinates,
  );

  @override
  List<Object?> get props => [
    id,
    fsqId,
    locationName,
    website,
    phone,
    coordinates,
  ];
}