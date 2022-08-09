import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_follow_status.g.dart';

@JsonSerializable()
class UserFollowStatus extends Equatable {
  @JsonKey(required: true)
  final String currentUserId;

  @JsonKey(required: true)
  final String otherUserId;

  @JsonKey(required: true)
  final bool isCurrentUserFollowingOtherUser;

  @JsonKey(required: true)
  final bool isOtherUserFollowingCurrentUser;

  @JsonKey(required: true)
  final bool hasCurrentUserRequestedToFollowOtherUser;

  @JsonKey(required: true)
  final bool hasOtherUserRequestedToFollowCurrentUser;

  const UserFollowStatus(
      this.currentUserId,
      this.otherUserId,
      this.isCurrentUserFollowingOtherUser,
      this.isOtherUserFollowingCurrentUser,
      this.hasCurrentUserRequestedToFollowOtherUser,
      this.hasOtherUserRequestedToFollowCurrentUser
  );

  factory UserFollowStatus.fromJson(Map<String, dynamic> json) => _$UserFollowStatusFromJson(json);

  Map<String, dynamic> toJson() => _$UserFollowStatusToJson(this);

  @override
  List<Object?> get props => [
    currentUserId,
    otherUserId,
    isCurrentUserFollowingOtherUser,
    isOtherUserFollowingCurrentUser,
    hasCurrentUserRequestedToFollowOtherUser,
    hasOtherUserRequestedToFollowCurrentUser
  ];
}
