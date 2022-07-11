// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_post_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialPostComment _$SocialPostCommentFromJson(Map<String, dynamic> json) =>
    SocialPostComment(
      json['postId'] as String,
      json['commentId'] as String,
      json['userId'] as String,
      json['text'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SocialPostCommentToJson(SocialPostComment instance) =>
    <String, dynamic>{
      'postId': instance.postId,
      'commentId': instance.commentId,
      'userId': instance.userId,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
