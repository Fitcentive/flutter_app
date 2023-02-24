// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseDefinition _$ExerciseDefinitionFromJson(Map<String, dynamic> json) =>
    ExerciseDefinition(
      json['id'] as int,
      json['name'] as String,
      json['uuid'] as String,
      json['description'] as String,
      ExerciseCategory.fromJson(json['category'] as Map<String, dynamic>),
      (json['muscles'] as List<dynamic>)
          .map((e) => Muscle.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['muscles_secondary'] as List<dynamic>)
          .map((e) => Muscle.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['equipment'] as List<dynamic>)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
          .toList(),
      Language.fromJson(json['language'] as Map<String, dynamic>),
      (json['images'] as List<dynamic>)
          .map((e) => ExerciseImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExerciseDefinitionToJson(ExerciseDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'uuid': instance.uuid,
      'description': instance.description,
      'category': instance.category,
      'muscles': instance.muscles,
      'muscles_secondary': instance.muscles_secondary,
      'equipment': instance.equipment,
      'language': instance.language,
      'images': instance.images,
    };
