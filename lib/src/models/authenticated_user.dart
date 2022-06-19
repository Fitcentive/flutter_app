import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/user.dart';

class AuthenticatedUser {
  final User user;
  final AuthTokens authTokens;

  AuthenticatedUser(this.user, this.authTokens);
}