import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'language.g.dart';

@JsonSerializable()
class Language extends Equatable {
  final int id;
  final String short_name;
  final String full_name;


  const Language(
      this.id,
      this.short_name,
      this.full_name,
      );

  factory Language.fromJson(Map<String, dynamic> json) => _$LanguageFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageToJson(this);

  @override
  List<Object?> get props => [
    id,
    short_name,
    full_name,
  ];
}