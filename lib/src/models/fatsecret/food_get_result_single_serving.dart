import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_result_single_serving.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_get_result_single_serving.g.dart';

@JsonSerializable()
class FoodGetResultSingleServing extends Equatable {
  final FoodResultSingleServing food;

  const FoodGetResultSingleServing(
      this.food,
      );

  factory FoodGetResultSingleServing.fromJson(Map<String, dynamic> json) => _$FoodGetResultSingleServingFromJson(json);

  Map<String, dynamic> toJson() => _$FoodGetResultSingleServingToJson(this);

  @override
  List<Object?> get props => [
    food
  ];

}