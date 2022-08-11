import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class ChatSearchState extends Equatable {
  const ChatSearchState();

  @override
  List<Object?> get props => [];
}

class ChatSearchStateInitial extends ChatSearchState {

  const ChatSearchStateInitial();

  @override
  List<Object> get props => [];
}

class ChatSearchResultsLoading extends ChatSearchState {
  final String query;

  const ChatSearchResultsLoading({required this.query});

  @override
  List<Object> get props => [query];
}

class ChatSearchResultsLoaded extends ChatSearchState {
  final String query;
  final List<PublicUserProfile> userData;
  final bool doesNextPageExist;

  const ChatSearchResultsLoaded({
    required this.query,
    required this.userData,
    required this.doesNextPageExist,
  });

  @override
  List<Object?> get props => [query, userData, doesNextPageExist];
}

class ChatSearchResultsError extends ChatSearchState {
  final String query;
  final String error;

  const ChatSearchResultsError({required this.query, required this.error});

  @override
  List<Object> get props => [query, error];
}

class GoToUserChatView extends ChatSearchState {
  final String roomId;
  final PublicUserProfile targetUserProfile;

  const GoToUserChatView({required this.roomId, required this.targetUserProfile});

  @override
  List<Object?> get props => [roomId, targetUserProfile];
}

class TargetUserChatNotEnabled extends ChatSearchState {

  const TargetUserChatNotEnabled();

  @override
  List<Object?> get props => [];
}