import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_agreements.dart';
import 'package:flutter_app/src/models/user_profile.dart';

import '../../models/user.dart';

import 'package:http/http.dart' as http;

class UserRepository {
  static const String BASE_URL = "http://api.vid.app/api/user";

  Future<List<PublicUserProfile>> searchForUsers(String searchQuery, int limit, String accessToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/public/search?limit=$limit"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: json.encode({
          "query": searchQuery
        }));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final publicUserProfiles = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return publicUserProfiles;
    } else {
      throw Exception(
          "searchForUsers: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

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

    if (response.statusCode == HttpStatus.created) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          "createNewUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserAgreements> updateUserAgreements(
      String userId, UpdateUserAgreements userAgreements, String accessToken) async {
    final jsonBody = {
      'termsAndConditionsAccepted': userAgreements.termsAndConditionsAccepted,
      'subscribeToEmails': userAgreements.subscribeToEmails,
    };
    final response = await http.patch(Uri.parse("$BASE_URL/$userId/agreements"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userAgreements = UserAgreements.fromJson(jsonResponse);
      return userAgreements;
    } else {
      throw Exception(
          "updateUserAgreements: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<bool> checkIfUsernameExists(String username, String accessToken) async {
    final response = await http
        .head(Uri.parse("$BASE_URL/username?username=$username"), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else if (response.statusCode == HttpStatus.notFound) {
      return false;
    } else {
      throw Exception(
          "checkIfUsernameExists: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserAgreements?> getUserAgreements(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/$userId/agreements"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userAgreements = UserAgreements.fromJson(jsonResponse);
      return userAgreements;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "updateUserAgreements: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserProfile?> getUserProfile(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/$userId/profile"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userProfile = UserProfile.fromJson(jsonResponse);
      return userProfile;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "getUserProfile: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<UserProfile>> getUserProfiles(List<String> userIds, String accessToken) async {
    if (userIds.isEmpty) {
      return List.empty();
    }

    final response = await http.post(Uri.parse("$BASE_URL/profile/get-by-ids"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({"userIds": userIds}));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final userProfiles = jsonResponse.map((e) => UserProfile.fromJson(e)).toList();
      return userProfiles;
    } else {
      throw Exception(
          "getUserProfiles: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<PublicUserProfile>> getPublicUserProfiles(List<String> userIds, String accessToken) async {
    if (userIds.isEmpty) {
      return List.empty();
    }

    final response = await http.post(Uri.parse("$BASE_URL/public/profile/get-by-ids"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({"userIds": userIds}));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final userProfiles = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return userProfiles;
    } else {
      throw Exception(
          "getUserProfiles: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserProfile> createOrUpdateUserProfile(
      String userId, UpdateUserProfile userProfile, String accessToken) async {
    final jsonBody = {
      'firstName': userProfile.firstName,
      'lastName': userProfile.lastName,
      'photoUrl': userProfile.photoUrl,
      'dateOfBirth': userProfile.dateOfBirth,
      'gender': userProfile.gender,
      'locationRadius': userProfile.locationRadius,
      'locationCenter': userProfile.locationCenter == null ? null : userProfile.locationCenter!.toJson()
    };
    final response = await http.patch(Uri.parse("$BASE_URL/$userId/profile"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userProfile = UserProfile.fromJson(jsonResponse);
      return userProfile;
    } else {
      throw Exception(
          "createOrUpdateUserProfile: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserProfile> updateUserProfilePost(String userId, UpdateUserProfile userProfile, String accessToken) async {
    final jsonBody = {
      'firstName': userProfile.firstName,
      'lastName': userProfile.lastName,
      'photoUrl': userProfile.photoUrl,
      'dateOfBirth': userProfile.dateOfBirth,
      'gender': userProfile.gender,
      'locationRadius': userProfile.locationRadius,
      'locationCenter': userProfile.locationCenter == null ? null : userProfile.locationCenter!.toJson()
    };
    final response = await http.post(Uri.parse("$BASE_URL/$userId/profile"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userProfile = UserProfile.fromJson(jsonResponse);
      return userProfile;
    } else {
      throw Exception(
          "updateUserProfilePost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<User> updateUserPatch(String userId, UpdateUserPatch user, String accessToken) async {
    final jsonBody = {
      'username': user.username,
      'accountStatus': user.accountStatus,
      'enabled': user.enabled,
    };
    final response = await http.patch(Uri.parse("$BASE_URL/$userId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } else {
      throw Exception(
          "updateUserPatch: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<User> updateUserPost(String userId, UpdateUserPost user, String accessToken) async {
    final jsonBody = {
      'username': user.username,
      'accountStatus': user.accountStatus,
      'enabled': user.enabled,
    };
    final response = await http.post(Uri.parse("$BASE_URL/$userId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } else {
      throw Exception(
          "updateUserPost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<bool> verifyEmailVerificationToken(String email, String token) async {
    final response = await http.post(Uri.parse("$BASE_URL/password/validate-token"),
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

  Future<bool> requestPasswordResetVerificationToken(String email) async {
    final response = await http.post(Uri.parse("$BASE_URL/password/reset-request"),
        headers: {
          'Content-type': 'application/json',
        },
        body: json.encode({"email": email}));

    if (response.statusCode == HttpStatus.accepted) {
      return true;
    } else if (response.statusCode == HttpStatus.notFound) {
      return false;
    } else if (response.statusCode == HttpStatus.badRequest) {
      return false;
    } else {
      throw Exception(
          "requestPasswordResetVerificationToken: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> requestNewEmailVerificationToken(String email) async {
    final response = await http.post(Uri.parse("$BASE_URL/email/verify"),
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
    final response = await http.post(Uri.parse("$BASE_URL/password/reset"),
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

  Future<String?> getUserUsername(String userId, String accessToken) async {
    final response =
        await http.get(Uri.parse("$BASE_URL/$userId/username"), headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final String username = jsonResponse;
      return username;
    } else {
      return null;
    }
  }
}
