import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_suggestion.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_search_suggestions.g.dart';

@JsonSerializable()
class FoodSearchSuggestions extends Equatable {
  final FoodSearchSuggestion suggestions;

  const FoodSearchSuggestions(
      this.suggestions,
      );

  factory FoodSearchSuggestions.fromJson(Map<String, dynamic> json) => _$FoodSearchSuggestionsFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchSuggestionsToJson(this);

  @override
  List<Object?> get props => [
    suggestions,
  ];
}