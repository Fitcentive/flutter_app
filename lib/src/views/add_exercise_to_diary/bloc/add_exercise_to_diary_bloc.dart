import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_event.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddExerciseToDiaryBloc extends Bloc<AddExerciseToDiaryEvent, AddExerciseToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  AddExerciseToDiaryBloc({
    required this.diaryRepository,
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const AddExerciseToDiaryStateInitial()) {
    on<AddCardioEntryToDiary>(_addCardioEntryToDiary);
    on<AddStrengthEntryToDiary>(_addStrengthEntryToDiary);
  }


  void _addStrengthEntryToDiary(AddStrengthEntryToDiary event, Emitter<AddExerciseToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final entry = await diaryRepository.addStrengthEntryToUserDiary(event.userId, event.newEntry, accessToken!);

    if (event.associatedMeetupId != null) {
      await meetupRepository.upsertStrengthDiaryEntryToMeetup(event.associatedMeetupId!, entry.id, accessToken);
    }
    userRepository.trackUserEvent(CreateExerciseDiaryEntry(), accessToken);
    emit(const ExerciseDiaryEntryAdded());
  }

  void _addCardioEntryToDiary(AddCardioEntryToDiary event, Emitter<AddExerciseToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final entry = await diaryRepository.addCardioEntryToUserDiary(event.userId, event.newEntry, accessToken!);

    if (event.associatedMeetupId != null) {
      await meetupRepository.upsertCardioDiaryEntryToMeetup(event.associatedMeetupId!, entry.id, accessToken);
    }
    userRepository.trackUserEvent(CreateExerciseDiaryEntry(), accessToken);
    emit(const ExerciseDiaryEntryAdded());
  }
}