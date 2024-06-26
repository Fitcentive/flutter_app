import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_event.dart';
import 'package:flutter_app/src/views/selected_post/bloc/selected_post_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectedPostBloc extends Bloc<SelectedPostEvent, SelectedPostState> {
  final UserRepository userRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  SelectedPostBloc({
    required this.userRepository,
    required this.socialMediaRepository,
    required this.secureStorage,
  }) : super(const SelectedPostStateInitial()) {
    on<FetchSelectedPost>(_fetchSelectedPost);
    on<PostAlreadyProvidedByParent>(_postAlreadyProvidedByParent);
    on<UnlikePostForUser>(_unlikePostForUser);
    on<LikePostForUser>(_likePostForUser);
    on<AddNewComment>(_addNewComment);
    on<DeleteSelectedPost>(_deleteSelectedPost);
    on<FetchMoreCommentsForPost>(_fetchMoreCommentsForPost);
  }

  void _fetchMoreCommentsForPost(FetchMoreCommentsForPost event, Emitter<SelectedPostState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final currentState = state;
    if (currentState is SelectedPostLoaded) {
      final additionalComments = await socialMediaRepository.getCommentChunkForPost(
        event.postId,
        accessToken!,
        event.skip,
        ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT,
      );
      final doMoreCommentsExist = additionalComments.length == ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT ? true : false;
      final distinctUserIdsFromPosts = _getRelevantUserIdsFromComments(additionalComments, event.currentUserId, event.currentUserId);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      emit(SelectedPostLoaded(
        post: currentState.post,
        comments: [...List.from(additionalComments.reversed), ...currentState.comments],
        postWithLikedUserIds: currentState.postWithLikedUserIds,
        userProfileMap: {...currentState.userProfileMap, ...userIdProfileMap},
        doMoreCommentsExist: doMoreCommentsExist,
      ));
    }
  }

  void _deleteSelectedPost(DeleteSelectedPost event, Emitter<SelectedPostState> emit) async {
    emit(const SelectedPostBeingDeleted());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.deletePostForUser(event.postId, event.currentUserId, accessToken!);
    userRepository.trackUserEvent(UserDeletedSocialPost(), accessToken);
    emit(const SelectedPostDeleted());
  }

  void _addNewComment(AddNewComment event, Emitter<SelectedPostState> emit) async {
    final currentState = state;
    if (currentState is SelectedPostLoaded) {
      emit(const SelectedPostLoading());
      emit(currentState.copyWithNewCommentAdded(newComment: event.comment, userId: event.userId));
    }

    if (!event.isMockDataMode) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await socialMediaRepository.addCommentToPost(event.postId, event.userId, event.comment, accessToken!);
      userRepository.trackUserEvent(AddSocialPostComment(), accessToken);
    }
  }

  void _unlikePostForUser(UnlikePostForUser event, Emitter<SelectedPostState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.unlikePostForUser(event.postId, event.currentUserId, accessToken!);
  }

  void _likePostForUser(LikePostForUser event, Emitter<SelectedPostState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.likePostForUser(event.postId, event.currentUserId, accessToken!);
    userRepository.trackUserEvent(LikeSocialPost(), accessToken);
  }

  // We reload comments async to be up to date
  // Not only that, parent provided post could only contain preview of comments, we need to fetch all comments here
  void _postAlreadyProvidedByParent(PostAlreadyProvidedByParent event, Emitter<SelectedPostState> emit) async {
    emit(SelectedPostLoaded(
        post: event.currentPost,
        comments: event.currentPostComments,
        postWithLikedUserIds: event.likedUsersForCurrentPost,
        userProfileMap: event.userIdProfileMap,
        doMoreCommentsExist: true
    ));

    if (!event.isMockDataMode) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final postComments = await socialMediaRepository.getCommentChunkForPost(
          event.currentPost.postId,
          accessToken!,
          0,
          ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT,
      );
      final doMoreCommentsExist = postComments.length == ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT ? true : false;
      final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds([event.currentPost.postId], accessToken);
      final distinctUserIdsFromPosts = _getRelevantUserIdsFromComments(postComments, event.currentUserId, event.currentPost.userId);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
      emit(SelectedPostLoaded(
          post: event.currentPost,
          comments: List.from(postComments.reversed),
          postWithLikedUserIds: likedUsersForPostIds.first,
          userProfileMap: userIdProfileMap,
          doMoreCommentsExist: doMoreCommentsExist,
      ));
    }
  }

  void _fetchSelectedPost(FetchSelectedPost event, Emitter<SelectedPostState> emit) async {
    emit(const SelectedPostLoading());

    if (!event.isMockDataMode) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final fetchedPost = await socialMediaRepository.getPostById(event.postId, accessToken!);
      final postComments = await socialMediaRepository.getCommentChunkForPost(
        event.postId,
        accessToken,
        0,
        ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT,
      );
      final likedUsersForPostIds = await socialMediaRepository.getPostsWithLikedUserIds([event.postId], accessToken);

      final distinctUserIdsFromPosts = _getRelevantUserIdsFromComments(postComments, event.currentUserId, fetchedPost.userId);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromPosts, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final doMoreCommentsExist = postComments.length == ConstantUtils.DEFAULT_SELECTED_POST_COMMENTS_FETCHED_LIMIT ? true : false;

      emit(SelectedPostLoaded(
          post: fetchedPost,
          comments: List.from(postComments.reversed),
          postWithLikedUserIds: likedUsersForPostIds.first, // should only be of size 1
          userProfileMap: userIdProfileMap,
          doMoreCommentsExist: doMoreCommentsExist
      ));
    }

  }

  List<String> _getRelevantUserIdsFromComments(
      List<SocialPostComment> comments,
      String currentUserId,
      String postCreatorId
  ) {
    final commenters = comments
        .map((e) => e.userId)
        .toSet();
    commenters.add(currentUserId);
    commenters.add(postCreatorId);
    return commenters.toList();
  }
}
