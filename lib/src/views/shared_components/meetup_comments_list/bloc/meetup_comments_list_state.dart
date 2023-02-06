import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/meetups/meetup_comment.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:uuid/uuid.dart';

abstract class MeetupCommentsListState extends Equatable {
  const MeetupCommentsListState();
}

class MeetupCommentsListStateInitial extends MeetupCommentsListState {
  const MeetupCommentsListStateInitial();

  @override
  List<Object> get props => [];
}

class MeetupCommentsLoading extends MeetupCommentsListState {
  final String userId;

  const MeetupCommentsLoading({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MeetupCommentsLoaded extends MeetupCommentsListState {
  final uuid = const Uuid();
  final String meetupId;
  final List<MeetupComment> comments;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const MeetupCommentsLoaded({
    required this.meetupId,
    required this.comments,
    required this.userIdProfileMap
  });

  MeetupCommentsLoaded copyWithNewCommentAdded({
    required String userId,
    required String newComment
  }) {
    final now = DateTime.now().toUtc();
    comments.add(MeetupComment(meetupId, uuid.v4(), userId, newComment, now, now));
    return MeetupCommentsLoaded(
        meetupId: meetupId,
        userIdProfileMap: userIdProfileMap,
        comments: comments
    );
  }

  @override
  List<Object> get props => [meetupId, comments, userIdProfileMap];
}