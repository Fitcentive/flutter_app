import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_get_result.g.dart';

@JsonSerializable()
class FoodGetResult extends Equatable {
  final FoodResult food;

  const FoodGetResult(
      this.food,
      );

  factory FoodGetResult.fromJson(Map<String, dynamic> json) => _$FoodGetResultFromJson(json);

  Map<String, dynamic> toJson() => _$FoodGetResultToJson(this);

  @override
  List<Object?> get props => [
    food
  ];

}