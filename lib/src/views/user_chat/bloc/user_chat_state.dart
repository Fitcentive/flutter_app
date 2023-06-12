import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/chats/chat_message.dart';
import 'package:flutter_app/src/models/chats/chat_room_admin.dart';
import 'package:flutter_app/src/models/chats/detailed_chat_room.dart';
import 'package:flutter_app/src/models/chats/user_last_seen.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();

  @override
  List<Object?> get props => [];
}

class UserChatStateInitial extends UserChatState {
  const UserChatStateInitial();

  @override
  List<Object?> get props => [];
}

class HistoricalChatsLoading extends UserChatState {

  const HistoricalChatsLoading();

  @override
  List<Object?> get props => [];

}

class HistoricalChatsFetched extends UserChatState {
  final String roomId;
  final List<ChatMessage> messages;
  final bool doesNextPageExist;
  final DetailedChatRoom currentChatRoom;

  // includes only userProfiles of those in the chat room
  final List<PublicUserProfile> chatRoomUserProfiles;

  // includes ALL userProfiles, including currentUserProfile and previous chat room users who have sent messages
  final List<PublicUserProfile> allMessagingUserProfiles;

  final List<ChatRoomAdmin> roomAdmins;

  final Meetup? associatedMeetup;

  final UserLastSeen? userLastSeen;

  const HistoricalChatsFetched({
    required this.roomId,
    required this.messages,
    required this.doesNextPageExist,
    required this.currentChatRoom,
    required this.chatRoomUserProfiles,
    required this.allMessagingUserProfiles,
    required this.associatedMeetup,
    required this.userLastSeen,
    required this.roomAdmins,
  });

  @override
  List<Object?> get props => [
    roomId,
    messages,
    doesNextPageExist,
    currentChatRoom,
    allMessagingUserProfiles,
    chatRoomUserProfiles,
    associatedMeetup,
    userLastSeen,
    roomAdmins,
  ];
}