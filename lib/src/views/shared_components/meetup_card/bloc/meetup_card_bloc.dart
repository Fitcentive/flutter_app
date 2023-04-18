import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/bloc/meetup_card_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/bloc/meetup_card_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class MeetupCardBloc extends Bloc<MeetupCardEvent, MeetupCardState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final ChatRepository chatRepository;

  Uuid uuid = const Uuid();

  MeetupCardBloc({
    required this.chatRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const MeetupCardStateInitial()) {
    on<CreateChatRoomForMeetup>(_createChatRoomForMeetup);
    on<GetDirectMessagePrivateChatRoomForMeetup>(_getDirectMessagePrivateChatRoomForMeetup);
  }

  void _getDirectMessagePrivateChatRoomForMeetup(GetDirectMessagePrivateChatRoomForMeetup event, Emitter<MeetupCardState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final chatRoom = await chatRepository.getChatRoomForPrivateConversation(event.participants.where((element) => element != event.currentUserProfileId).first, accessToken!);
    emit(MeetupChatRoomCreated(chatRoomId: chatRoom.id, randomId: uuid.v4()));
  }

  void _createChatRoomForMeetup(CreateChatRoomForMeetup event, Emitter<MeetupCardState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final chatRoom = await chatRepository.getChatRoomForGroupConversationWithName(event.participants, event.roomName, accessToken!);
    final updatedMeetup = MeetupUpdate(
      meetupType: event.meetup.meetupType,
      name: event.meetup.name,
      time: event.meetup.time,
      locationId: event.meetup.locationId,
      durationInMinutes: event.meetup.durationInMinutes,
      chatRoomId: chatRoom.id,
    );
    await meetupRepository.updateMeetup(event.meetup.id, updatedMeetup, accessToken);

    emit(MeetupChatRoomCreated(chatRoomId: chatRoom.id, randomId: uuid.v4()));
  }
}