import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile extends Equatable {
  @JsonKey(required: true)
  final String userId;

  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? dateOfBirth;
  final int? locationRadius;
  final Coordinates? locationCenter;

  const UserProfile(
      this.userId,
      this.firstName,
      this.lastName,
      this.photoUrl,
      this.dateOfBirth,
      this.locationRadius,
      this.locationCenter
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  List<Object?> get props => [
    userId,
    firstName,
    lastName,
    photoUrl,
    dateOfBirth,
    locationRadius,
    locationCenter,
  ];
}

class UpdateUserProfile extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? dateOfBirth;
  final int? locationRadius;
  final Coordinates? locationCenter;

  const UpdateUserProfile({
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.dateOfBirth,
    this.locationRadius,
    this.locationCenter
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    photoUrl,
    dateOfBirth,
    locationRadius,
    locationCenter
  ];
}