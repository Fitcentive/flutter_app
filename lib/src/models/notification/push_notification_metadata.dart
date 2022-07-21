import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_notification_metadata.g.dart';

@JsonSerializable()
class PushNotificationMetadata extends Equatable {
  final String type;

  const PushNotificationMetadata(this.type);

  factory PushNotificationMetadata.fromJson(Map<String, dynamic> json) => _$PushNotificationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PushNotificationMetadataToJson(this);

  @override
  List<Object> get props => [type];
}