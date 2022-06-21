import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:flutter_app/src/utils/jwt_utils.dart';
import 'package:http/http.dart' as http;

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository {
  static final String BASE_URL = "http://api.vid.app/api/auth";

  // todo - do analysis of reactive repository vs classical approach.

  Future<void> logout({required String accessToken, required String refreshToken}) async {
    var uri = Uri.parse("${BASE_URL}/logout");

    var request = http.MultipartRequest('POST', uri)
    ..headers["Authorization"] = "Bearer $accessToken"
    ..fields['client_id'] = 'webapp'
    ..fields['refresh_token'] = refreshToken;

    final response = await request.send();

    if (response.statusCode >= 200 && response.statusCode < 400) {
      return;
    }
    else {
      throw Exception('Failed to get user details');
    }

  }

  Future<AuthTokens> logIn({
    required String username,
    required String password,
  }) async {
    String url = "${BASE_URL}/login/basic";

    final response = await http.post(
        Uri.parse(url),
        body: {
          "username": username,
          "password": password,
          "client_id": "webapp",
          "grant_type": "password",
        }
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      final parsedTokenResponse = AuthTokens.fromJson(responseMap);
      return parsedTokenResponse;
    } else {
      throw Exception('Failed to get user details');
    }
  }

}
