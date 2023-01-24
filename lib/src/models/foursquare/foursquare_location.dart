import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_location.g.dart';

@JsonSerializable()
class FourSquareLocation extends Equatable {
  final String? address;
  final String? country;
  final String? formattedAddress;
  final String? locality;
  final String? region;

  const FourSquareLocation(this.address, this.country, this.formattedAddress, this.locality, this.region);

  factory FourSquareLocation.fromJson(Map<String, dynamic> json) => _$FourSquareLocationFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareLocationToJson(this);

  @override
  List<Object?> get props => [
    address,
    country,
    formattedAddress,
    locality,
    region,
  ];
}