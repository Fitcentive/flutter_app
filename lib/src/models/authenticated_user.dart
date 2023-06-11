import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/models/user_agreements.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/models/user_tutorial_status.dart';

class AuthenticatedUser extends Equatable {
  final User user;
  final UserProfile? userProfile;
  final UserAgreements? userAgreements;
  final UserTutorialStatus? userTutorialStatus;
  final String authProvider;
  final SecureAuthTokens authTokens;

  const AuthenticatedUser({
    required this.user,
    this.userProfile,
    this.userAgreements,
    this.userTutorialStatus,
    required this.authTokens,
    required this.authProvider
  });

  @override
  List<Object?> get props => [
    user,
    userProfile,
    userAgreements,
    userTutorialStatus,
    authTokens,
    authProvider
  ];
}