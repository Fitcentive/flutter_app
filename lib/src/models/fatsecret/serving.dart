import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'serving.g.dart';

@JsonSerializable()
class Serving extends Equatable {
  final String? calcium;
  final String? calories;
  final String? carbohydrate;
  final String? cholesterol;
  final String? fat;
  final String? fiber;
  final String? iron;
  final String? measurement_description;
  final String? metric_serving_amount;
  final String? metric_serving_unit;
  final String? monounsaturated_fat;
  final String? number_of_units;
  final String? polyunsaturated_fat;
  final String? potassium;
  final String? protein;
  final String? saturated_fat;
  final String? serving_description;
  final String? serving_id;
  final String? serving_url;
  final String? sodium;
  final String? sugar;


  const Serving(
      this.calcium,
      this.calories,
      this.carbohydrate,
      this.cholesterol,
      this.fat,
      this.fiber,
      this.iron,
      this.measurement_description,
      this.metric_serving_amount,
      this.metric_serving_unit,
      this.monounsaturated_fat,
      this.number_of_units,
      this.polyunsaturated_fat,
      this.potassium,
      this.protein,
      this.saturated_fat,
      this.serving_description,
      this.serving_id,
      this.serving_url,
      this.sodium,
      this.sugar
  );

  factory Serving.fromJson(Map<String, dynamic> json) => _$ServingFromJson(json);

  Map<String, dynamic> toJson() => _$ServingToJson(this);

  @override
  List<Object?> get props => [
    calcium,
    calories,
    carbohydrate,
    cholesterol,
    fat,
    fiber,
    iron,
    measurement_description,
    metric_serving_amount,
    metric_serving_unit,
    monounsaturated_fat,
    number_of_units,
    polyunsaturated_fat,
    potassium,
    protein,
    saturated_fat,
    serving_description,
    serving_id,
    serving_url,
    sodium,
    sugar,
  ];
}