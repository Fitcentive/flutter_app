// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverRecommendation _$DiscoverRecommendationFromJson(
        Map<String, dynamic> json) =>
    DiscoverRecommendation(
      PublicUserProfile.fromJson(json['user'] as Map<String, dynamic>),
      json['pathsInCommon'] as int,
      MatchedAttributes.fromJson(
          json['matchedAttributes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DiscoverRecommendationToJson(
        DiscoverRecommendation instance) =>
    <String, dynamic>{
      'user': instance.user,
      'pathsInCommon': instance.pathsInCommon,
      'matchedAttributes': instance.matchedAttributes,
    };
