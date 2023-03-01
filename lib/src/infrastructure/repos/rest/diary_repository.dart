import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class DiaryRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/diary";

  final logger = Logger("DiaryRepository");

  Future<List<ExerciseDefinition>> getAllExerciseInfo(
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/exercise"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<ExerciseDefinition> results = jsonResponse.map((e) {
        return ExerciseDefinition.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getAllExerciseInfo: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<CardioDiaryEntry> addCardioEntryToUserDiary(
      String userId,
      CardioDiaryEntryCreate entry,
      String accessToken
      ) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/user/$userId/cardio"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "workoutId": entry.workoutId,
          "name": entry.name,
          "cardioDate": entry.cardioDate,
          "durationInMinutes": entry.durationInMinutes,
          "caloriesBurned": entry.caloriesBurned,
          "meetupId": entry.meetupId,
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return CardioDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "addCardioEntryToUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<StrengthDiaryEntry> addStrengthEntryToUserDiary(
      String userId,
      StrengthDiaryEntryCreate entry,
      String accessToken
      ) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/user/$userId/strength"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "workoutId": entry.workoutId,
          "name": entry.name,
          "exerciseDate": entry.exerciseDate,
          "sets": entry.sets,
          "reps": entry.reps,
          "weightsInLbs": entry.weightsInLbs,
          "caloriesBurned": entry.caloriesBurned,
          "meetupId": entry.meetupId,
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return StrengthDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "addStrengthEntryToUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<CardioDiaryEntry>> getCardioWorkoutsForUserByDay(
      String userId,
      String dateString,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString/cardio"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<CardioDiaryEntry> results = jsonResponse.map((e) {
        return CardioDiaryEntry.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getCardioWorkoutsForUserByDay: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<StrengthDiaryEntry>> getStrengthWorkoutsForUserByDay(
      String userId,
      String dateString,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString/strength"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<StrengthDiaryEntry> results = jsonResponse.map((e) {
        return StrengthDiaryEntry.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getStrengthWorkoutsForUserByDay: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}