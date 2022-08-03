import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_discovery_preferences.g.dart';

@JsonSerializable()
class UserDiscoveryPreferences extends Equatable {
  final String userId;
  final String preferredTransportMode;
  final Coordinates locationCenter;
  final int locationRadius;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDiscoveryPreferences(
      this.userId,
      this.preferredTransportMode,
      this.locationCenter,
      this.locationRadius,
      this.createdAt,
      this.updatedAt
  );

  factory UserDiscoveryPreferences.fromJson(Map<String, dynamic> json) => _$UserDiscoveryPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserDiscoveryPreferencesToJson(this);

  @override
  List<Object?> get props => [
    userId,
    preferredTransportMode,
    locationCenter,
    locationRadius,
    createdAt,
    updatedAt,
  ];
}

class UserDiscoveryPreferencesPost extends Equatable {
  final String userId;
  final String preferredTransportMode;
  final Coordinates locationCenter;
  final int locationRadius;

  const UserDiscoveryPreferencesPost({
    required this.userId,
    required this.preferredTransportMode,
    required this.locationCenter,
    required this.locationRadius
  });

  @override
  List<Object?> get props => [
    userId,
    preferredTransportMode,
    locationCenter,
    locationRadius,
  ];

}

