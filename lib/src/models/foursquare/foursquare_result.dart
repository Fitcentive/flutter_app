import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_category.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_geocodes.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_hours.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_location.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_photos.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_social_media.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_result.g.dart';

@JsonSerializable()
class FourSquareResult extends Equatable {

  final String fsqId;
  final List<FourSquareCategory> categories;
  final int distance;
  final FourSquareGeoCodes geocodes;
  final String link;
  final FourSquareLocation location;
  final String name;
  final int? price;
  final double? rating;
  final String? tel;
  final String? website;
  final FourSquareSocialMedia? socialMedia;
  final FourSquareHours hours;
  final List<FourSquarePhoto>? photos;

  const FourSquareResult(
      this.fsqId,
      this.categories,
      this.distance,
      this.geocodes,
      this.link,
      this.location,
      this.name,
      this.price,
      this.rating,
      this.tel,
      this.website,
      this.socialMedia,
      this.hours,
      this.photos
  );

  factory FourSquareResult.fromJson(Map<String, dynamic> json) => _$FourSquareResultFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareResultToJson(this);

  @override
  List<Object?> get props => [
    fsqId,
    categories,
    distance,
    geocodes,
    link,
    location,
    name,
    price,
    rating,
    tel,
    website,
    socialMedia,
    hours,
    photos,
  ];
}