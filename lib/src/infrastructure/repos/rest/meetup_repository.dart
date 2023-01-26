import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/metups/meetup_location.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class MeetupRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/meetup";

  final logger = Logger("MeetupRepository");

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