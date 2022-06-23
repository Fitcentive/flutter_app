import 'package:flutter_app/src/models/auth/auth_tokens.dart';

class SecureAuthTokens {
  static const String REFRESH_TOKEN_SECURE_STORAGE_KEY = "refresh_token";
  static const String ACCESS_TOKEN_SECURE_STORAGE_KEY = "access_token";

  final int expiresIn;
  final int refreshExpiresIn;
  final String tokenType;
  final String scope;
  final String accessTokenSecureStorageKey;
  final String refreshTokenSecureStorageKey;

  SecureAuthTokens({required this.expiresIn,
    required this.refreshExpiresIn,
    required this.tokenType,
    required this.scope,
    required this.accessTokenSecureStorageKey,
    required this.refreshTokenSecureStorageKey});

  factory SecureAuthTokens.fromAuthTokens(AuthTokens raw) =>
      SecureAuthTokens(expiresIn: raw.expiresIn,
          refreshExpiresIn: raw.refreshExpiresIn,
          tokenType: raw.tokenType,
          scope: raw.scope,
          accessTokenSecureStorageKey: ACCESS_TOKEN_SECURE_STORAGE_KEY,
          refreshTokenSecureStorageKey: REFRESH_TOKEN_SECURE_STORAGE_KEY
      );
}
