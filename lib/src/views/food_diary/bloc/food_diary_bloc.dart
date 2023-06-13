
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_event.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodDiaryBloc extends Bloc<FoodDiaryEvent, FoodDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  FoodDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const FoodDiaryStateInitial()) {
    on<FetchFoodDiaryEntryInfo>(_fetchFoodDiaryEntryInfo);
    on<FoodDiaryEntryUpdated>(_foodDiaryEntryUpdated);
  }

  void _fetchFoodDiaryEntryInfo(FetchFoodDiaryEntryInfo event, Emitter<FoodDiaryState> emit) async {
    emit(const FoodDiaryDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final foodResult = await diaryRepository.getFoodById(event.foodId.toString(), accessToken!);
    final diaryEntry = await diaryRepository.getFoodDiaryEntryById(event.userId, event.diaryEntryId, accessToken);
    emit(
        FoodDiaryDataLoaded(
          foodDefinition: foodResult,
          diaryEntry: diaryEntry
        )
    );
  }

  void _foodDiaryEntryUpdated(FoodDiaryEntryUpdated event, Emitter<FoodDiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await diaryRepository.updateFoodDiaryEntryForUser(event.userId, event.foodDiaryEntryId, event.entry, accessToken!);
    emit(const FoodEntryUpdatedAndReadyToPop());
  }

}