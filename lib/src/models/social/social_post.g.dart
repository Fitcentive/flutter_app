// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialPost _$SocialPostFromJson(Map<String, dynamic> json) => SocialPost(
      json['postId'] as String,
      json['userId'] as String,
      json['text'] as String,
      json['photoUrl'] as String?,
      json['numberOfLikes'] as int,
      json['numberOfComments'] as int,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SocialPostToJson(SocialPost instance) =>
    <String, dynamic>{
      'postId': instance.postId,
      'userId': instance.userId,
      'text': instance.text,
      'photoUrl': instance.photoUrl,
      'numberOfLikes': instance.numberOfLikes,
      'numberOfComments': instance.numberOfComments,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
