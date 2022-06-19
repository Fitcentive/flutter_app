// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['access_token', 'refresh_token'],
  );
  return AuthTokens(
    json['access_token'] as String,
    json['refresh_token'] as String,
    json['expires_in'] as int,
    json['refresh_expires_in'] as int,
    json['token_type'] as String,
    json['session_state'] as String,
    json['scope'] as String,
  );
}

Map<String, dynamic> _$AuthTokensToJson(AuthTokens instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'refresh_expires_in': instance.refreshExpiresIn,
      'token_type': instance.tokenType,
      'session_state': instance.sessionState,
      'scope': instance.scope,
    };
