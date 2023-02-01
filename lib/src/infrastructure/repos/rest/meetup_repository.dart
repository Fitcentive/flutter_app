import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
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
      final jsonResponse = jsonDecode(response.body);
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
    final response = await http.get(
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

  Future<List<Meetup>> getMeetupsForUser(
      String userId,
      String accessToken,
      int limit,
      int offset
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups?limit=$limit&offset=$offset"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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

  Future<List<MeetupDecision>> getMeetupDecisions(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/decisions"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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

  Future<List<MeetupParticipant>> getMeetupParticipants(
      String meetupId,
      String accessToken
      ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/meetups/$meetupId/participants"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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
      final jsonResponse = jsonDecode(response.body);
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
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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
      final jsonResponse = jsonDecode(response.body);
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
      final jsonResponse = jsonDecode(response.body);
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
      final List<dynamic> jsonResponse = jsonDecode(response.body);
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
      final jsonResponse = jsonDecode(response.body);
      final meetupLocation = MeetupLocation.fromJson(jsonResponse);
      return meetupLocation;
    }
    else {
      throw Exception(
          "getGymsAroundLocation: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}