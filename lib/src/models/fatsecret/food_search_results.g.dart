// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodSearchResults _$FoodSearchResultsFromJson(Map<String, dynamic> json) =>
    FoodSearchResults(
      FoodResults.fromJson(json['foods'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FoodSearchResultsToJson(FoodSearchResults instance) =>
    <String, dynamic>{
      'foods': instance.foods,
    };
