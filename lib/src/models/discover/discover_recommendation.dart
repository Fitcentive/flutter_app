import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/matched_attributes.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'discover_recommendation.g.dart';

@JsonSerializable()
class DiscoverRecommendation extends Equatable {
  final PublicUserProfile user;
  final num discoverScore;
  final MatchedAttributes matchedAttributes;

  const DiscoverRecommendation(this.user, this.discoverScore, this.matchedAttributes);

  factory DiscoverRecommendation.fromJson(Map<String, dynamic> json) => _$DiscoverRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverRecommendationToJson(this);

  @override
  List<Object?> get props => [user, discoverScore, matchedAttributes];
}