import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/discover/discover_recommendation.dart';
import 'package:flutter_app/src/models/discover/user_all_preferences.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_gym_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;

class DiscoverRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/discover";

  Future<void> removeDiscoveredUser(String userId, String discoveredUserId, String accessToken) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/user/$userId/discovered-users/$discoveredUserId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "removeDiscoveredUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> upsertDiscoveredUser(String userId, String discoveredUserId, String accessToken) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/user/$userId/discovered-users/$discoveredUserId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "upsertDiscoveredUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }


  Future<List<PublicUserProfile>> getDiscoveredUserProfiles(String userId, String accessToken, int limit, int offset) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/discovered-users?limit=$limit&offset=$offset"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final userProfiles = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return userProfiles;
    } else {
      throw Exception(
          "getDiscoveredUserProfiles: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DiscoverRecommendation>> getUserDiscoverRecommendations(
      String userId,
      int? discoverLimit,
      String accessToken
  ) async {
    final response = await http.get(
        discoverLimit == null ?
          Uri.parse("$BASE_URL/user/$userId/recommendations") :
          Uri.parse("$BASE_URL/user/$userId/recommendations?discoverLimit=$discoverLimit"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final recommendations = jsonResponse.map((e) => DiscoverRecommendation.fromJson(e)).toList();
      return recommendations;
    } else {
      throw Exception(
          "getUserDiscoverRecommendations: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserAllPreferences> getAllUserPreferences(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/preferences"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userAllPrefs = UserAllPreferences.fromJson(jsonResponse);
      return userAllPrefs;
    } else {
      throw Exception(
          "getAllUserPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserDiscoveryPreferences?> getUserDiscoveryPreferences(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/preferences/discovery"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userDiscoveryPreferences = UserDiscoveryPreferences.fromJson(jsonResponse);
      return userDiscoveryPreferences;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "getUserDiscoveryPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserDiscoveryPreferences> upsertUserDiscoveryPreferences(String userId, UserDiscoveryPreferencesPost prefs, String accessToken) async {
    final jsonBody = {
      'userId': prefs.userId,
      'preferredTransportMode': prefs.preferredTransportMode,
      'locationRadius': prefs.locationRadius,
      'locationCenter': prefs.locationCenter.toJson()
    };
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/preferences/discovery"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody)
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final prefs = UserDiscoveryPreferences.fromJson(jsonResponse);
      return prefs;
    } else {
      throw Exception(
          "upsertUserDiscoveryPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserFitnessPreferences?> getUserFitnessPreferences(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/preferences/fitness"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userFitnessPreferences = UserFitnessPreferences.fromJson(jsonResponse);
      return userFitnessPreferences;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "getUserFitnessPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserFitnessPreferences> upsertUserFitnessPreferences(String userId, UserFitnessPreferencesPost prefs, String accessToken) async {
    final jsonBody = {
      'userId': prefs.userId,
      'activitiesInterestedIn': prefs.activitiesInterestedIn,
      'fitnessGoals': prefs.fitnessGoals,
      'desiredBodyTypes': prefs.desiredBodyTypes
    };
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/preferences/fitness"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody)
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final prefs = UserFitnessPreferences.fromJson(jsonResponse);
      return prefs;
    } else {
      throw Exception(
          "upsertUserFitnessPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserPersonalPreferences?> getUserPersonalPreferences(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/preferences/personal"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userPersonalPreferences = UserPersonalPreferences.fromJson(jsonResponse);
      return userPersonalPreferences;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "getUserPersonalPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<num> getUserDiscoverScore(String currentUserId, String otherUserId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$currentUserId/discover-score/$otherUserId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final discoverScore = jsonResponse as num;
      return discoverScore;
    }
    else {
      throw Exception(
          "getUserDiscoverScore: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserPersonalPreferences> upsertUserPersonalPreferences(String userId, UserPersonalPreferencesPost prefs, String accessToken) async {
    final jsonBody = {
      'userId': prefs.userId,
      'gendersInterestedIn': prefs.gendersInterestedIn,
      'preferredDays': prefs.preferredDays,
      'minimumAge': prefs.minimumAge,
      'maximumAge': prefs.maximumAge,
      'hoursPerWeek': prefs.hoursPerWeek,
    };
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/preferences/personal"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody)
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final prefs = UserPersonalPreferences.fromJson(jsonResponse);
      return prefs;
    } else {
      throw Exception(
          "upsertUserPersonalPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserGymPreferences> upsertUserGymPreferences(String userId, UserGymPreferencesPost prefs, String accessToken) async {
    final jsonBody = {
      'userId': prefs.userId,
      'gymLocationId': prefs.gymLocationId,
      'fsqId': prefs.fsqId,
    };
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/preferences/gym"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode(jsonBody)
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final prefs = UserGymPreferences.fromJson(jsonResponse);
      return prefs;
    } else {
      throw Exception(
          "upsertUserGymPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserGymPreferences?> getUserGymPreferences(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/preferences/gym"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userGymPreferences = UserGymPreferences.fromJson(jsonResponse);
      return userGymPreferences;
    } else if (response.statusCode == HttpStatus.notFound) {
      return null;
    } else {
      throw Exception(
          "getUserGymPreferences: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}