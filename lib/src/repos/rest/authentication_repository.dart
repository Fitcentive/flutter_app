import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/models/auth/oidc_provider_info.dart';
import 'package:flutter_app/src/utils/datetime_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:logging/logging.dart';

class AuthenticationRepository {
  static const String BASE_URL = "https://api.vid.app/api/auth";

  static final Map<String, OidcProviderInfo> providerToDetailsMap = {
    OidcProviderInfo.GOOGLE_AUTH_PROVIDER: OidcProviderInfo.googleOidcProviderInfo()
  };

  final logger = Logger('AuthenticationRepository');
  final FlutterAppAuth appAuth = const FlutterAppAuth();

  Future<void> createNewSsoUser(String authRealm, String accessToken) async {
    final response = await http
        .post(Uri.parse("$BASE_URL/realm/$authRealm/user"), headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == HttpStatus.created) {
      return;
    } else {
      throw Exception(
          "createNewSsoUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> logout({required String accessToken, required String refreshToken, required String authRealm}) async {
    var uri = Uri.parse("$BASE_URL/logout/$authRealm");
    var request = http.MultipartRequest('POST', uri)
      ..headers["Authorization"] = "Bearer $accessToken"
      ..fields['client_id'] = 'mobileapp'
      ..fields['refresh_token'] = refreshToken;

    final response = await request.send();

    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      logger.warning("logIn: Received bad response with status: ${response.statusCode}");
      return;
    }
  }

  Future<AuthTokens> oidcLogin({
    required String providerRealm,
  }) async {
    final oidcProviderInfo = providerToDetailsMap[providerRealm];

    final AuthorizationResponse? authorizationResponse = await appAuth.authorize(AuthorizationRequest(
        oidcProviderInfo!.clientId, oidcProviderInfo.redirectUri,
        serviceConfiguration: oidcProviderInfo.serviceConfiguration,
        discoveryUrl: oidcProviderInfo.discoverUri,
        scopes: ['openid', 'profile', 'email'],
        promptValues: ["login"],
        additionalParameters: {
          "kc_idp_hint": oidcProviderInfo.keycloakIdpHint,
        }));

    final TokenResponse? result = await appAuth.token(TokenRequest(
        oidcProviderInfo.clientId, oidcProviderInfo.redirectUri,
        authorizationCode: authorizationResponse!.authorizationCode,
        serviceConfiguration: oidcProviderInfo.serviceConfiguration,
        codeVerifier: authorizationResponse.codeVerifier,
        nonce: authorizationResponse.nonce,
        scopes: ['openid', 'profile', 'email']));

    return AuthTokens(
        result!.accessToken!,
        result.refreshToken!,
        DateTimeUtils.secondsBetweenNowAndEpochTime(result.accessTokenExpirationDateTime!.millisecondsSinceEpoch),
        // todo - this has to be replaced with refresh token expiry time
        DateTimeUtils.secondsBetweenNowAndEpochTime(result.accessTokenExpirationDateTime!.millisecondsSinceEpoch),
        result.tokenType!,
        result.scopes!.join(" "));
  }

  Future<AuthTokens> basicLogIn({
    required String username,
    required String password,
  }) async {
    final clientId = DeviceUtils.isMobileDevice() ? "mobileapp" : "webapp";
    final response = await http.post(Uri.parse("${BASE_URL}/login/basic"), body: {
      "username": username,
      "password": password,
      "client_id": clientId,
      "grant_type": "password",
    });

    if (response.statusCode == HttpStatus.ok) {
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      final parsedTokenResponse = AuthTokens.fromJson(responseMap);
      return parsedTokenResponse;
    } else {
      throw Exception("logIn: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<AuthTokens> refreshAccessToken({
    required String accessToken,
    required String refreshToken,
    required String providerRealm,
  }) async =>
      _refreshAccessTokenHelper(
          refreshTokenEndpoint: "$BASE_URL/refresh",
          accessToken: accessToken,
          refreshToken: refreshToken,
          providerRealm: providerRealm
      );

  Future<AuthTokens> refreshNewSsoUserAccessToken({
    required String accessToken,
    required String refreshToken,
    required String providerRealm,
  }) async =>
      _refreshAccessTokenHelper(
          refreshTokenEndpoint: "$BASE_URL/sso/refresh",
          accessToken: accessToken,
          refreshToken: refreshToken,
          providerRealm: providerRealm
      );

  Future<AuthTokens> _refreshAccessTokenHelper({
    required String refreshTokenEndpoint,
    required String accessToken,
    required String refreshToken,
    required String providerRealm,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(refreshTokenEndpoint))
      ..headers["Authorization"] = "Bearer $accessToken"
      ..fields['client_id'] = 'mobileapp'
      ..fields['refresh_token'] = refreshToken
      ..fields['realm'] = providerRealm;

    final streamedResponse = await request.send();
    final response = await Response.fromStream(streamedResponse);

    if (response.statusCode == HttpStatus.ok) {
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      final parsedTokenResponse = AuthTokens.fromJson(responseMap);
      return parsedTokenResponse;
    } else {
      throw Exception(
          "$refreshTokenEndpoint: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}
