import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
}