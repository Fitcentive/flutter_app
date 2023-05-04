// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodSearchSuggestion _$FoodSearchSuggestionFromJson(
        Map<String, dynamic> json) =>
    FoodSearchSuggestion(
      (json['suggestion'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FoodSearchSuggestionToJson(
        FoodSearchSuggestion instance) =>
    <String, dynamic>{
      'suggestion': instance.suggestion,
    };
