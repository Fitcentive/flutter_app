
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_event.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodDiaryBloc extends Bloc<FoodDiaryEvent, FoodDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final UserRepository userRepository;
  final MeetupRepository meetupRepository;

  FoodDiaryBloc({
    required this.diaryRepository,
    required this.meetupRepository,
    required this.userRepository,
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

    if (diaryEntry.meetupId != null) {
      final associatedMeetupDetails = await meetupRepository.getDetailedMeetupForUserById(diaryEntry.meetupId!, accessToken);
      final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(
            associatedMeetupDetails.participants.map((e) => e.userId).toList(),
            accessToken
        );
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      emit(
          FoodDiaryDataLoaded(
            foodDefinition: foodResult,
            diaryEntry: diaryEntry,
            associatedMeetup: associatedMeetupDetails,
            associatedUserIdProfileMap: userIdProfileMap,
          )
      );
    }
    else {
      emit(
          FoodDiaryDataLoaded(
              foodDefinition: foodResult,
              diaryEntry: diaryEntry,
          )
      );
    }

  }

  void _foodDiaryEntryUpdated(FoodDiaryEntryUpdated event, Emitter<FoodDiaryState> emit) async {
    final currentState = state;

    if (currentState is FoodDiaryDataLoaded) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final updatedEntry = await diaryRepository.updateFoodDiaryEntryForUser(event.userId, event.foodDiaryEntryId, event.entry, accessToken!);
      if (event.entry.meetupId != null) {
        await meetupRepository.upsertFoodDiaryEntryToMeetup(event.entry.meetupId!, updatedEntry.id, accessToken);
      }
      else {
        if (currentState.associatedMeetup != null) {
          await meetupRepository.deleteFoodDiaryEntryFromAssociatedMeetup(currentState.associatedMeetup!.meetup.id, updatedEntry.id, accessToken);
        }
      }
      emit(const FoodEntryUpdatedAndReadyToPop());
    }

  }

}