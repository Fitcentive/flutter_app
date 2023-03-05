// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodResults _$FoodResultsFromJson(Map<String, dynamic> json) => FoodResults(
      (json['food'] as List<dynamic>)
          .map((e) => FoodSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['max_results'] as String,
      json['page_number'] as String,
      json['total_results'] as String,
    );

Map<String, dynamic> _$FoodResultsToJson(FoodResults instance) =>
    <String, dynamic>{
      'food': instance.food,
      'max_results': instance.max_results,
      'page_number': instance.page_number,
      'total_results': instance.total_results,
    };
