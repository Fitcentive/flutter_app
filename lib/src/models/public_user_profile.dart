import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_user_profile.g.dart';

@JsonSerializable()
class PublicUserProfile extends Equatable {
  @JsonKey(required: true)
  final String userId;

  final String? username;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final int? locationRadius;
  final Coordinates? locationCenter;
  final String? gender;

  const PublicUserProfile(
      this.userId,
      this.username,
      this.firstName,
      this.lastName,
      this.photoUrl,
      this.locationRadius,
      this.locationCenter,
      this.gender
      );

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) => _$PublicUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PublicUserProfileToJson(this);

  @override
  List<Object?> get props => [
    userId,
    username,
    firstName,
    lastName,
    photoUrl,
    locationCenter,
    locationRadius,
    gender,
  ];
}