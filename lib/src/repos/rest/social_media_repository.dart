import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/social/social_post.dart';

import 'package:http/http.dart' as http;

class SocialMediaRepository {
  static const String BASE_URL = "http://api.vid.app/api/user";

  Future<List<SocialPost>> getNewsfeedForUser(String userId,String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/$userId/newsfeed"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final posts = jsonResponse.map((e) => SocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getNewsfeedForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<SocialPost>> getPostsForUser(String userId,String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/$userId/post"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final posts = jsonResponse.map((e) => SocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getNewsfeedForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<SocialPost> createPostForUser(String userId, SocialPostCreate newPost,String accessToken, ) async {
    final response = await http.post(Uri.parse("$BASE_URL/$userId/post"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: json.encode({
        'userId': newPost.userId,
        'text': newPost.text,
        'photoUrl': newPost.photoUrl,
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final post = SocialPost.fromJson(jsonResponse);
      return post;
    } else {
      throw Exception(
          "getNewsfeedForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}