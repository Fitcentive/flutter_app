import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/social/posts_with_liked_user_ids.dart';
import 'package:flutter_app/src/models/social/social_post.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/user_follow_status.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_event.dart';
import 'package:flutter_app/src/views/user_profile/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    on<RequestToFollowUser>(_requestToFollowUser);
    on<UnfollowUser>(_unfollowUser);
    on<UnlikePostForUser>(_unlikePostForUser);
    on<LikePostForUser>(_likePostForUser);
    on<RemoveUserFromCurrentUserFollowers>(_removeOtherUserFromCurrentUserFollowers);
    on<ApplyUserDecisionToFollowRequest>(_applyUserDecisionToFollowRequest);
    on<GetChatRoom>(_getChatRoom);
  }

  void _getChatRoom(GetChatRoom event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      if (currentState.chatRoomId == null) {

        try {
          final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
          final chatRoom = await chatRepository.getChatRoomForConversation(event.targetUserId, accessToken!);

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
      if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFollowingOtherUser) {
        userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
        final postIds = userPosts.map((e) => e.postId).toList();
        likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);
      }
      final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
      emit(RequiredDataResolved(
        userFollowStatus: event.userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
        selectedPostId: null,
        chatRoomId: null,
        doesNextPageExist: doesNextPageExist,
      ));
    }

    else if (currentState is RequiredDataResolved && currentState.doesNextPageExist) {
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      List<SocialPost>? userPosts;
      List<PostsWithLikedUserIds>? likedUsersForPostIds;
      bool doesNextPageExist = false;
      if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFollowingOtherUser) {
        final fetchedPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
        final postIds = fetchedPosts.map((e) => e.postId).toList();
        final fetchedLikedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);

        userPosts = [...currentState.userPosts!, ...fetchedPosts];
        likedUsersForPostIds = [...currentState.usersWhoLikedPosts!, ...fetchedLikedUsersForPostIds];
        doesNextPageExist = fetchedPosts.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
      }

      emit(RequiredDataResolved(
        userFollowStatus: event.userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
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
    if (event.userId == event.currentUser.user.id || event.userFollowStatus.isCurrentUserFollowingOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken!, event.createdBefore, event.limit);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);
    }
    final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
    emit(RequiredDataResolved(
      userFollowStatus: event.userFollowStatus,
      currentUser: event.currentUser,
      userPosts: userPosts,
      usersWhoLikedPosts: likedUsersForPostIds,
      selectedPostId: null,
      chatRoomId: null,
      doesNextPageExist: doesNextPageExist,
    ));
  }

  void _fetchRequiredData(FetchRequiredData event, Emitter<UserProfileState> emit) async {
    emit(const DataLoading());
    final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final userFollowStatus =
        await socialMediaRepository.getUserFollowStatus(event.currentUser.user.id, event.userId, accessToken!);

    List<SocialPost>? userPosts;
    List<PostsWithLikedUserIds>? likedUsersForPostIds;
    if (event.userId == event.currentUser.user.id || userFollowStatus.isCurrentUserFollowingOtherUser) {
      userPosts = await socialMediaRepository.getPostsForUser(event.userId, accessToken, event.createdBefore, event.limit);
      final postIds = userPosts.map((e) => e.postId).toList();
      likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds(postIds, accessToken);
    }
    final doesNextPageExist = userPosts?.length == ConstantUtils.DEFAULT_NEWSFEED_LIMIT ? true : false;
    emit(RequiredDataResolved(
        userFollowStatus: userFollowStatus,
        currentUser: event.currentUser,
        userPosts: userPosts,
        usersWhoLikedPosts: likedUsersForPostIds,
        selectedPostId: null,
        chatRoomId: null,
        doesNextPageExist: doesNextPageExist,
    ));
  }

  void _requestToFollowUser(RequestToFollowUser event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFollowStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          event.userFollowStatus.isCurrentUserFollowingOtherUser,
          event.userFollowStatus.isOtherUserFollowingCurrentUser,
          true,
          event.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.requestToFollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
      final userFollowStatus =
      await socialMediaRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }

  void _unfollowUser(UnfollowUser event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFollowStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          false,
          event.userFollowStatus.isOtherUserFollowingCurrentUser,
          event.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser,
          event.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.unfollowUser(event.currentUser.user.id, event.targetUserId, accessToken!);
      final userFollowStatus =
      await socialMediaRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }

  void _removeOtherUserFromCurrentUserFollowers(RemoveUserFromCurrentUserFollowers event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFollowStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          event.userFollowStatus.isCurrentUserFollowingOtherUser,
          false,
          event.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser,
          event.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.removeFollowingUser(event.currentUser.user.id, event.targetUserId, accessToken!);
      final userFollowStatus =
      await socialMediaRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }

  void _applyUserDecisionToFollowRequest(ApplyUserDecisionToFollowRequest event, Emitter<UserProfileState> emit) async {
    final currentState = state;
    if (currentState is RequiredDataResolved) {
      final newFollowStatus = UserFollowStatus(
          event.userFollowStatus.currentUserId,
          event.userFollowStatus.otherUserId,
          event.userFollowStatus.isCurrentUserFollowingOtherUser,
          event.isFollowRequestApproved,
          event.userFollowStatus.hasCurrentUserRequestedToFollowOtherUser,
          event.userFollowStatus.hasOtherUserRequestedToFollowCurrentUser
      );
      emit(RequiredDataResolved(
          userFollowStatus: newFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
      final accessToken = await flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.applyUserDecisionToFollowRequest(
          event.targetUserId,
          event.currentUser.user.id,
          event.isFollowRequestApproved,
          accessToken!
      );
      final userFollowStatus =
      await socialMediaRepository.getUserFollowStatus(event.currentUser.user.id, event.targetUserId, accessToken);
      emit(RequiredDataResolved(
          userFollowStatus: userFollowStatus,
          currentUser: event.currentUser,
          userPosts: event.userPosts,
          usersWhoLikedPosts: event.usersWhoLikedPosts,
          selectedPostId: null,
          chatRoomId: null,
          doesNextPageExist: currentState.doesNextPageExist
      ));
    }
  }
}
