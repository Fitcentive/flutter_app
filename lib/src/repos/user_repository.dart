import 'dart:async';
import 'dart:convert';

import '../models/user.dart';

import 'package:http/http.dart' as http;

class UserRepository {

  static final String BASE_URL = "http://api.vid.app/api/user";

  Future<User> createNewUser(String email, String verificationToken) async {

    final encodedBody = json.encode({
      "email": email,
      "verificationToken": verificationToken,
    });

    final response = await http.post(
        Uri.parse("$BASE_URL"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: encodedBody
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    else {
      print(response.statusCode);
      print(response.body);
      throw Exception("Bad response from new user creation API");
    }
  }

  Future<bool> verifyEmailVerificationToken(String email, String token) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/password-reset/validate-token"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({
          "email": email,
          "token": token,
        })
    );

    if (response.statusCode == 204) {
      return true;
    }
    else if (response.statusCode == 401) {
      return false;
    }
    else {
      throw Exception("Bad response from new email verification API");
    }
  }

  Future<void> requestNewEmailVerificationToken(String email) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/verify-email"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({
          "email": email
        })
    );

    if (response.statusCode == 202) {
      return;
    }
    else {
      throw Exception("Bad response from new email verification API");
    }
  }

  Future<void> resetUserPassword(String email, String password, String verificationToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/password-reset"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({
          "email": email,
          "newPassword": password,
          "emailVerificationToken": verificationToken,
        })
    );

    if (response.statusCode == 202) {
      return;
    }
    else {
      print(response.statusCode);
      print(response.body);
      throw Exception("Bad response from new reset password API");
    }
  }


  Future<User?> getUser(String userId, String accessToken) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/$userId"),
        headers: {
          "Authorization": "Bearer $accessToken"
        }
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    }
    else {
      return null;
    }
  }
}
