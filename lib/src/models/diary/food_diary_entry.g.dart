// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodDiaryEntry _$FoodDiaryEntryFromJson(Map<String, dynamic> json) =>
    FoodDiaryEntry(
      json['id'] as String,
      json['userId'] as String,
      json['foodId'] as int,
      json['servingId'] as int,
      (json['numberOfServings'] as num).toDouble(),
      json['mealEntry'] as String,
      DateTime.parse(json['entryDate'] as String),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
      json['meetupId'] as String?,
    );

Map<String, dynamic> _$FoodDiaryEntryToJson(FoodDiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'foodId': instance.foodId,
      'servingId': instance.servingId,
      'numberOfServings': instance.numberOfServings,
      'mealEntry': instance.mealEntry,
      'entryDate': instance.entryDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'meetupId': instance.meetupId,
    };
