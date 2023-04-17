import 'package:equatable/equatable.dart';

abstract class SelectChatUsersState extends Equatable {
  const SelectChatUsersState();

  @override
  List<Object?> get props => [];
}

class SelectChatUsersStateInitial extends SelectChatUsersState {

  const SelectChatUsersStateInitial();
}