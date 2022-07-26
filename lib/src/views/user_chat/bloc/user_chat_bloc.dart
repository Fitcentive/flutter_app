import 'dart:convert';

import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_message.dart';
import 'package:flutter_app/src/models/websocket/shout_payload.dart';
import 'package:flutter_app/src/models/websocket/typing_started_payload.dart';
import 'package:flutter_app/src/models/websocket/typing_stopped_payload.dart';
import 'package:flutter_app/src/models/websocket/web_socket_event.dart';
import 'package:flutter_app/src/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_event.dart';
import 'package:flutter_app/src/views/user_chat/bloc/user_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UserChatBloc extends Bloc<UserChatEvent, UserChatState> {

  final ChatRepository chatRepository;
  final FlutterSecureStorage secureStorage;
  late final WebSocketChannel _chatRoomChannel;

  final joinRef = const Uuid().v4();
  final userTypingMessageId = const Uuid().v4();

  UserChatBloc({
    required this.chatRepository,
    required this.secureStorage,
  }) : super(const UserChatStateInitial()) {
    on<ConnectWebsocketAndFetchHistoricalChats>(_fetchHistoricalChats);
    on<AddMessageToChatRoom>(_addMessageToChatRoom);
    on<UpdateIncomingMessageIntoChatRoom>(_updateIncomingMessageIntoChatRoom);
    on<CurrentUserTypingStarted>(_currentUserTypingStarted);
    on<CurrentUserTypingStopped>(_currentUserTypingStopped);
    on<OtherUserTypingStarted>(_otherUserTypingStarted);
    on<OtherUserTypingStopped>(_otherUserTypingStopped);
  }

  _initializeWebsocketConnections(String roomId, String currentUserId) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // wss works because we allow for unverified certificates in development mode
    _chatRoomChannel = WebSocketChannel.connect(
      Uri.parse('wss://api.vid.app/api/chat/socket/websocket?token=${accessToken!}'),
    );

    _chatRoomChannel.sink.add(jsonEncode({
      "topic": "chat_room:$roomId",
      "event": "phx_join",
      "payload": {
        "user_id": currentUserId
      },
      "join_ref": joinRef,
      "ref": const Uuid().v4()
    }));

    _chatRoomChannel.stream.listen((event) {
      final decodedJson = jsonDecode(event);
      final websocketEvent = WebsocketEvent.fromJson(decodedJson);

      switch (websocketEvent.event) {
        case "phx_join":
          break;

        case "shout":
          final Map<String, dynamic> decodedShoutJson = jsonDecode(jsonEncode(websocketEvent.payload));
          final shoutPayload = ShoutPayload.fromJson(decodedShoutJson);
          if (shoutPayload.userId != currentUserId) {
            add(UpdateIncomingMessageIntoChatRoom(userId: shoutPayload.userId, text: shoutPayload.body));
          }
          break;

        case "typing_started":
          final Map<String, dynamic> decodedJson = jsonDecode(jsonEncode(websocketEvent.payload));
          final payload =  TypingStartedPayload.fromJson(decodedJson);
          if (payload.userId != currentUserId) {
            add(OtherUserTypingStarted(payload.userId));
          }
          break;

        case "typing_stopped":
          final Map<String, dynamic> decodedJson = jsonDecode(jsonEncode(websocketEvent.payload));
          final payload =  TypingStoppedPayload.fromJson(decodedJson);
          if (payload.userId != currentUserId) {
            add(OtherUserTypingStopped(payload.userId));
          }
          break;

        default:
            break;
      }
    });
  }

  void _fetchHistoricalChats(ConnectWebsocketAndFetchHistoricalChats event, Emitter<UserChatState> emit) async {
    emit(const HistoricalChatsLoading());

    _initializeWebsocketConnections(event.roomId, event.currentUserId);
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final chatMessages = (await chatRepository.getMessagesForRoom(event.roomId, accessToken!))
        .map((chatMessage) => chatMessage.copyWithLocalTime())
        .toList();

    emit(HistoricalChatsFetched(roomId: event.roomId, messages: chatMessages));
  }

  void _addCurrentUserStartedTypingEventToChannel(String roomId, String userId) {
    _chatRoomChannel.sink.add(jsonEncode({
      "topic": "chat_room:$roomId",
      "event": "typing_started",
      "payload": {
        "user_id": userId,
      },
      "join_ref": joinRef,
      "ref": const Uuid().v4()
    }));
  }

  void _addCurrentUserStoppedTypingEventToChannel(String roomId, String userId) {
    _chatRoomChannel.sink.add(jsonEncode({
      "topic": "chat_room:$roomId",
      "event": "typing_stopped",
      "payload": {
        "user_id": userId,
      },
      "join_ref": joinRef,
      "ref": const Uuid().v4()
    }));
  }

  void _addMessageToChatRoom(AddMessageToChatRoom event, Emitter<UserChatState> emit) async {
    _addCurrentUserStoppedTypingEventToChannel(event.roomId, event.userId);
    _chatRoomChannel.sink.add(jsonEncode({
      "topic": "chat_room:${event.roomId}",
      "event": "shout",
      "payload": {
        "user_id": event.userId,
        "body": event.text
      },
      "join_ref": joinRef,
      "ref": const Uuid().v4()
    }));
  }

  void _updateIncomingMessageIntoChatRoom(UpdateIncomingMessageIntoChatRoom event, Emitter<UserChatState> emit) async {
    final currentState = state;
    if (currentState is HistoricalChatsFetched) {
      final updatedMessages = currentState.messages;
      final now = DateTime.now();
      updatedMessages.insert(0,
          ChatMessage(
              const Uuid().v4(),
              event.userId,
              currentState.roomId,
              event.text,
              null,
              now,
              now
          )
      );
      emit(const HistoricalChatsLoading());
      emit(HistoricalChatsFetched(roomId: currentState.roomId, messages: updatedMessages));
    }
  }

  void _otherUserTypingStarted(OtherUserTypingStarted event, Emitter<UserChatState> emit) async {
    final currentState = state;
    if (currentState is HistoricalChatsFetched) {
      final updatedMessages = currentState.messages;
      final now = DateTime.now();
      // todo - typing indicator feature is in PR - https://github.com/flyerhq/flutter_chat_ui/pull/293
      updatedMessages.insert(0,
          ChatMessage(
              userTypingMessageId,
              event.userId,
              currentState.roomId,
              "...",
              null,
              now,
              now
          )
      );
      emit(const HistoricalChatsLoading());
      emit(HistoricalChatsFetched(roomId: currentState.roomId, messages: updatedMessages));
    }
  }

  void _otherUserTypingStopped(OtherUserTypingStopped event, Emitter<UserChatState> emit) async {
    final currentState = state;
    if (currentState is HistoricalChatsFetched) {
      final updatedMessages = currentState.messages;
      updatedMessages.removeWhere((element) => element.id == userTypingMessageId);
      emit(const HistoricalChatsLoading());
      emit(HistoricalChatsFetched(roomId: currentState.roomId, messages: updatedMessages));
    }
  }

  void _currentUserTypingStarted(CurrentUserTypingStarted event, Emitter<UserChatState> emit) async {
    _addCurrentUserStartedTypingEventToChannel(event.roomId, event.userId);
  }

  void _currentUserTypingStopped(CurrentUserTypingStopped event, Emitter<UserChatState> emit) async {
    _addCurrentUserStoppedTypingEventToChannel(event.roomId, event.userId);
  }

  void dispose() {
    _chatRoomChannel.sink.close();
  }
}