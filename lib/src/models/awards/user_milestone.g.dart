// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_milestone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMilestone _$UserMilestoneFromJson(Map<String, dynamic> json) =>
    UserMilestone(
      json['userId'] as String,
      json['name'] as String,
      json['milestoneCategory'] as String,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserMilestoneToJson(UserMilestone instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'milestoneCategory': instance.milestoneCategory,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
