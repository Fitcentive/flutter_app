import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise_category.g.dart';

@JsonSerializable()
class ExerciseCategory extends Equatable {
  final int id;
  final String name;


  const ExerciseCategory(
      this.id,
      this.name,
      );

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) => _$ExerciseCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseCategoryToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
  ];
}