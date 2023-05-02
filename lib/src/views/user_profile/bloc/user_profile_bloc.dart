import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/models/user_friend_status.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:collection/collection.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage flutterSecureStorage;

  UserProfileBloc({
    required this.userRepository,
    required this.chatRepository,
    required this.flutterSecureStorage,
    required this.socialMediaRepository,
  }) : super(const UserProfileInitial()) {
    on<FetchRequiredData>(_fetchRequiredData);
    on<ReFetchUserPostsData>(_reFetchUserPostsData);
    on<FetchUserPostsData>(_fetchUserPostsData);
    on<RequestToFriendUser>(_requestToFriendUser);
    on<UnfriendUser>(_unfriendUser);
    on<UnlikePostForUser>(_unlikePostForUser);
    on<LikePostForUser>(_likePostForUser);
    on<ApplyUserDecisionToFriendRequest>(_applyUserDecisionToFriendRequest);
    on<GetChatRoom>(_getChatRoom);
  }

  void _getChatRoom(GetChatRoom event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      if (currentState.chatRoomId == null) {

        try {
          final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
          final chatRoom = await chatRepository.getChatRoomForPrivateConversation(event.targetUserId, accessToken!);

          emit(GoToUserChatView(roomId: chatRoom.id));
          emit(currentState.copyWith(
              newPostId: currentState.selectedPostId,
              chatRoomId: chatRoom.id,
              doesNextPageExist: currentState.doesNextPageExist,
          ));
        } catch (ex) {
          emit(const TargetUserChatNotEnabled());
          emit(currentState.copyWith(
              newPostId: currentState.selectedPostId,
              chatRoomId: currentState.chatRoomId,
              doesNextPageExist: currentState.doesNextPageExist,
          ));
        }

      }
      else {
        emit(GoToUserChatView(roomId: currentState.chatRoomId!));
        emit(currentState.copyWith(
            newPostId: currentState.selectedPostId,
            chatRoomId: currentState.chatRoomId,
            doesNextPageExist: currentState.doesNextPageExist,
        ));
      }
    }

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
    final currentState = state;
    if (currentState is UserProfileInitial) {
      emit(const DataLoading());

      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      List<SocialPost>? userPosts;
      List<PostsWithLikedUserIds>? likedUsersForPostIds;
      Map<String, List<SocialPostComment>>? postIdCommentMap;
      Map<String, PublicUserProfile>? userIdProfileMap;

      if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
        userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
        final postIds = userPosts.map((e) => e.postId).toList();
        likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

        final List<List<SocialPostComment>> postsComments =
        await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
        postIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

        final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(userPosts, postsComments);
        final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
        userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
      }
      final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
      emit(RequiredDataResolved(
        userFollowStatus: event.userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
        postIdCommentsMap: postIdCommentMap,
        userIdProfileMap: userIdProfileMap,
        selectedPostId: null,
        chatRoomId: null,
        doesNextPageExist: doesNextPageExist,
      ));
    }

    else if (currentState is RequiredDataResolved && currentState.doesNextPageExist) {
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      List<SocialPost>? userPosts;
      List<PostsWithLikedUserIds>? likedUsersForPostIds;
      Map<String, List<SocialPostComment>>? postIdCommentMap;
      Map<String, PublicUserProfile>? userIdProfileMap;
      bool doesNextPageExist = false;

      if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
        final fetchedPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
        final postIds = fetchedPosts.map((e) => e.postId).toList();
        final fetchedLikedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

        final List<List<SocialPostComment>> postsComments =
        await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
        final fetchedPostIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

        final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(fetchedPosts, postsComments);
        final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
        final newUserIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

        userPosts = [...currentState.userPosts!, ...fetchedPosts];
        likedUsersForPostIds = [...currentState.usersWhoLikedPosts!, ...fetchedLikedUsersForPostIds];
        postIdCommentMap = {...currentState.postIdCommentsMap!, ...fetchedPostIdCommentMap};
        userIdProfileMap = {...currentState.userIdProfileMap!, ...newUserIdProfileMap};
        doesNextPageExist = fetchedPosts.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
      }

      emit(RequiredDataResolved(
        userFollowStatus: event.userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
        postIdCommentsMap: postIdCommentMap,
        userIdProfileMap: userIdProfileMap,
        selectedPostId: null,
        chatRoomId: null,
        doesNextPageExist: doesNextPageExist,
      ));
    }

  }

  void _reFetchUserPostsData(ReFetchUserPostsData event, Emitter<UserProfileState> emit) async {
    emit(const DataLoading());

    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    List<SocialPost>? userPosts;
    List<PostsWithLikedUserIds>? likedUsersForPostIds;
    Map<String, List<SocialPostComment>>? postIdCommentMap;
    Map<String, PublicUserProfile>? userIdProfileMap;

    if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFriendsWithOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

      final List<List<SocialPostComment>> postsComments =
      await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
      postIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

      final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(userPosts, postsComments);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
      userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    }
    final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
    emit(RequiredDataResolved(
      userFollowStatus: event.userFollowStatus,
      currentUser: event.currentUser,
      userPosts: userPosts,
      usersWhoLikedPosts: likedUsersForPostIds,
      postIdCommentsMap: postIdCommentMap,
      userIdProfileMap: userIdProfileMap,
      selectedPostId: null,
      chatRoomId: null,
      doesNextPageExist: doesNextPageExist,
    ));
  }

  void _fetchRequiredData(FetchRequiredData event, Emitter<UserProfileState> emit) async {
    emit(const DataLoading());
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFollowStatus =
        await socialMediaRepository.getUserFriendStatus(event.currentUser.user.id, event.userId, accessToken!);

    List<SocialPost>? userPosts;
    List<PostsWithLikedUserIds>? likedUsersForPostIds;
    Map<String, List<SocialPostComment>>? postIdCommentMap;
    Map<String, PublicUserProfile>? userIdProfileMap;

    if (event.userId == event.currentUser.user.id || userFollowStatus.isCurrentUserFriendsWithOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken, event.createdBefore, event.limit);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

      final List<List<SocialPostComment>> postsComments =
      await Future.wait(postIds.map((p) => socialMediaRepository.getCommentsForPost(p, accessToken)));
      postIdCommentMap = { for (var e in IterableZip([postIds, postsComments])) e[0] as String : e[1] as List<SocialPostComment> };

      final distinctUserIdsFromPostsAndComments = _getRelevantUserIdsFromPostsAndComments(userPosts, postsComments);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPostsAndComments, accessToken);
      userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    }
    final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
        postIdCommentsMap: postIdCommentMap,
        userIdProfileMap: userIdProfileMap,
        selectedPostId: null,
        chatRoomId: null,
        doesNextPageExist: doesNextPageExist,
    ));
  }

  void _requestToFriendUser(RequestToFriendUser event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFriendStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          event.userFollowStatus.isCurrentUserFriendsWithOtherUser,
          true,
          event.userFollowStatus.hasOtherUserRequestedToFriendCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          postIdCommentsMap: currentState.postIdCommentsMap,
          userIdProfileMap: currentState.userIdProfileMap,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.requestToFriendUser(event.currentUser.user.id, event.targetUserId, accessToken!);
      final userFollowStatus =
      await socialMediaRepository.getUserFriendStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          postIdCommentsMap: currentState.postIdCommentsMap,
          userIdProfileMap: currentState.userIdProfileMap,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }

  void _unfriendUser(UnfriendUser event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFriendStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          false,
          event.userFollowStatus.hasCurrentUserRequestedToFriendOtherUser,
          event.userFollowStatus.hasOtherUserRequestedToFriendCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          postIdCommentsMap: currentState.postIdCommentsMap,
          userIdProfileMap: currentState.userIdProfileMap,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.unfriendUser(event.currentUser.user.id, event.targetUserId, accessToken!);
      final userFollowStatus =
      await socialMediaRepository.getUserFriendStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          postIdCommentsMap: currentState.postIdCommentsMap,
          userIdProfileMap: currentState.userIdProfileMap,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }

  void _applyUserDecisionToFriendRequest(ApplyUserDecisionToFriendRequest event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.applyUserDecisionToFriendRequest(
          event.targetUserId,
          event.currentUser.user.id,
          event.isFollowRequestApproved,
          accessToken!
      );
      final userFollowStatus =
      await socialMediaRepository.getUserFriendStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          postIdCommentsMap: currentState.postIdCommentsMap,
          userIdProfileMap: currentState.userIdProfileMap,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
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
