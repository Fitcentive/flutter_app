import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String email;

  final String? username;
  final String accountStatus;
  final String authProvider;
  final bool enabled;
  final bool isPremiumEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  const User(
      this.id,
      this.email,
      this.username,
      this.accountStatus,
      this.authProvider,
      this.enabled,
      this.isPremiumEnabled,
      this.createdAt,
      this.updatedAt
  );

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        accountStatus,
        authProvider,
        enabled,
        isPremiumEnabled,
        createdAt,
        updatedAt,
      ];
}

class UpdateUserPatch extends Equatable {
  final String? username;
  final String? accountStatus;
  final bool? enabled;

  const UpdateUserPatch({this.username, this.accountStatus, this.enabled});

  @override
  List<Object?> get props => [
    username,
    accountStatus,
    enabled,
  ];
}

class UpdateUserPost extends Equatable {
  final String? username;
  final String accountStatus;
  final bool enabled;

  const UpdateUserPost({this.username, required this.accountStatus, required this.enabled});

  @override
  List<Object?> get props => [
    username,
    accountStatus,
    enabled,
  ];
}