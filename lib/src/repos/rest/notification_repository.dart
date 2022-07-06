import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/push/notification_device.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class NotificationRepository {
  static const String BASE_URL = "http://api.vid.app/api/notification";

  final logger = Logger("NotificationRepository");

  Future<void> registerDeviceToken(NotificationDevice device, String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/push/${device.userId}/devices"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({
          "userId": device.userId,
          "registrationToken": device.registrationToken,
          "manufacturer": device.manufacturer,
          "model": device.model,
          "isPhysicalDevice": device.isPhysicalDevice,
        }));
    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception(
          "registerDeviceToken: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> unregisterDeviceToken(String userId, String registrationToken, String accessToken) async {
    final response = await http.delete(
      Uri.parse("$BASE_URL/push/$userId/devices?registrationToken=$registrationToken"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception("unregisterDeviceToken: Received bad response with status: ${response.statusCode}");
    }
  }

  Future<List<AppNotification>> fetchUserNotifications(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/$userId/notifications"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<AppNotification> notifications = jsonResponse.map((e) => AppNotification.fromJson(e)).toList();
      return notifications;
    } else {
      throw Exception("fetchUserNotifications: Received bad response with status: ${response.statusCode}");
    }
  }
}