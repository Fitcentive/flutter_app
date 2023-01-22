// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_friend_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFriendStatus _$UserFriendStatusFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'currentUserId',
      'otherUserId',
      'isCurrentUserFriendsWithOtherUser',
      'hasCurrentUserRequestedToFriendOtherUser',
      'hasOtherUserRequestedToFriendCurrentUser'
    ],
  );
  return UserFriendStatus(
    json['currentUserId'] as String,
    json['otherUserId'] as String,
    json['isCurrentUserFriendsWithOtherUser'] as bool,
    json['hasCurrentUserRequestedToFriendOtherUser'] as bool,
    json['hasOtherUserRequestedToFriendCurrentUser'] as bool,
  );
}

Map<String, dynamic> _$UserFriendStatusToJson(UserFriendStatus instance) =>
    <String, dynamic>{
      'currentUserId': instance.currentUserId,
      'otherUserId': instance.otherUserId,
      'isCurrentUserFriendsWithOtherUser':
          instance.isCurrentUserFriendsWithOtherUser,
      'hasCurrentUserRequestedToFriendOtherUser':
          instance.hasCurrentUserRequestedToFriendOtherUser,
      'hasOtherUserRequestedToFriendCurrentUser':
          instance.hasOtherUserRequestedToFriendCurrentUser,
    };
