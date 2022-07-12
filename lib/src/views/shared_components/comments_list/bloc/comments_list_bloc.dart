import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/social/social_post_comment.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/comments_list/bloc/comments_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommentsListBloc extends Bloc<CommentsListEvent, CommentsListState> {
  final UserRepository userRepository;
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  CommentsListBloc({
    required this.userRepository,
    required this.socialMediaRepository,
    required this.secureStorage
  }): super(const CommentsListStateInitial()) {
    on<FetchCommentsRequested>(_fetchCommentsRequested);
    on<AddNewComment>(_addNewComment);
  }

  void _addNewComment(AddNewComment event, Emitter<CommentsListState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await socialMediaRepository.addCommentToPost(event.postId, event.userId, event.comment, accessToken!);
    emit(CommentsLoading(userId: event.postId));

    final comments = await socialMediaRepository.getCommentsForPost(event.postId, accessToken);
    final List<String> userIdsFromNotificationSources = _getDistinctUserIds(comments);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    emit(CommentsLoaded(userId: event.postId, comments: comments, userIdProfileMap: userIdProfileMap));
  }

  void _fetchCommentsRequested(FetchCommentsRequested event, Emitter<CommentsListState> emit) async {
    emit(CommentsLoading(userId: event.postId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final comments = await socialMediaRepository.getCommentsForPost(event.postId, accessToken!);

    final List<String> userIdsFromNotificationSources = _getDistinctUserIds(comments);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    emit(CommentsLoaded(userId: event.postId, comments: comments, userIdProfileMap: userIdProfileMap));
  }

  List<String> _getDistinctUserIds(List<SocialPostComment> comments) {
    return comments
        .map((e) => e.userId)
        .toSet()
        .toList();
  }
}