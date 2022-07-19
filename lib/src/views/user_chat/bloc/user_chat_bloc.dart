import 'dart:convert';

import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/chats/chat_message.dart';
import 'package:flutter_app/src/models/websocket/shout_payload.dart';
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

  UserChatBloc({
    required this.chatRepository,
    required this.secureStorage,
  }) : super(const UserChatStateInitial()) {
    on<ConnectWebsocketAndFetchHistoricalChats>(_fetchHistoricalChats);
    on<AddMessageToChatRoom>(_addMessageToChatRoom);
    on<UpdateIncomingMessageIntoChatRoom>(_updateIncomingMessageIntoChatRoom);
  }

  _initializeWebsocketConnections(String roomId, String currentUserId) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // todo - use wss instead of ws
    _chatRoomChannel = WebSocketChannel.connect(
      Uri.parse('ws://api.vid.app/api/chat/socket/websocket?token=${accessToken!}'),
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
          add(UpdateIncomingMessageIntoChatRoom(userId: shoutPayload.userId, text: shoutPayload.body));
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

  // todo - this is untested
  void _addMessageToChatRoom(AddMessageToChatRoom event, Emitter<UserChatState> emit) async {
    _chatRoomChannel.sink.add(jsonEncode({
      "topic": "chat_room:${event.roomId}",
      "event": "shout",
      "payload": {
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

  void dispose() {
    _chatRoomChannel.sink.close();
  }
}