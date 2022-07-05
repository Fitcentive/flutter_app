import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/notification/notification_device.dart';
import 'package:http/http.dart' as http;

class NotificationRepository {

  static const String BASE_URL = "http://api.vid.app/api/notification";

  Future<void> registerDeviceToken(NotificationDevice device, String accessToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/push/${device.userId}/devices"),
        headers: {
          'Content-type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: json.encode({
          "userId": device.userId,
          "registrationToken": device.registrationToken,
          "manufacturer": device.manufacturer,
          "model": device.model,
          "isPhysicalDevice": device.isPhysicalDevice,
        })
    );
    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception("registerDeviceToken: Received bad response with status: ${response.statusCode}");
    }
  }

  Future<void> unregisterDeviceToken(String userId, String registrationToken, String accessToken) async {
    final response = await http.delete(
        Uri.parse("$BASE_URL/push/$userId/devices?registrationToken=$registrationToken"),
        headers: {
          'Content-type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
    );
    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception("unregisterDeviceToken: Received bad response with status: ${response.statusCode}");
    }
  }

}