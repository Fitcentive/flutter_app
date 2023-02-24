import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'muscle.g.dart';

@JsonSerializable()
class Muscle extends Equatable {
  final int id;
  final String name;
  final String name_en;
  final bool is_front;
  final String image_url_main;
  final String image_url_secondary;


  const Muscle(
      this.id,
      this.name,
      this.name_en,
      this.is_front,
      this.image_url_main,
      this.image_url_secondary
  );

  factory Muscle.fromJson(Map<String, dynamic> json) => _$MuscleFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    name_en,
    is_front,
    image_url_main,
    image_url_secondary
  ];
}