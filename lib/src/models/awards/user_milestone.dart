import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_milestone.g.dart';

@JsonSerializable()
class UserMilestone extends Equatable {
  final String userId;
  final String name;
  final String milestoneCategory;
  final DateTime createdAt;
  final DateTime updatedAt;


  const UserMilestone(
      this.userId,
      this.name,
      this.milestoneCategory,
      this.createdAt,
      this.updatedAt
  );

  factory UserMilestone.fromJson(Map<String, dynamic> json) => _$UserMilestoneFromJson(json);

  Map<String, dynamic> toJson() => _$UserMilestoneToJson(this);

  @override
  List<Object?> get props => [
    userId,
    name,
    milestoneCategory,
    createdAt,
    updatedAt
  ];
}