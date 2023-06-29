import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/newsfeed/bloc/newsfeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:collection/collection.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  static const mostRecentCommentsLimit = 3;

  final SocialMediaRepository socialMediaRepository;
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  NewsFeedBloc({
    required this.socialMediaRepository,
    required this.userRepository,
    required this.secureStorage
  }): super(const NewsFeedStateInitial()) {
    on<TrackViewNewsfeedHomeEvent>(_trackViewNewsfeedHomeEvent);
    on<NewsFeedFetchRequested>(_newsFeedFetchRequested);
    on<NewsFeedReFetchRequested>(_newsFeedReFetchRequested);
    on<LikePostForUser>(_likePostForUser);
    on<UnlikePostForUser>(_unlikePostForUser);
  }

  void _trackViewNewsfeedHomeEvent(TrackViewNewsfeedHomeEvent event, Emitter<NewsFeedState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewNewsfeedHome(), accessToken!);
  }

  void _likePostForUser(LikePostForUser event, Emitter<NewsFeedState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.likePostForUser(event.postId, event.userId, accessToken!);
    userRepository.trackUserEvent(LikeSocialPost(), accessToken);
  }

  void _unlikePostForUser(UnlikePostForUser event, Emitter<NewsFeedState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.unlikePostForUser(event.postId, event.userId, accessToken!);
  }

  void _newsFeedReFetchRequested(NewsFeedReFetchRequested event, Emitter<NewsFeedState> emit) async {
    emit(const NewsFeedDataLoading());

    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final detailedPosts = await socialMediaRepository.getDetailedNewsfeedForUser(
        event.user.user.id,
        accessToken!,
        event.createdBefore,
        event.limit,
        mostRecentCommentsLimit,
    );
    // final postIds = posts.map((e) => e.postId).toList();
    // final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

    // final List<List<SocialPostComment>> postsComments =
    // await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
    // final Map<String, List<SocialPostComment>> postIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

    final Map<String, List<SocialPostComment>> postIdCommentMap =
    { for (var e in IterableZip([
            detailedPosts.map((e) => e.post.postId).toList(),
            detailedPosts.map((e) => e.mostRecentComments).toList()
          ]
        )
      ) e[0] as String : e[1] as List<SocialPostComment>
    };
    final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(
      detailedPosts.map((e) => e.post).toList(),
      detailedPosts.map((e) => e.mostRecentComments).toList(),
    );
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    final doesNextPageExist = detailedPosts.length == event.limit ? true : false;

    emit(NewsFeedDataReady(
        user: event.user,
        posts: detailedPosts.map((e) => e.post).toList(),
        postsWithLikedUserIds: detailedPosts.map((e) => PostsWithLikedUserIds(e.post.postId, e.likedUserIds)).toList(),
        userIdProfileMap: userIdProfileMap,
        doesNextPageExist: doesNextPageExist,
        postIdCommentsMap: postIdCommentMap,
    ));
  }

  void _newsFeedFetchRequested(NewsFeedFetchRequested event, Emitter<NewsFeedState> emit) async {
    final currentState = state;

    if (currentState is NewsFeedStateInitial) {
      emit(const NewsFeedDataLoading());

      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final detailedPosts = await socialMediaRepository.getDetailedNewsfeedForUser(
          event.user.user.id,
          accessToken!,
          event.createdBefore,
          event.limit,
          mostRecentCommentsLimit,
      );
      // final postIds = posts.map((e) => e.postId).toList();
      // final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

      // final List<List<SocialPostComment>> postsComments =
      //   await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
      // final Map<String, List<SocialPostComment>> postIdCommentMap =
      //   { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

      final Map<String, List<SocialPostComment>> postIdCommentMap =
        { for (var e in IterableZip([
                detailedPosts.map((e) => e.post.postId).toList(),
                detailedPosts.map((e) => e.mostRecentComments).toList()
              ]
            )
          ) e[0] as String : e[1] as List<SocialPostComment>
        };
      final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(
          detailedPosts.map((e) => e.post).toList(),
          detailedPosts.map((e) => e.mostRecentComments).toList(),
      );
      final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final doesNextPageExist = detailedPosts.length == event.limit ? true : false;

      emit(NewsFeedDataReady(
          user: event.user,
          posts: detailedPosts.map((e) => e.post).toList(),
          postsWithLikedUserIds: detailedPosts.map((e) => PostsWithLikedUserIds(e.post.postId, e.likedUserIds)).toList(),
          userIdProfileMap: userIdProfileMap,
          doesNextPageExist: doesNextPageExist,
          postIdCommentsMap: postIdCommentMap
      ));
    }
    else if (currentState is NewsFeedDataReady && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final detailedPosts = await socialMediaRepository.getDetailedNewsfeedForUser(
          event.user.user.id,
          accessToken!,
          event.createdBefore,
          event.limit,
          mostRecentCommentsLimit,
      );
      // final postIds = posts.map((e) => e.postId).toList();
      // final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

      // final List<List<SocialPostComment>> postsComments =
      // await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
      // final Map<String, List<SocialPostComment>> postIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

      final Map<String, List<SocialPostComment>> postIdCommentMap =
      { for (var e in IterableZip([
              detailedPosts.map((e) => e.post.postId).toList(),
              detailedPosts.map((e) => e.mostRecentComments).toList()
            ]
          )
        ) e[0] as String : e[1] as List<SocialPostComment>
      };
      final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(
        detailedPosts.map((e) => e.post).toList(),
        detailedPosts.map((e) => e.mostRecentComments).toList(),
      );
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final doesNextPageExist = detailedPosts.length == event.limit ? true : false;

      final completePostsList = [...currentState.posts, ...detailedPosts.map((e) => e.post)];
      final updatedUserIdProfileMap = {...currentState.userIdProfileMap, ...userIdProfileMap};
      final updatedLikedUsersForPostIds = [...currentState.postsWithLikedUserIds, ...detailedPosts.map((e) => PostsWithLikedUserIds(e.post.postId, e.likedUserIds))];
      final updatedCommentMap = {...currentState.postIdCommentsMap, ...postIdCommentMap};

      emit(NewsFeedDataReady(
          user: event.user,
          posts: completePostsList,
          postsWithLikedUserIds: updatedLikedUsersForPostIds,
          userIdProfileMap: updatedUserIdProfileMap,
          doesNextPageExist: doesNextPageExist,
          postIdCommentsMap: updatedCommentMap,
      ));
    }

  }

  List<String> _getRelevantUserIdsFromPostsAndComments(List<SocialPost> posts, List<List<SocialPostComment>> comments) {
    final distinctPostUserIds = posts
        .map((e) => e.userId)
        .toSet()
        .toList();
    final distinctCommentUserIds = comments
      .map((e) => e.map((c) => c.userId))
      .expand((element) => element)
      .toSet()
      .toList();

    return [...distinctPostUserIds, ...distinctCommentUserIds].toSet().toList();
  }
}