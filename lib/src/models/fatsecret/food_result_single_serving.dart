import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/single_serving.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_result_single_serving.g.dart';

@JsonSerializable()
class FoodResultSingleServing extends Equatable {
  final String food_id;
  final String food_name;
  final String food_type;
  final String food_url;
  final SingleServing servings;

  const FoodResultSingleServing(
      this.food_id,
      this.food_name,
      this.food_type,
      this.food_url,
      this.servings
      );

  factory FoodResultSingleServing.fromJson(Map<String, dynamic> json) => _$FoodResultSingleServingFromJson(json);

  Map<String, dynamic> toJson() => _$FoodResultSingleServingToJson(this);

  @override
  List<Object?> get props => [
    servings
  ];

}