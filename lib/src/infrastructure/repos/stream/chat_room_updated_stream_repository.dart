import 'dart:async';

import 'package:flutter_app/src/models/websocket/user_room_updated_payload.dart';

/// For more information on streaming repositories, refer to
/// https://bloclibrary.dev/#/architecture?id=connecting-blocs-through-domain
class ChatRoomUpdatedStreamRepository {

  final _controller = StreamController<UserRoomUpdatedPayload>.broadcast();

  Stream<UserRoomUpdatedPayload> get nextPayload async* {
    yield* _controller.stream;
  }

  void newPayload(UserRoomUpdatedPayload user) => _controller.add(user);
}