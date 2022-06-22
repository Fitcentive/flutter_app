import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/user.dart';

import 'package:http/http.dart' as http;

class UserRepository {
  static const String BASE_URL = "http://api.vid.app/api/user";

  Future<User> createNewUser(
      String email, String verificationToken, bool termsAndConditions, bool subscribeToEmails) async {
    final response = await http.post(Uri.parse("$BASE_URL"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "email": email,
          "verificationToken": verificationToken,
          "termsAndConditionsAccepted": termsAndConditions,
          "subscribeToEmails": subscribeToEmails,
        }));

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          "createNewUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<bool> verifyEmailVerificationToken(String email, String token) async {
    final response = await http.post(Uri.parse("$BASE_URL/password-reset/validate-token"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({
          "email": email,
          "token": token,
        }));

    if (response.statusCode == HttpStatus.noContent) {
      return true;
    } else if (response.statusCode == HttpStatus.unauthorized) {
      return false;
    } else {
      throw Exception(
          "verifyEmailVerificationToken: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<bool> checkIfUserExistsForEmail(String email) async {
    final response = await http.head(Uri.parse("$BASE_URL/email?email=$email"));
    if (response.statusCode == HttpStatus.notFound) {
      return false;
    } else if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception(
          "checkIfUserExistsForEmail: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> requestNewEmailVerificationToken(String email) async {
    final response = await http.post(Uri.parse("$BASE_URL/verify-email"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({"email": email}));

    if (response.statusCode == HttpStatus.accepted) {
      return;
    } else {
      throw Exception(
          "requestNewEmailVerificationToken: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> resetUserPassword(String email, String password, String verificationToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/password-reset"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({
          "email": email,
          "newPassword": password,
          "emailVerificationToken": verificationToken,
        }));

    if (response.statusCode == HttpStatus.accepted) {
      return;
    } else {
      throw Exception(
          "resetUserPassword: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<User?> getUser(String userId, String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/$userId"), headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } else {
      return null;
    }
  }
}
