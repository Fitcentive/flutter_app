import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/servings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_result.g.dart';

@JsonSerializable()
class FoodResult extends Equatable {
  final String food_id;
  final String food_name;
  final String food_type;
  final String food_url;
  final Servings servings;

  const FoodResult(
      this.food_id,
      this.food_name,
      this.food_type,
      this.food_url,
      this.servings
  );

  factory FoodResult.fromJson(Map<String, dynamic> json) => _$FoodResultFromJson(json);

  Map<String, dynamic> toJson() => _$FoodResultToJson(this);

  @override
  List<Object?> get props => [
    servings
  ];

}