import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/notification/app_notification.dart';
import 'package:flutter_app/src/models/push/notification_device.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class NotificationRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/notification";

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

  Future<List<AppNotification>> fetchUserNotifications(String userId, String accessToken, int limit, int offset) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/$userId/notifications?limit=$limit&offset=$offset"),
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

  Future<void> updateUserNotification(
      String userId,
      AppNotification notification,
      bool isApproved,
      String accessToken
      ) async {
    final bodyMap = notification.data;
    bodyMap['isApproved'] = isApproved;
    final response = await http.put(
      Uri.parse("$BASE_URL/$userId/notifications/${notification.id}"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: json.encode({
        "hasBeenInteractedWith": true,
        "hasBeenViewed": true,
        "data": bodyMap
      })
    );
    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception("updateUserNotification: Received bad response with status: ${response.statusCode}");
    }
  }

  Future<int> getUnreadNotificationCount(
      String userId,
      String accessToken
  ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/$userId/notifications/get-unread-count"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final unreadCount = jsonResponse as int;
      return unreadCount;
    } else {
      throw Exception("getUnreadNotificationCount: Received bad response with status: ${response.statusCode}");
    }
  }

  Future<void> markNotificationsAsRead(
      String userId,
      List<String> notificationIds,
      String accessToken
      ) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/$userId/notifications/mark-as-viewed"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({
          "notificationIds": notificationIds,
        })
    );
    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception("markNotificationsAsRead: Received bad response with status: ${response.statusCode}");
    }
  }
}