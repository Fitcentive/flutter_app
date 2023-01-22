import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_gym_preferences.g.dart';

@JsonSerializable()
class UserGymPreferences extends Equatable {
  final String userId;
  final String? gymLocationId;
  final String? fsqId;
  final String? gymName;
  final String? gymWebsite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGymPreferences(
      this.userId,
      this.gymLocationId,
      this.fsqId,
      this.gymName,
      this.gymWebsite,
      this.createdAt,
      this.updatedAt
  );

  factory UserGymPreferences.fromJson(Map<String, dynamic> json) => _$UserGymPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserGymPreferencesToJson(this);

  @override
  List<Object?> get props => [
    userId,
    gymLocationId,
    fsqId,
    gymName,
    gymWebsite,
    createdAt,
    updatedAt,
  ];
}

class UserGymPreferencesPost extends Equatable {
  final String userId;
  final String? gymLocationId;
  final String? fsqId;
  final String? gymName;
  final String? gymWebsite;

  const UserGymPreferencesPost(
      this.userId,
      this.gymLocationId,
      this.fsqId,
      this.gymName,
      this.gymWebsite,
      );

  @override
  List<Object?> get props => [
    userId,
    gymLocationId,
    fsqId,
    gymName,
    gymWebsite,
  ];
}