// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Muscle _$MuscleFromJson(Map<String, dynamic> json) => Muscle(
      json['id'] as int,
      json['name'] as String,
      json['name_en'] as String,
      json['is_front'] as bool,
      json['image_url_main'] as String,
      json['image_url_secondary'] as String,
    );

Map<String, dynamic> _$MuscleToJson(Muscle instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'name_en': instance.name_en,
      'is_front': instance.is_front,
      'image_url_main': instance.image_url_main,
      'image_url_secondary': instance.image_url_secondary,
    };
