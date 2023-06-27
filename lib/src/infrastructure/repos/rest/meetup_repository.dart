import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetup_diary/meetup_cardio_diary_entry.dart';
import 'package:flutter_app/src/models/meetup_diary/meetup_food_diary_entry.dart';
import 'package:flutter_app/src/models/meetup_diary/meetup_strength_diary_entry.dart';
import 'package:flutter_app/src/models/meetups/detailed_meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_comment.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class MeetupRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/meetup";

  final logger = Logger("MeetupRepository");

  Future<AllDiaryEntries> getAllDiaryEntriesForMeetupUser(
      String meetupId,
      String userId,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/user/$userId/diary-entry"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return AllDiaryEntries.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getAllDiaryEntriesForMeetupUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupStrengthDiaryEntry> upsertStrengthDiaryEntryToMeetup(
      String meetupId,
      String strengthDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.post(
      Uri.parse("$BASE_URL/meetups/$meetupId/strength-entry/$strengthDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return MeetupStrengthDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertStrengthDiaryEntryToMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<MeetupCardioDiaryEntry> upsertCardioDiaryEntryToMeetup(
      String meetupId,
      String cardioDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.post(
      Uri.parse("$BASE_URL/meetups/$meetupId/cardio-entry/$cardioDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return MeetupCardioDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertCardioDiaryEntryToMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<MeetupFoodDiaryEntry> upsertFoodDiaryEntryToMeetup(
      String meetupId,
      String foodDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.post(
      Uri.parse("$BASE_URL/meetups/$meetupId/food-entry/$foodDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      return MeetupFoodDiaryEntry.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertFoodDiaryEntryToMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<void> deleteStrengthDiaryEntryFromAssociatedMeetup(
      String meetupId,
      String strengthDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/strength-entry/$strengthDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.accepted) {
      return;
    }
    else {
      throw Exception(
          "deleteStrengthDiaryEntryFromAssociatedMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<void> deleteCardioDiaryEntryFromAssociatedMeetup(
      String meetupId,
      String cardioDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/cardio-entry/$cardioDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.accepted) {
      return;
    }
    else {
      throw Exception(
          "deleteCardioDiaryEntryFromAssociatedMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<void> deleteFoodDiaryEntryFromAssociatedMeetup(
      String meetupId,
      String foodDiaryEntryId,
      String accessToken
      ) async {

    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/food-entry/$foodDiaryEntryId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.accepted) {
      return;
    }
    else {
      throw Exception(
          "deleteFoodDiaryEntryFromAssociatedMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }

  }

  Future<Meetup?> getMeetupByChatRoomId(
      String chatRoomId,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/chat-room/$chatRoomId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Meetup.fromJson(jsonResponse);
    }
    else if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    else {
      throw Exception(
          "getMeetupByChatRoomId: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteMeetupCommentForUser(
      String meetupId,
      String commentId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/comments/$commentId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "deleteMeetupCommentForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupComment> createMeetupComment(
      String meetupId,
      String comment,
      String accessToken
      ) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/meetups/$meetupId/comments"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "comment": comment
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return MeetupComment.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "createMeetupComment: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<MeetupComment>> getMeetupComments(
      String meetupId,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/comments"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<MeetupComment> results = jsonResponse.map((e) {
        return MeetupComment.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupComments: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Meetup> updateMeetup(
      String meetupId,
      MeetupUpdate updatedMeetup,
      String accessToken
      ) async {
    final response = await http.put(
        Uri.parse("$BASE_URL/meetups/$meetupId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          "meetupType": updatedMeetup.meetupType,
          "name" : updatedMeetup.name,
          "time" : updatedMeetup.time?.toUtc().toIso8601String(),
          "durationInMinutes" : updatedMeetup.durationInMinutes,
          "locationId" : updatedMeetup.locationId,
          "chatRoomId": updatedMeetup.chatRoomId,
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Meetup.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "updateMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Meetup> updateMeetupChatRoom(
      String meetupId,
      String chatRoomId,
      String accessToken
      ) async {
    final response = await http.put(
        Uri.parse("$BASE_URL/meetups/$meetupId/chat-room/$chatRoomId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Meetup.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "updateMeetupChatRoom: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Meetup> createMeetup(
      MeetupCreate newMeetup,
      String accessToken
      ) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/meetups"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "meetupType": newMeetup.meetupType,
        "owner" : newMeetup.ownerId,
        "name" : newMeetup.name,
        "time" : newMeetup.time?.toUtc().toIso8601String(),
        "durationInMinutes" : newMeetup.durationInMinutes,
        "locationId" : newMeetup.locationId
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Meetup.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "createMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteMeetupForUser(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "getMeetupsForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<Meetup>> getMeetupsForUserByMonth(
      String accessToken,
      String dateString,
      int timezoneOffsetInMinutes,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/month/$dateString?offsetInMinutes=$timezoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<Meetup> results = jsonResponse.map((e) {
        return Meetup.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupsForUserByMonth: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DetailedMeetup>> getDetailedMeetupsForUserByMonth(
      String accessToken,
      String dateString,
      int timezoneOffsetInMinutes,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/detailed-meetups/month/$dateString?offsetInMinutes=$timezoneOffsetInMinutes"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<DetailedMeetup> results = jsonResponse.map((e) {
        return DetailedMeetup.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getDetailedMeetupsForUserByMonth: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DetailedMeetup>> getDetailedMeetupsForUser(
      String userId,
      String accessToken,
      int limit,
      int offset,
      String? filterBy,
      String? status
      ) async {
    final filterByOption = filterBy == null ? "" : "&filterBy=$filterBy";
    final statusOption = status == null ? "" : "&status=$status";
    final response = await http.get(
      Uri.parse("$BASE_URL/detailed-meetups?limit=$limit&offset=$offset$filterByOption$statusOption"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<DetailedMeetup> results = jsonResponse.map((e) {
        return DetailedMeetup.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getDetailedMeetupsForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<DetailedMeetup> getDetailedMeetupForUserById(
      String meetupId,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/detailed-meetups/$meetupId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final dynamic jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return DetailedMeetup.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getDetailedMeetupForUserById: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<Meetup>> getMeetupsForUser(
      String userId,
      String accessToken,
      int limit,
      int offset,
      String? filterBy,
      String? status
      ) async {
    final filterByOption = filterBy == null ? "" : "&filterBy=$filterBy";
    final statusOption = status == null ? "" : "&status=$status";
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups?limit=$limit&offset=$offset$filterByOption$statusOption"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<Meetup> results = jsonResponse.map((e) {
        return Meetup.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupsForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Meetup> getMeetupById(
      String meetupId,
      String accessToken,
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Meetup.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "getMeetupById: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<MeetupDecision>> getMeetupDecisions(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/decisions"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<MeetupDecision> results = jsonResponse.map((e) {
        return MeetupDecision.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupDecisions: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupDecision> upsertMeetupDecision(
      String meetupId,
      String participantId,
      bool hasAccepted,
      String accessToken
      ) async {
    final response = await http.put(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId/decision"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: json.encode({
        "hasAccepted": hasAccepted
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return MeetupDecision.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "upsertMeetupDecision: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteUserMeetupDecision(
      String meetupId,
      String participantId,
      String accessToken
      ) async {
    final response = await http.delete(
        Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId/decision"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "deleteUserMeetupDecision: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<MeetupParticipant>> getMeetupParticipants(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<MeetupParticipant> results = jsonResponse.map((e) {
        return MeetupParticipant.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupParticipants: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  // This is unused at the moment
  Future<void> removeAllParticipantsFromMeetup(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "removeAllParticipantsToMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> removeParticipantFromMeetup(
      String meetupId,
      String participantId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    else {
      throw Exception(
          "removeParticipantFromMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupParticipant> addParticipantToMeetup(
      String meetupId,
      String participantUserId,
      String accessToken
      ) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantUserId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return MeetupParticipant.fromJson(jsonResponse);
    }
    else {
      throw Exception(
          "addParticipantToMeetup: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<MeetupAvailability>> getMeetupParticipantAvailabilities(
      String meetupId,
      String participantId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId/availabilities"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<MeetupAvailability> results = jsonResponse.map((e) {
        return MeetupAvailability.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getMeetupParticipantAvailability: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<MeetupAvailability>> upsertMeetupParticipantAvailabilities(
      String meetupId,
      String participantId,
      String accessToken,
      List<MeetupAvailabilityUpsert> availabilities,
      ) async {
    final response = await http.put(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId/availabilities"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        "availabilities": availabilities.map((e) => e.toJson()).toList()
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<MeetupAvailability> results = jsonResponse.map((e) {
        return MeetupAvailability.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "upsertMeetupParticipantAvailabilities: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deleteMeetupParticipantAvailabilities(
      String meetupId,
      String participantId,
      String accessToken
      ) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants/$participantId/availabilities"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
        return;
    }
    else {
      throw Exception(
          "deleteMeetupParticipantAvailabilities: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<Location> getLocationByFsqId(
      String fsqId,
      String accessToken
      ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/fsq-locations/$fsqId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final result = Location.fromJson(jsonResponse);
      return result;
    }
    else {
      throw Exception(
          "getLocationByFsqId: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupLocation> getLocationByLocationId(
      String locationId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/locations/$locationId"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final result = MeetupLocation.fromJson(jsonResponse);
      return result;
    }
    else {
      throw Exception(
          "getLocationByLocationId: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<Location>> getGymsAroundLocation(
      String query,
      Coordinates userCoordinates,
      int userRadiusInMetres,
      String accessToken
  ) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/locations?query=$query"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({
          "userLocation": {
            "center": {
              "latitude": userCoordinates.latitude,
              "longitude": userCoordinates.longitude,
            },
            "radiusInMetres": userRadiusInMetres
          }
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final List<Location> results = jsonResponse.map((e) {
        return Location.fromJson(e);
      }).toList();
      return results;
    }
    else {
      throw Exception(
          "getGymsAroundLocation: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<MeetupLocation> upsertGymLocation(MeetupLocationPost payload, String userId, String accessToken) async {
    final response = await http.put(
      Uri.parse("$BASE_URL/locations"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({
          "fsqId": payload.fsqId,
          "locationName": payload.locationName,
          "website": payload.website,
          "phone": payload.phone,
          "coordinates": {
            "latitude": payload.coordinates.latitude,
            "longitude": payload.coordinates.longitude,
          }
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final meetupLocation = MeetupLocation.fromJson(jsonResponse);
      return meetupLocation;
    }
    else {
      throw Exception(
          "getGymsAroundLocation: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}