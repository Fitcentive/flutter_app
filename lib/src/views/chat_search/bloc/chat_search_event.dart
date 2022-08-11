import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class ChatSearchEvent extends Equatable {
  const ChatSearchEvent();

  @override
  List<Object?> get props => [];
}

class ChatSearchQueryChanged extends ChatSearchEvent {
  final String query;
  final int limit;
  final int offset;

  const ChatSearchQueryChanged({
    required this.query,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object?> get props => [query, limit, offset];
}

class FetchMoreResultsForSameQuery extends ChatSearchEvent {
  final String query;
  final int limit;
  final int offset;

  const FetchMoreResultsForSameQuery({
    required this.query,
    required this.limit,
    required this.offset,
  });

  @override
  List<Object?> get props => [query, limit, offset];
}

class GetChatRoom extends ChatSearchEvent {
  final PublicUserProfile targetUserProfile;

  const GetChatRoom({required this.targetUserProfile});

  @override
  List<Object> get props => [targetUserProfile];
}