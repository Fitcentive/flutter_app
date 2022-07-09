import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';

abstract class NewsFeedEvent extends Equatable {
  const NewsFeedEvent();
}

class NewsFeedFetchRequested extends NewsFeedEvent {
  final AuthenticatedUser user;

  const NewsFeedFetchRequested({required this.user});

  @override
  List<Object> get props => [user];
}