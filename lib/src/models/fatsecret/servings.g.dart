// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Servings _$ServingsFromJson(Map<String, dynamic> json) => Servings(
      (json['serving'] as List<dynamic>)
          .map((e) => Serving.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServingsToJson(Servings instance) => <String, dynamic>{
      'serving': instance.serving,
    };
