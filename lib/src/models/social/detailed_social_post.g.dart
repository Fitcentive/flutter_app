// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detailed_social_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetailedSocialPost _$DetailedSocialPostFromJson(Map<String, dynamic> json) =>
    DetailedSocialPost(
      SocialPost.fromJson(json['post'] as Map<String, dynamic>),
      (json['likedUserIds'] as List<dynamic>).map((e) => e as String).toList(),
      (json['mostRecentComments'] as List<dynamic>)
          .map((e) => SocialPostComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DetailedSocialPostToJson(DetailedSocialPost instance) =>
    <String, dynamic>{
      'post': instance.post,
      'likedUserIds': instance.likedUserIds,
      'mostRecentComments': instance.mostRecentComments,
    };
