import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/views/select_chat_users/bloc/select_chat_users_event.dart';
import 'package:flutter_app/src/views/select_chat_users/bloc/select_chat_users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectChatUsersBloc extends Bloc<SelectChatUsersEvent, SelectChatUsersState> {
  final FlutterSecureStorage secureStorage;
  final ChatRepository chatRepository;

  SelectChatUsersBloc({
    required this.chatRepository,
    required this.secureStorage,
  }) : super(const SelectChatUsersStateInitial()) {
  }

}