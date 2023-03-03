import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/add_to_diary/bloc/add_to_diary_event.dart';
import 'package:flutter_app/src/views/add_to_diary/bloc/add_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddToDiaryBloc extends Bloc<AddToDiaryEvent, AddToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  AddToDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const AddToDiaryStateInitial()) {
    on<AddCardioEntryToDiary>(_addCardioEntryToDiary);
    on<AddStrengthEntryToDiary>(_addStrengthEntryToDiary);
  }


  void _addStrengthEntryToDiary(AddStrengthEntryToDiary event, Emitter<AddToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addStrengthEntryToUserDiary(event.userId, event.newEntry, accessToken!);
    emit(const DiaryEntryAdded());
  }

  void _addCardioEntryToDiary(AddCardioEntryToDiary event, Emitter<AddToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addCardioEntryToUserDiary(event.userId, event.newEntry, accessToken!);
    emit(const DiaryEntryAdded());
  }
}