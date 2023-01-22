import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_latlng.g.dart';

@JsonSerializable()
class FourSquareLatLng extends Equatable {
  final double latitude;
  final double longitude;

  const FourSquareLatLng(this.latitude, this.longitude);

  factory FourSquareLatLng.fromJson(Map<String, dynamic> json) => _$FourSquareLatLngFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareLatLngToJson(this);

  @override
  List<Object?> get props => [
    latitude,
    longitude
  ];
}