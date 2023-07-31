import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class AwardsRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/awards";

  final logger = Logger("AwardsRepository");

  Future<List<UserMilestone>> getAllUserAchievements(String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/achievements"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<UserMilestone> results = jsonResponse.map((e) {
        return UserMilestone.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getAllUserAchievements: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<UserMilestone>> getAllUserAchievementsForCategory(String accessToken, AwardCategory awardCategory) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/achievements?milestoneCategory=${awardCategory.name()}"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<UserMilestone> results = jsonResponse.map((e) {
        return UserMilestone.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getAllUserAchievementsForCategory: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<int> getTotalMilestonesForCategory(String accessToken, AwardCategory awardCategory) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/achievements/milestone-types?milestoneCategory=${awardCategory.name()}"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.length;
    }
    else {
      throw Exception(
          "getTotalMilestonesForCategory: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

}