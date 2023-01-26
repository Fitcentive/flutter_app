import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_result.dart';
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

  @override
  List<Object?> get props => [
   locationId, location
  ];
}