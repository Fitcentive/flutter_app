import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_event.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddExerciseToDiaryBloc extends Bloc<AddExerciseToDiaryEvent, AddExerciseToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  AddExerciseToDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const AddExerciseToDiaryStateInitial()) {
    on<AddCardioEntryToDiary>(_addCardioEntryToDiary);
    on<AddStrengthEntryToDiary>(_addStrengthEntryToDiary);
  }


  void _addStrengthEntryToDiary(AddStrengthEntryToDiary event, Emitter<AddExerciseToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addStrengthEntryToUserDiary(event.userId, event.newEntry, accessToken!);
    emit(const ExerciseDiaryEntryAdded());
  }

  void _addCardioEntryToDiary(AddCardioEntryToDiary event, Emitter<AddExerciseToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addCardioEntryToUserDiary(event.userId, event.newEntry, accessToken!);
    emit(const ExerciseDiaryEntryAdded());
  }
}