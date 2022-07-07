import 'package:equatable/equatable.dart';
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

  const PublicUserProfile(this.userId, this.username, this.firstName, this.lastName, this.photoUrl);

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) => _$PublicUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PublicUserProfileToJson(this);

  @override
  List<Object?> get props => [
    userId,
    username,
    firstName,
    lastName,
    photoUrl,
  ];
}