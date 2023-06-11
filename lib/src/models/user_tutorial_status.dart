import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_tutorial_status.g.dart';

@JsonSerializable()
class UserTutorialStatus extends Equatable {
  final String userId;
  final bool isTutorialComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTutorialStatus(
      this.userId,
      this.isTutorialComplete,
      this.createdAt,
      this.updatedAt
  );

  factory UserTutorialStatus.fromJson(Map<String, dynamic> json) => _$UserTutorialStatusFromJson(json);

  Map<String, dynamic> toJson() => _$UserTutorialStatusToJson(this);

  @override
  List<Object?> get props => [
    userId,
    isTutorialComplete,
    createdAt,
    updatedAt
  ];
}