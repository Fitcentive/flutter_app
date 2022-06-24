import 'dart:async';

import 'package:flutter_app/src/models/authenticated_user.dart';

/// For more information on streaming repositories, refer to
/// https://bloclibrary.dev/#/architecture?id=connecting-blocs-through-domain
class AuthenticatedUserStreamRepository {

  final _controller = StreamController<AuthenticatedUser>();

  Stream<AuthenticatedUser> get authenticatedUser async* {
    yield* _controller.stream;
  }

  void newUser(AuthenticatedUser user) => _controller.add(user);
}