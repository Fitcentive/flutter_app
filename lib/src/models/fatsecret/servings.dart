import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:json_annotation/json_annotation.dart';

part 'servings.g.dart';

@JsonSerializable()
class Servings extends Equatable {
 final List<Serving> serving;

 const Servings(this.serving);

 factory Servings.fromJson(Map<String, dynamic> json) => _$ServingsFromJson(json);

 Map<String, dynamic> toJson() => _$ServingsToJson(this);

 @override
 List<Object?> get props => [
   serving
 ];

}