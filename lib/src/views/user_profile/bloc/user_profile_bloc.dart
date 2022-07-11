import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserRepository userRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage flutterSecureStorage;

  UserProfileBloc({
    required this.userRepository,
    required this.flutterSecureStorage,
    required this.socialMediaRepository,
  }) : super(const UserProfileInitial()) {
    on<FetchRequiredData>(_fetchRequiredData);
    on<FetchUserPostsData>(_fetchUserPostsData);
    on<RequestToFollowUser>(_requestToFollowUser);
    on<UnfollowUser>(_unfollowUser);
    on<UnlikePostForUser>(_unlikePostForUser);
    on<LikePostForUser>(_likePostForUser);
    on<RemoveUserFromCurrentUserFollowers>(_removeUserFromCurrentUserFollowers);
    on<ApplyUserDecisionToFollowRequest>(_applyUserDecisionToFollowRequest);
  }


  void _likePostForUser(LikePostForUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.likePostForUser(event.postId, event.currentUser.user.id, accessToken!);
  }

  void _unlikePostForUser(UnlikePostForUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.unlikePostForUser(event.postId, event.currentUser.user.id, accessToken!);
  }


  void _fetchUserPostsData(FetchUserPostsData event, Emitter<UserProfileState> emit) async {
    emit(const DataLoading());
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    List<SocialPost>? userPosts;
    List<PostsWithLikedUserIds>? likedUsersForPostIds;
    if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFollowingOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);
    }
    emit(RequiredDataResolved(
        userFollowStatus: event.userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds
    ));
  }

  void _fetchRequiredData(FetchRequiredData event, Emitter<UserProfileState> emit) async {
    emit(const DataLoading());
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFollowStatus =
        await userRepository.getUserFollowStatus(event.currentUser.user.id, event.userId, accessToken!);

    List<SocialPost>? userPosts;
    List<PostsWithLikedUserIds>? likedUsersForPostIds;
    if (event.userId == event.currentUser.user.id || userFollowStatus.isCurrentUserFollowingOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);
    }
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds
    ));
  }

  void _requestToFollowUser(RequestToFollowUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.requestToFollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: event.userPosts,
        usersWhoLikedPosts: event.usersWhoLikedPosts,
    ));
  }

  void _unfollowUser(UnfollowUser event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.unfollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: event.userPosts,
        usersWhoLikedPosts: event.usersWhoLikedPosts,
    ));
  }

  void _removeUserFromCurrentUserFollowers(RemoveUserFromCurrentUserFollowers event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.removeFollowingUser(event.currentUser.user.id, event.targetUserId, accessToken!);
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: event.userPosts,
        usersWhoLikedPosts: event.usersWhoLikedPosts,
    ));
  }

  void _applyUserDecisionToFollowRequest(ApplyUserDecisionToFollowRequest event, Emitter<UserProfileState> emit) async {
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await userRepository.applyUserDecisionToFollowRequest(
        event.targetUserId,
        event.currentUser.user.id,
        event.isFollowRequestApproved,
        accessToken!
    );
    final userFollowStatus =
    await userRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: event.userPosts,
        usersWhoLikedPosts: event.usersWhoLikedPosts,
    ));
  }
}
