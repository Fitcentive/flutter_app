// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodSearchResult _$FoodSearchResultFromJson(Map<String, dynamic> json) =>
    FoodSearchResult(
      json['brand_name'] as String?,
      json['food_description'] as String,
      json['food_id'] as String,
      json['food_name'] as String,
      json['food_type'] as String,
      json['food_url'] as String,
    );

Map<String, dynamic> _$FoodSearchResultToJson(FoodSearchResult instance) =>
    <String, dynamic>{
      'brand_name': instance.brand_name,
      'food_description': instance.food_description,
      'food_id': instance.food_id,
      'food_name': instance.food_name,
      'food_type': instance.food_type,
      'food_url': instance.food_url,
    };
