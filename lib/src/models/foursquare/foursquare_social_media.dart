import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_social_media.g.dart';

@JsonSerializable()
class FourSquareSocialMedia extends Equatable {
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;

  const FourSquareSocialMedia(this.facebookUrl, this.instagramUrl, this.twitterUrl);

  factory FourSquareSocialMedia.fromJson(Map<String, dynamic> json) => _$FourSquareSocialMediaFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareSocialMediaToJson(this);

  @override
  List<Object?> get props => [
    facebookUrl,
    instagramUrl,
    twitterUrl,
  ];
}