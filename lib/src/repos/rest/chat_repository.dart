import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/chats/chat_message.dart';
import 'package:flutter_app/src/models/chats/chat_room.dart';
import 'package:flutter_app/src/models/chats/room_most_recent_message.dart';

import 'package:http/http.dart' as http;

class ChatRepository {
  static const String BASE_URL = "http://api.vid.app/api/chat";

  Future<ChatRoom> getChatRoomForConversation(String targetUserId, String accessToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/get-chat-room"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: json.encode({
          "target_user": targetUserId
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final chatRoom = ChatRoom.fromJson(jsonResponse);
      return chatRoom;
    } else {
      throw Exception(
          "getChatRoomForConversation: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<ChatMessage>> getMessagesForRoom(String roomId, String accessToken) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/room/$roomId/messages"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        });

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final messages = jsonResponse.map((e) => ChatMessage.fromJson(e)).toList();
      return messages;
    } else {
      throw Exception(
          "getMessagesForRoom: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<ChatRoom>> getUserChatRooms(String userId, String accessToken) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/user/rooms"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        });

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final chatRooms = jsonResponse.map((e) => ChatRoom.fromJson(e)).toList();
      return chatRooms;
    } else {
      throw Exception(
          "getUserChatRooms: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<RoomMostRecentMessage>> getRoomMostRecentMessage(List<String> roomIds, String accessToken) async {
    final response = await http.post(
        Uri.parse("$BASE_URL/room/most-recent-message"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
      body: json.encode({
        "room_ids": roomIds
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final roomMostRecentMessage = jsonResponse.map((e) => RoomMostRecentMessage.fromJson(e)).toList();
      return roomMostRecentMessage;
    } else {
      throw Exception(
          "getRoomMostRecentMessage: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

}