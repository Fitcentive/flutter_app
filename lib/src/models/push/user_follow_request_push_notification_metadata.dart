import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_follow_request_push_notification_metadata.g.dart';

@JsonSerializable()
class UserFollowRequestPushNotificationMetadata extends Equatable {
  final String type;
  final String requestingUserId;
  final String targetUserId;
  final String requestingUserPhotoUrl;


  const UserFollowRequestPushNotificationMetadata(this.type, this.requestingUserId, this.targetUserId, this.requestingUserPhotoUrl);

  factory UserFollowRequestPushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$UserFollowRequestPushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$UserFollowRequestPushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type, requestingUserId, targetUserId, requestingUserPhotoUrl];
}