import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_all_preferences.g.dart';

@JsonSerializable()
class UserAllPreferences extends Equatable {

  final UserDiscoveryPreferences? userDiscoveryPreferences;
  final UserGymPreferences? userGymPreferences;
  final UserFitnessPreferences? userFitnessPreferences;
  final UserPersonalPreferences? userPersonalPreferences;


  const UserAllPreferences(
      this.userDiscoveryPreferences,
      this.userGymPreferences,
      this.userFitnessPreferences,
      this.userPersonalPreferences
  );

  factory UserAllPreferences.fromJson(Map<String, dynamic> json) => _$UserAllPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserAllPreferencesToJson(this);

  @override
  List<Object?> get props => [
    userDiscoveryPreferences,
    userGymPreferences,
    userFitnessPreferences,
    userPersonalPreferences,
  ];


}