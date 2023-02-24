import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable()
class Equipment extends Equatable {
  final int id;
  final String name;


  const Equipment(
      this.id,
      this.name,
      );

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
  ];
}