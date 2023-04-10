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

class GoToUserChatView extends ChatSearchState {
  final String roomId;
  final List<PublicUserProfile> targetUserProfiles;

  const GoToUserChatView({required this.roomId, required this.targetUserProfiles});

  @override
  List<Object?> get props => [roomId, targetUserProfiles];
}

class ChatParticipantsModified extends ChatSearchState {
  final PublicUserProfile currentUserProfile;
  final List<PublicUserProfile> participantUserProfiles;

  const ChatParticipantsModified({
    required this.currentUserProfile,
    required this.participantUserProfiles,
  });

  @override
  List<Object?> get props => [currentUserProfile, participantUserProfiles];
}

class TargetUserChatNotEnabled extends ChatSearchState {

  const TargetUserChatNotEnabled();

  @override
  List<Object?> get props => [];
}