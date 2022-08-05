import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'matched_attributes.g.dart';

@JsonSerializable()
class MatchedAttributes extends Equatable {
  final List<String>? activities;
  final List<String>? fitnessGoals;
  final List<String>? bodyTypes;
  final List<String>? genders;
  final List<String>? preferredDays;

  const MatchedAttributes(
      this.activities,
      this.fitnessGoals,
      this.bodyTypes,
      this.genders,
      this.preferredDays
  );

  factory MatchedAttributes.fromJson(Map<String, dynamic> json) => _$MatchedAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$MatchedAttributesToJson(this);

  @override
  List<Object?> get props => [
    activities,
    fitnessGoals,
    bodyTypes,
    genders,
    preferredDays,
  ];
}