// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_follow_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFollowStatus _$UserFollowStatusFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'isCurrentUserFollowingOtherUser',
      'isOtherUserFollowingCurrentUser',
      'hasCurrentUserRequestedToFollowOtherUser',
      'hasOtherUserRequestedToFollowCurrentUser'
    ],
  );
  return UserFollowStatus(
    json['isCurrentUserFollowingOtherUser'] as bool,
    json['isOtherUserFollowingCurrentUser'] as bool,
    json['hasCurrentUserRequestedToFollowOtherUser'] as bool,
    json['hasOtherUserRequestedToFollowCurrentUser'] as bool,
  );
}

Map<String, dynamic> _$UserFollowStatusToJson(UserFollowStatus instance) =>
    <String, dynamic>{
      'isCurrentUserFollowingOtherUser':
          instance.isCurrentUserFollowingOtherUser,
      'isOtherUserFollowingCurrentUser':
          instance.isOtherUserFollowingCurrentUser,
      'hasCurrentUserRequestedToFollowOtherUser':
          instance.hasCurrentUserRequestedToFollowOtherUser,
      'hasOtherUserRequestedToFollowCurrentUser':
          instance.hasOtherUserRequestedToFollowCurrentUser,
    };
