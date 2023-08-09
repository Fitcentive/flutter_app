import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_event.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddFoodToDiaryBloc extends Bloc<AddFoodToDiaryEvent, AddFoodToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  AddFoodToDiaryBloc({
    required this.diaryRepository,
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const AddToFoodDiaryStateInitial()) {
    on<AddFoodEntryToDiary>(_addFoodEntryToDiary);
  }


  void _addFoodEntryToDiary(AddFoodEntryToDiary event, Emitter<AddFoodToDiaryState> emit) async {
    emit(const FoodDiaryEntryBeingAdded());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final entry = await diaryRepository.addFoodEntryToUserDiary(event.userId, event.newEntry, accessToken!);

    if (event.associatedMeetupId != null) {
      await meetupRepository.upsertFoodDiaryEntryToMeetup(event.associatedMeetupId!, entry.id, accessToken);
    }

    userRepository.trackUserEvent(CreateFoodDiaryEntry(), accessToken);
    emit(const FoodDiaryEntryAdded());
  }

}