import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_results.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_search_results.g.dart';

@JsonSerializable()
class FoodSearchResults extends Equatable {
  final FoodResults foods;

  const FoodSearchResults(
      this.foods,
      );

  factory FoodSearchResults.fromJson(Map<String, dynamic> json) => _$FoodSearchResultsFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchResultsToJson(this);

  @override
  List<Object?> get props => [
    foods,
  ];
}