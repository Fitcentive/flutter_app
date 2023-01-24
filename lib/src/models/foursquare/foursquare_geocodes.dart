import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_latlng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_geocodes.g.dart';

@JsonSerializable()
class FourSquareGeoCodes extends Equatable {
  final FourSquareLatLng main;

  const FourSquareGeoCodes(this.main);

  factory FourSquareGeoCodes.fromJson(Map<String, dynamic> json) => _$FourSquareGeoCodesFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareGeoCodesToJson(this);

  LatLng toGoogleMapsLatLng() => LatLng(main.latitude, main.longitude);

  @override
  List<Object?> get props => [
    main
  ];
}