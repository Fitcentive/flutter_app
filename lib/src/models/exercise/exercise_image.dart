import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise_image.g.dart';

@JsonSerializable()
class ExerciseImage extends Equatable {
  final int id;
  final String uuid;
  final int exercise_base;
  final String image;
  final bool is_main;

  const ExerciseImage(
      this.id,
      this.uuid,
      this.exercise_base,
      this.image,
      this.is_main
  );

  factory ExerciseImage.fromJson(Map<String, dynamic> json) => _$ExerciseImageFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseImageToJson(this);

  @override
  List<Object?> get props => [
    id,
    uuid,
    exercise_base,
    image,
    is_main
  ];
}