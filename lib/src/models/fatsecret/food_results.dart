import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_results.g.dart';

@JsonSerializable()
class FoodResults extends Equatable {
  final List<FoodSearchResult> food;
  final String max_results;
  final String page_number;
  final String total_results;

  const FoodResults(
      this.food,
      this.max_results,
      this.page_number,
      this.total_results,
      );

  factory FoodResults.fromJson(Map<String, dynamic> json) => _$FoodResultsFromJson(json);

  Map<String, dynamic> toJson() => _$FoodResultsToJson(this);

  @override
  List<Object?> get props => [
    food,
    max_results,
    total_results,
    page_number,
  ];
}