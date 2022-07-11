// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_with_liked_user_ids.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostsWithLikedUserIds _$PostsWithLikedUserIdsFromJson(
        Map<String, dynamic> json) =>
    PostsWithLikedUserIds(
      json['postId'] as String,
      (json['userIds'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PostsWithLikedUserIdsToJson(
        PostsWithLikedUserIds instance) =>
    <String, dynamic>{
      'postId': instance.postId,
      'userIds': instance.userIds,
    };
