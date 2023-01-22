import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_category.g.dart';

@JsonSerializable()
class FourSquareCategory extends Equatable {
  final int id;
  final String name;
  final String iconUrl;

  const FourSquareCategory(this.id, this.name, this.iconUrl);

  factory FourSquareCategory.fromJson(Map<String, dynamic> json) => _$FourSquareCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquareCategoryToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    iconUrl,
  ];
}