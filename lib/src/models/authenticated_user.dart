import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/user.dart';

class AuthenticatedUser {
  final User user;
  final String authProvider;
  final SecureAuthTokens authTokens;

  AuthenticatedUser(this.user, this.authTokens, this.authProvider);
}