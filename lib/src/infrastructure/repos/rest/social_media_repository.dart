import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/detailed_social_post.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/models/user_friend_status.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';

import 'package:http/http.dart' as http;

class SocialMediaRepository {
  static const String BASE_URL = "${ConstantUtils.API_HOST_URL}/api/social";

  Future<void> requestToFriendUser(String currentUserId, String targetUserId, String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/user/$currentUserId/friend/$targetUserId/request"),
        headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == HttpStatus.accepted) {
      return;
    } else {
      throw Exception(
          "requestToFollowUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<UserFriendStatus> getUserFriendStatus(
      String requestingUserId, String targetUserId, String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/user/$requestingUserId/friend-status/$targetUserId"),
        headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final userFollowStatus = UserFriendStatus.fromJson(jsonResponse);
      return userFollowStatus;
    } else {
      throw Exception(
          "getUserFollowStatus: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> applyUserDecisionToFriendRequest(
      String requestingUserId, String targetUserId, bool isRequestApproved, String accessToken) async {
    final jsonBody = {
      'isRequestApproved': isRequestApproved,
    };
    final response = await http.post(
        Uri.parse("$BASE_URL/user/$targetUserId/friend/$requestingUserId"),
        headers: {
          'Content-type': 'application/json',
          "Authorization": "Bearer $accessToken",
        },
        body: json.encode(jsonBody));

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "applyUserDecisionToFollowRequest: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<PublicUserProfile>> fetchUserFriends(String userId, String accessToken, int limit, int offset) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/friends?skip=$offset&limit=$limit"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final publicUserProfiles = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return publicUserProfiles;
    } else {
      throw Exception(
          "fetchUserFollowers: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<PublicUserProfile>> searchUserFriends(String userId, String query, String accessToken, int limit, int offset) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/search-friends?query=$query&skip=$offset&limit=$limit"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final publicUserProfiles = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return publicUserProfiles;
    } else {
      throw Exception(
          "searchUserFriends: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> unfriendUser(String currentUserId, String targetUserId, String accessToken) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/user/$currentUserId/unfriend/$targetUserId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "fetchUserFollowing: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DetailedSocialPost>> getDetailedNewsfeedForUser(
      String userId,
      String accessToken,
      int createdBefore,
      int limit,
      int mostRecentCommentsLimit
  ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/detailed-newsfeed?createdBefore=$createdBefore&limit=$limit&mostRecentCommentsLimit=$mostRecentCommentsLimit"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = jsonResponse.map((e) => DetailedSocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getDetailedNewsfeedForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<SocialPost>> getNewsfeedForUser(String userId, String accessToken, int createdBefore, int limit) async {
    final response = await http.get(Uri.parse("$BASE_URL/user/$userId/newsfeed?createdBefore=$createdBefore&limit=$limit"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = jsonResponse.map((e) => SocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getNewsfeedForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<PostsWithLikedUserIds>> getPostsWithLikedUserIds(List<String> postIds,String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/posts/get-liked-user-ids"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: json.encode({
        "postIds": postIds
      })
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final likedUsers = jsonResponse.map((e) => PostsWithLikedUserIds.fromJson(e)).toList();
      return likedUsers;
    } else {
      throw Exception(
          "getPostsWithLikedUserIds: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<PublicUserProfile>> getLikedUsersForPost(String postId,String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/post/$postId/liked-users"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'}
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final likedUsers = jsonResponse.map((e) => PublicUserProfile.fromJson(e)).toList();
      return likedUsers;
    } else {
      throw Exception(
          "getLikedUsersForPost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<SocialPostComment>> getCommentsForPost(String postId, String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/post/$postId/comment"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'}
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final comments = jsonResponse.map((e) => SocialPostComment.fromJson(e)).toList();
      return comments;
    } else {
      throw Exception(
          "getCommentsForPost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<SocialPostComment>> getCommentChunkForPost(
      String postId,
      String accessToken,
      int skip,
      int limit,
      ) async {
    final response = await http.get(
        Uri.parse("$BASE_URL/post/$postId/comment-chunk?limit=$limit&skip=$skip"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'}
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final comments = jsonResponse.map((e) => SocialPostComment.fromJson(e)).toList();
      return comments;
    } else {
      throw Exception(
          "getCommentChunkForPost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<SocialPostComment> addCommentToPost(String postId, String userId, String text, String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/post/$postId/comment"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: json.encode({
          "text": text
        })
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(response.body);
      final comment =  SocialPostComment.fromJson(jsonResponse);
      return comment;
    } else {
      throw Exception(
          "addCommentToPost: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<SocialPost> getPostById(String postId, String accessToken) async {
    final response = await http.get(Uri.parse("$BASE_URL/post/$postId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final post =  SocialPost.fromJson(jsonResponse);
      return post;
    } else {
      throw Exception(
          "getPostById: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> likePostForUser(String postId, String userId, String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/post/$postId/like"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "likePostForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> unlikePostForUser(String postId, String userId, String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/post/$postId/unlike"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else {
      throw Exception(
          "unlikePostForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<DetailedSocialPost>> getDetailedPostsForUser(
      String userId,
      String accessToken,
      int createdBefore,
      int limit,
      int mostRecentCommentsLimit
  ) async {
    final response = await http.get(
      Uri.parse("$BASE_URL/user/$userId/detailed-post?createdBefore=$createdBefore&limit=$limit&mostRecentCommentsLimit=$mostRecentCommentsLimit"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = jsonResponse.map((e) => DetailedSocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getDetailedPostsForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<List<SocialPost>> getPostsForUser(String userId, String accessToken, int createdBefore, int limit) async {
    final response = await http.get(Uri.parse("$BASE_URL/user/$userId/post?createdBefore=$createdBefore&limit=$limit"),
      headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = jsonResponse.map((e) => SocialPost.fromJson(e)).toList();
      return posts;
    } else {
      throw Exception(
          "getPostsForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<SocialPost> createPostForUser(String userId, SocialPostCreate newPost,String accessToken) async {
    final response = await http.post(Uri.parse("$BASE_URL/user/$userId/post"),
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
          "createPostForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }

  Future<void> deletePostForUser(String postId, String userId, String accessToken) async {
    final response = await http.delete(Uri.parse("$BASE_URL/user/$userId/post/$postId"),
        headers: {'Content-type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == HttpStatus.noContent) {
      return;
    } else {
      throw Exception(
          "deletePostForUser: Received bad response with status: ${response.statusCode} and body ${response.body}");
    }
  }
}