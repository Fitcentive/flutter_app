import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  final SocialMediaRepository socialMediaRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  NewsFeedBloc({
    required this.socialMediaRepository,
    required this.userRepository,
    required this.secureStorage
  }): super(const NewsFeedStateInitial()) {
    on<NewsFeedFetchRequested>(_newsFeedFetchRequested);
    on<LikePostForUser>(_likePostForUser);
    on<UnlikePostForUser>(_unlikePostForUser);
  }

  void _likePostForUser(LikePostForUser event, Emitter<NewsFeedState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.likePostForUser(event.postId, event.userId, accessToken!);
  }

  void _unlikePostForUser(UnlikePostForUser event, Emitter<NewsFeedState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.unlikePostForUser(event.postId, event.userId, accessToken!);
  }

  void _newsFeedFetchRequested(NewsFeedFetchRequested event, Emitter<NewsFeedState> emit) async {
    emit(const NewsFeedDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final posts = await socialMediaRepository.getNewsfeedForUser(event.user.user.id, accessToken!);
    final postIds = posts.map((e) => e.postId).toList();
    final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

    final distinctUserIdsFromPosts = _getRelevantUserIdsFromPosts(posts);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(NewsFeedDataReady(
        user: event.user,
        posts: posts,
        postsWithLikedUserIds: likedUsersForPostIds,
        userIdProfileMap: userIdProfileMap
    ));
  }

  List<String> _getRelevantUserIdsFromPosts(List<SocialPost> posts) {
    return posts
        .map((e) => e.userId)
        .toSet()
        .toList();
  }
}