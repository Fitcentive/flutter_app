import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class ChatSearchEvent extends Equatable {
  const ChatSearchEvent();

  @override
  List<Object?> get props => [];
}

class ChatParticipantsChanged extends ChatSearchEvent {
  final PublicUserProfile currentUserProfile;
  final List<String> participantUserIds;

  const ChatParticipantsChanged({
    required this.currentUserProfile,
    required this.participantUserIds,
  });

  @override
  List<Object?> get props => [currentUserProfile, participantUserIds];
}

class GetChatRoom extends ChatSearchEvent {
  final List<PublicUserProfile> targetUserProfiles;

  const GetChatRoom({required this.targetUserProfiles});

  @override
  List<Object> get props => [targetUserProfiles];
}