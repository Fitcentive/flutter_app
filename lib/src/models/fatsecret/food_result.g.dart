// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodResult _$FoodResultFromJson(Map<String, dynamic> json) => FoodResult(
      json['food_id'] as String,
      json['food_name'] as String,
      json['food_type'] as String,
      json['food_url'] as String,
      Servings.fromJson(json['servings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FoodResultToJson(FoodResult instance) =>
    <String, dynamic>{
      'food_id': instance.food_id,
      'food_name': instance.food_name,
      'food_type': instance.food_type,
      'food_url': instance.food_url,
      'servings': instance.servings,
    };
