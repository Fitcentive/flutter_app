import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_search_suggestion.g.dart';

@JsonSerializable()
class FoodSearchSuggestion extends Equatable {
  final List<String> suggestion;

  const FoodSearchSuggestion(
      this.suggestion,
      );

  factory FoodSearchSuggestion.fromJson(Map<String, dynamic> json) => _$FoodSearchSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchSuggestionToJson(this);

  @override
  List<Object?> get props => [
    suggestion,
  ];
}