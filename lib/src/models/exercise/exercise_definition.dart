import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/exercise/equipment.dart';
import 'package:flutter_app/src/models/exercise/exercise_category.dart';
import 'package:flutter_app/src/models/exercise/exercise_image.dart';
import 'package:flutter_app/src/models/exercise/language.dart';
import 'package:flutter_app/src/models/exercise/muscle.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise_definition.g.dart';

@JsonSerializable()
class ExerciseDefinition extends Equatable {
  final int id;
  final String name;
  final String uuid;
  final String description;
  final ExerciseCategory category;
  final List<Muscle> muscles;
  final List<Muscle> muscles_secondary;
  final List<Equipment> equipment;
  final Language language;
  final List<ExerciseImage> images;


  const ExerciseDefinition(
      this.id,
      this.name,
      this.uuid,
      this.description,
      this.category,
      this.muscles,
      this.muscles_secondary,
      this.equipment,
      this.language,
      this.images
  );

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) => _$ExerciseDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseDefinitionToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    uuid,
    description,
    category,
    muscles,
    muscles_secondary,
    equipment,
    language,
    images
  ];
}