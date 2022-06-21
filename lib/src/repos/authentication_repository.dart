import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/auth/auth_tokens.dart';
import 'package:http/http.dart' as http;

class AuthenticationRepository {
  static const String BASE_URL = "http://api.vid.app/api/auth";

  Future<void> logout({required String accessToken, required String refreshToken}) async {
    var uri = Uri.parse("${BASE_URL}/logout");

    var request = http.MultipartRequest('POST', uri)
    ..headers["Authorization"] = "Bearer $accessToken"
    ..fields['client_id'] = 'webapp'
    ..fields['refresh_token'] = refreshToken;

    final response = await request.send();

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "logIn: Received bad response with status: ${response.statusCode}");
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

    if (response.statusCode == HttpStatus.ok) {
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      final parsedTokenResponse = AuthTokens.fromJson(responseMap);
      return parsedTokenResponse;
    } else {
      throw Exception(
          "logIn: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

}
