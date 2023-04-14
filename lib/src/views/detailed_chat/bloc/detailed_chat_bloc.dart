import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_event.dart';
import 'package:flutter_app/src/views/detailed_chat/bloc/detailed_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedChatBloc extends Bloc<DetailedChatEvent, DetailedChatState> {
  final FlutterSecureStorage secureStorage;

  DetailedChatBloc({
    required this.secureStorage,
  }) : super(const DetailedChatStateInitial()) {

  }

}