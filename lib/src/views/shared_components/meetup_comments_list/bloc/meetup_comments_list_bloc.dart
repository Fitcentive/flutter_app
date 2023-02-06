import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_comment.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_event.dart';
import 'package:flutter_app/src/views/shared_components/meetup_comments_list/bloc/meetup_comments_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MeetupCommentsListBloc extends Bloc<MeetupCommentsListEvent, MeetupCommentsListState> {
  final UserRepository userRepository;
  final MeetupRepository meetupRepository;
  final FlutterSecureStorage secureStorage;

  MeetupCommentsListBloc({
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage
  }): super(const MeetupCommentsListStateInitial()) {
    on<FetchMeetupCommentsRequested>(_fetchMeetupCommentsRequested);
    on<AddNewMeetupComment>(_addNewMeetupComment);
  }

  void _addNewMeetupComment(AddNewMeetupComment event, Emitter<MeetupCommentsListState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.createMeetupComment(event.meetupId, event.comment, accessToken!);
    final currentState = state;
    if (currentState is MeetupCommentsLoaded) {
      emit(MeetupCommentsLoading(userId: event.userId));
      emit(currentState.copyWithNewCommentAdded(newComment: event.comment, userId: event.userId));
    }
  }

  void _fetchMeetupCommentsRequested(FetchMeetupCommentsRequested event, Emitter<MeetupCommentsListState> emit) async {
    emit(MeetupCommentsLoading(userId: event.meetupId));
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final comments = await meetupRepository.getMeetupComments(event.meetupId, accessToken!);

    final List<String> userIdsFromNotificationSources = _getDistinctUserIds(comments, event.currentUserId);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(userIdsFromNotificationSources, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
    emit(MeetupCommentsLoaded(meetupId: event.meetupId, comments: comments, userIdProfileMap: userIdProfileMap));
  }

  List<String> _getDistinctUserIds(List<MeetupComment> comments, String currentUserId) {
    final userIdSet =  comments
        .map((e) => e.userId)
        .toSet();
    userIdSet.add(currentUserId);
    return userIdSet.toList();
  }
}