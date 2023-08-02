import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:either_dart/either.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries_for_month.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/diary/user_steps_data.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_results.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_suggestions.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class DiaryRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/diary";

  static const int DEFAULT_MAX_SEARCH_FOOD_RESULTS = 50;
  static const int DEFAULT_MAX_AUTOCOMPLETE_SEARCH_FOOD_RESULTS = 5;
  static const int DEFAULT_SEARCH_FOOD_RESULTS_PAGE = 0;

  final logger = Logger("DiaryRepository");

  Future<UserStepsData> upsertUserStepsData(String userId, UserStepsDataUpsert upsert, String accessToken) async {
    final response = await http.put(
      Uri.parse("$BASE_URL/user/$userId/steps"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "stepsTaken": upsert.stepsTaken,
        "dateString": upsert.dateString,
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return UserStepsData.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertUserStepsData: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserStepsData?> getUserStepsData(String userId, String dateString, String accessToken) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/user/$userId/steps?dateString=$dateString"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return UserStepsData.fromJson(jsonResponse);
    }
    else if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    else {
      throw Exception(
          "getUserStepsData: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> addUserMostRecentlyViewedFoods(String userId, int foodId, String accessToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/user/$userId/recently-viewed-foods"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "id": foodId
        })
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "addUserMostRecentlyViewedFoods: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<String>> getUserMostRecentlyViewedFoodIds(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/recently-viewed-foods"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<String> results = jsonResponse.map((e) {
        return e.toString();
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getUserMostRecentlyViewedFoodIds: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> addUserMostRecentlyViewedWorkouts(String userId, String workoutId, String accessToken) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/user/$userId/recently-viewed-workouts"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "id": workoutId
      })
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "addUserMostRecentlyViewedWorkouts: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<String>> getUserMostRecentlyViewedWorkoutIds(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/recently-viewed-workouts"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<String> results = jsonResponse.map((e) {
        return e.toString();
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getUserMostRecentlyViewedWorkouts: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

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

  Future<ExerciseDefinition> getExerciseInfoByWorkoutId(
      String workoutId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/exercise/$workoutId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final dynamic jsonResponse = jsonDecode(response.body);
      final ExerciseDefinition result = ExerciseDefinition.fromJson(jsonResponse);
      return result;
    }
    else {
      throw Exception(
          "getExerciseInfoByWorkoutId: Received bad response with status: ${response.statusCode} and body ${response.body}");
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
          "cardioDate": entry.cardioDate.toUtc().toIso8601String(),
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

  Future<CardioDiaryEntry> getCardioUserDiaryEntry(
      String userId,
      String cardioDiaryEntryId,
      String accessToken
      ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/user/$userId/cardio/$cardioDiaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return CardioDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getCardioUserDiaryEntry: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<CardioDiaryEntry> updateCardioUserDiaryEntry(
      String userId,
      String cardioDiaryEntryId,
      CardioDiaryEntryUpdate entry,
      String accessToken
      ) async {
    final response = await http.put(
        Uri.parse("$BASE_URL/user/$userId/cardio/$cardioDiaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "cardioDate": entry.cardioDate.toUtc().toIso8601String(),
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
          "updateCardioUserDiaryEntry: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteCardioEntryFromUserDiary(
      String userId,
      String cardioWorkoutDiaryEntryId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/user/$userId/cardio/$cardioWorkoutDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "deleteCardioEntryFromUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
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
          "exerciseDate": entry.exerciseDate.toUtc().toIso8601String(),
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

  Future<StrengthDiaryEntry> updateStrengthUserDiaryEntry(
      String userId,
      String strengthDiaryEntryId,
      StrengthDiaryEntryUpdate entry,
      String accessToken
      ) async {
    final response = await http.put(
        Uri.parse("$BASE_URL/user/$userId/strength/$strengthDiaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "exerciseDate": entry.exerciseDate.toUtc().toIso8601String(),
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
          "updateStrengthUserDiaryEntry: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<StrengthDiaryEntry> getStrengthUserDiaryEntry(
      String userId,
      String strengthDiaryEntryId,
      String accessToken
      ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/user/$userId/strength/$strengthDiaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return StrengthDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getStrengthUserDiaryEntry: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteStrengthEntryFromUserDiary(
      String userId,
      String strengthWorkoutDiaryEntryId,
      String accessToken
      ) async {
    final response = await http.delete(
        Uri.parse("$BASE_URL/user/$userId/strength/$strengthWorkoutDiaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "deleteStrengthEntryFromUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<AllDiaryEntriesForMonth> getAllDiaryEntriesForUserByMonth(
      String userId,
      String dateString,
      int timeZoneOffsetInMinutes,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/month/$dateString?offsetInMinutes=$timeZoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return AllDiaryEntriesForMonth.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getAllDiaryEntriesForUserByMonth: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<AllDiaryEntries> getAllDiaryEntriesForUserByDay(
      String userId,
      String dateString,
      int timeZoneOffsetInMinutes,
      String accessToken,
    ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString?offsetInMinutes=$timeZoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return AllDiaryEntries.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getAllDiaryEntriesForUserByDay: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<CardioDiaryEntry>> getCardioWorkoutsForUserByDay(
      String userId,
      String dateString,
      int timeZoneOffsetInMinutes,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString/cardio?offsetInMinutes=$timeZoneOffsetInMinutes"),
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
      int timeZoneOffsetInMinutes,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString/strength?offsetInMinutes=$timeZoneOffsetInMinutes"),
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


  Future<FoodSearchSuggestions> autocompleteFoods(
      String query,
      String accessToken, {
        int maxResults = DEFAULT_MAX_AUTOCOMPLETE_SEARCH_FOOD_RESULTS
      }) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/food/search/autocomplete?query=$query&maxResults=$maxResults"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FoodSearchSuggestions.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "autocompleteFoods: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FoodSearchResults> searchForFoods(
      String query,
      String accessToken, {
        int pageNumber = DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
        int maxResults = DEFAULT_MAX_SEARCH_FOOD_RESULTS
      }) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/food/search?query=$query&pageNumber=$pageNumber&maxResults=$maxResults"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FoodSearchResults.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "searchForFoods: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Either<FoodGetResult, FoodGetResultSingleServing>> getFoodById(String foodId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/food/$foodId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      try {
        return Left(FoodGetResult.fromJson(jsonResponse));
      } catch (e) {
        return Right(FoodGetResultSingleServing.fromJson(jsonResponse));
      }

    }
    else {
      throw Exception(
          "getFoodById: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }


  Future<List<Either<FoodGetResult, FoodGetResultSingleServing>>> getFoodsByIds(
      List<String> foodIds,
      String accessToken
  ) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/food/get-by-food-ids"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "foodIds": foodIds
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final List<Either<FoodGetResult, FoodGetResultSingleServing>> results =
          jsonResponse.map<Either<FoodGetResult, FoodGetResultSingleServing>>((e) {
            final innerJson = jsonDecode(jsonEncode(e));
            Either<FoodGetResult, FoodGetResultSingleServing> eitherResult;
            try {
              eitherResult = Left<FoodGetResult, FoodGetResultSingleServing>(FoodGetResult.fromJson(innerJson));
            } catch (e) {
              eitherResult = Right<FoodGetResult, FoodGetResultSingleServing>(FoodGetResultSingleServing.fromJson(innerJson));
            }
            return eitherResult;
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getFoodsByIds: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<FoodDiaryEntry>> getFoodEntriesForUserByDay(
      String userId,
      String dateString,
      int timeZoneOffsetInMinutes,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/date/$dateString/food?offsetInMinutes=$timeZoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<FoodDiaryEntry> results = jsonResponse.map((e) {
        return FoodDiaryEntry.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getFoodEntriesForUserByDay: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FoodDiaryEntry> addFoodEntryToUserDiary(
      String userId,
      FoodDiaryEntryCreate entry,
      String accessToken
      ) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/user/$userId/food"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "foodId": entry.foodId,
          "servingId": entry.servingId,
          "numberOfServings": entry.numberOfServings,
          "mealEntry": entry.mealEntry,
          "entryDate": entry.entryDate.toUtc().toIso8601String(),
          "meetupId": entry.meetupId,
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FoodDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "addFoodEntryToUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FoodDiaryEntry> updateFoodDiaryEntryForUser(
      String userId,
      String diaryEntryId,
      FoodDiaryEntryUpdate entry,
      String accessToken
      ) async {
    final response = await http.put(
        Uri.parse("$BASE_URL/user/$userId/food/$diaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "servingId": entry.servingId,
          "numberOfServings": entry.numberOfServings,
          "entryDate": entry.entryDate.toUtc().toIso8601String(),
          "meetupId": entry.meetupId,
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FoodDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "updateFoodDiaryEntryForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FoodDiaryEntry> getFoodDiaryEntryById(
      String userId,
      String diaryEntryId,
      String accessToken
      ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/user/$userId/food/$diaryEntryId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FoodDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getFoodDiaryEntryById: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteFoodEntryFromUserDiary(
      String userId,
      String foodDiaryEntryId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/user/$userId/food/$foodDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "deleteFoodEntryFromUserDiary: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> associateDiaryEntriesWithMeetupId(
      String userId,
      String meetupId,
      List<String> cardioDiaryEntryIds,
      List<String> strengthDiaryEntryIds,
      List<String> foodDiaryEntryIds,
      String accessToken
      ) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/user/$userId/meetup/$meetupId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "foodEntryIds": foodDiaryEntryIds,
        "strengthEntryIds": strengthDiaryEntryIds,
        "cardioEntryIds": cardioDiaryEntryIds,
      })
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception(
          "associateDiaryEntriesWithMeetupId: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FitnessUserProfile?> getFitnessUserProfile(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/profile"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FitnessUserProfile.fromJson(jsonResponse);
    }
    else if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    else {
      throw Exception(
          "getFitnessUserProfile: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<FitnessUserProfile> upsertFitnessUserProfile(
      String userId,
      FitnessUserProfileUpdate update,
      String accessToken
  ) async {
    final response = await http.put(
      Uri.parse("$BASE_URL/user/$userId/profile"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "heightInCm": update.heightInCm,
        "weightInLbs": update.weightInLbs,
        "goal": update.goal,
        "stepGoalPerDay": update.stepGoalPerDay,
        "activityLevel": update.activityLevel,
        "goalWeightInLbs": update.goalWeightInLbs,
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return FitnessUserProfile.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertFitnessUserProfile: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

}