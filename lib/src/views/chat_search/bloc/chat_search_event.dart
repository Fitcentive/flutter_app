import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class ChatSearchEvent extends Equatable {
  const ChatSearchEvent();

  @override
  List<Object?> get props => [];
}

class ChatSearchQueryChanged extends ChatSearchEvent {
  final String query;

  const ChatSearchQueryChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

class GetChatRoom extends ChatSearchEvent {
  final PublicUserProfile targetUserProfile;

  const GetChatRoom({required this.targetUserProfile});

  @override
  List<Object> get props => [targetUserProfile];
}