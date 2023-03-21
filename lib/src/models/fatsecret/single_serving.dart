import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_serving.g.dart';

@JsonSerializable()
class SingleServing extends Equatable {
  final Serving serving;

  const SingleServing(this.serving);

  factory SingleServing.fromJson(Map<String, dynamic> json) => _$SingleServingFromJson(json);

  Map<String, dynamic> toJson() => _$SingleServingToJson(this);

  @override
  List<Object?> get props => [
    serving
  ];

}