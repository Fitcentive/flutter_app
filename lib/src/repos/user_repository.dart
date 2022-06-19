import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/user.dart';

import 'package:http/http.dart' as http;

class UserRepository {

  static final String BASE_URL = "http://api.vid.app/api/user";

  Future<User?> getUser(String userId, String accessToken) async {

    final response = await http.get(
      Uri.parse("$BASE_URL/$userId"),
      headers: {
        "Authorization": "Bearer $accessToken"
      }
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    }
    else {
      return null;
    }

  }
}
