import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_friend_status.g.dart';

@JsonSerializable()
class UserFriendStatus extends Equatable {
  @JsonKey(required: true)
  final String currentUserId;

  @JsonKey(required: true)
  final String otherUserId;

  @JsonKey(required: true)
  final bool isCurrentUserFriendsWithOtherUser;

  @JsonKey(required: true)
  final bool hasCurrentUserRequestedToFriendOtherUser;

  @JsonKey(required: true)
  final bool hasOtherUserRequestedToFriendCurrentUser;

  const UserFriendStatus(
      this.currentUserId,
      this.otherUserId,
      this.isCurrentUserFriendsWithOtherUser,
      this.hasCurrentUserRequestedToFriendOtherUser,
      this.hasOtherUserRequestedToFriendCurrentUser
  );

  factory UserFriendStatus.fromJson(Map<String, dynamic> json) => _$UserFollowStatusFromJson(json);

  Map<String, dynamic> toJson() => _$UserFollowStatusToJson(this);

  @override
  List<Object?> get props => [
    currentUserId,
    otherUserId,
    isCurrentUserFriendsWithOtherUser,
    hasCurrentUserRequestedToFriendOtherUser,
    hasOtherUserRequestedToFriendCurrentUser
  ];
}
