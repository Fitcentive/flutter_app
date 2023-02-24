// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseImage _$ExerciseImageFromJson(Map<String, dynamic> json) =>
    ExerciseImage(
      json['id'] as int,
      json['uuid'] as String,
      json['exercise_base'] as int,
      json['image'] as String,
      json['is_main'] as bool,
    );

Map<String, dynamic> _$ExerciseImageToJson(ExerciseImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'exercise_base': instance.exercise_base,
      'image': instance.image,
      'is_main': instance.is_main,
    };
