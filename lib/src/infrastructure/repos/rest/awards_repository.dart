import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/awards/user_milestone.dart';
import 'package:flutter_app/src/models/progress/activity_minutes_per_day.dart';
import 'package:flutter_app/src/models/progress/diary_entries_per_day.dart';
import 'package:flutter_app/src/models/progress/progress_insights.dart';
import 'package:flutter_app/src/models/progress/user_step_metrics.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class AwardsRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/awards";

  final logger = Logger("AwardsRepository");

  Future<List<UserStepMetrics>> getUserStepProgressData(String from, String to, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/progress/steps"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<UserStepMetrics> results = jsonResponse.map((e) {
        return UserStepMetrics.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getUserStepProgressData: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DiaryEntriesPerDay>> getUserDiaryEntryProgressData(String from, String to, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/progress/diary"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<DiaryEntriesPerDay> results = jsonResponse.map((e) {
        return DiaryEntriesPerDay.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getUserDiaryEntryProgressData: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<ActivityMinutesPerDay>> getUserActivityProgressData(String from, String to, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/progress/activity"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<ActivityMinutesPerDay> results = jsonResponse.map((e) {
        return ActivityMinutesPerDay.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getUserActivityProgressData: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<ProgressInsights> getUserProgressInsights(String accessToken, int timeZoneOffsetInMinutes) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/progress/insights?offsetInMinutes=$timeZoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final dynamic jsonResponse = jsonDecode(response.body);
      final ProgressInsights results = ProgressInsights.fromJson(jsonResponse);
      return results;
    }
    else {
      throw Exception(
          "getUserProgressInsights: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

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