import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_search_result.g.dart';

@JsonSerializable()
class FoodSearchResult extends Equatable {
  final String? brand_name;
  final String food_description;
  final String food_id;
  final String food_name;
  final String food_type;
  final String food_url;

  const FoodSearchResult(
      this.brand_name,
      this.food_description,
      this.food_id,
      this.food_name,
      this.food_type,
      this.food_url
  );

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) => _$FoodSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchResultToJson(this);

  @override
  List<Object?> get props => [
    brand_name,
    food_description,
    food_id,
    food_name,
    food_type,
    food_url
  ];
}