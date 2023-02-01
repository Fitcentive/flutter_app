import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_result.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location extends Equatable {
  final String locationId;
  final FourSquareResult location;

  const Location(this.locationId, this.location);

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  MeetupLocation toMeetupLocation() =>
      MeetupLocation(
          locationId,
          location.fsqId,
          location.name,
          location.website,
          location.tel,
          Coordinates(location.geocodes.main.latitude, location.geocodes.main.longitude),
          DateTime.now(),
          DateTime.now()
      );

  @override
  List<Object?> get props => [
   locationId, location
  ];
}