import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_event.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddFoodToDiaryBloc extends Bloc<AddFoodToDiaryEvent, AddFoodToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  AddFoodToDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const AddToFoodDiaryStateInitial()) {
    on<AddFoodEntryToDiary>(_addFoodEntryToDiary);
  }


  void _addFoodEntryToDiary(AddFoodEntryToDiary event, Emitter<AddFoodToDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.addFoodEntryToUserDiary(event.userId, event.newEntry, accessToken!);
    emit(const FoodDiaryEntryAdded());
  }

}