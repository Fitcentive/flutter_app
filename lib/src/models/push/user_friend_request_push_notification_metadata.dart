import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_friend_request_push_notification_metadata.g.dart';

@JsonSerializable()
class UserFriendRequestPushNotificationMetadata extends Equatable {
  final String type;
  final String requestingUserId;
  final String targetUserId;
  final String requestingUserPhotoUrl;


  const UserFriendRequestPushNotificationMetadata(this.type, this.requestingUserId, this.targetUserId, this.requestingUserPhotoUrl);

  factory UserFriendRequestPushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$UserFriendRequestPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$UserFriendRequestPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type, requestingUserId, targetUserId, requestingUserPhotoUrl];
}