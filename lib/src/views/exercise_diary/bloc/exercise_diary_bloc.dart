import 'package:either_dart/either.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_event.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExerciseDiaryBloc extends Bloc<ExerciseDiaryEvent, ExerciseDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  ExerciseDiaryBloc({
    required this.diaryRepository,
    required this.meetupRepository,
    required this.userRepository,
    required this.secureStorage,
  }) : super(const ExerciseDiaryStateInitial()) {
    on<FetchExerciseDiaryEntryInfo>(_fetchExerciseDiaryEntryInfo);
    on<StrengthExerciseDiaryEntryUpdated>(_strengthExerciseDiaryEntryUpdated);
    on<CardioExerciseDiaryEntryUpdated>(_cardioExerciseDiaryEntryUpdated);
  }

  void _cardioExerciseDiaryEntryUpdated(CardioExerciseDiaryEntryUpdated event, Emitter<ExerciseDiaryState> emit) async {
    final currentState = state;

    if (currentState is ExerciseDiaryDataLoaded) {
      emit(const ExerciseDiaryDataLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final updatedEntry = await diaryRepository.updateCardioUserDiaryEntry(event.userId, event.cardioDiaryEntryId, event.entry, accessToken!);

      if (event.entry.meetupId != null) {
        await meetupRepository.upsertCardioDiaryEntryToMeetup(event.entry.meetupId!, updatedEntry.id, accessToken);
      }
      else {
        if (currentState.associatedMeetup != null) {
          await meetupRepository.deleteCardioDiaryEntryFromAssociatedMeetup(currentState.associatedMeetup!.meetup.id, updatedEntry.id, accessToken);
        }
      }
      userRepository.trackUserEvent(EditDiaryEntry(), accessToken);
      emit(const ExerciseEntryUpdatedAndReadyToPop());
    }

  }

  void _strengthExerciseDiaryEntryUpdated(StrengthExerciseDiaryEntryUpdated event, Emitter<ExerciseDiaryState> emit) async {
    final currentState = state;

    if (currentState is ExerciseDiaryDataLoaded) {
      emit(const ExerciseDiaryDataLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final updatedEntry = await diaryRepository.updateStrengthUserDiaryEntry(event.userId, event.strengthDiaryEntryId, event.entry, accessToken!);

      if (event.entry.meetupId != null) {
        await meetupRepository.upsertStrengthDiaryEntryToMeetup(event.entry.meetupId!, updatedEntry.id, accessToken);
      }
      else {
        if (currentState.associatedMeetup != null) {
          await meetupRepository.deleteStrengthDiaryEntryFromAssociatedMeetup(currentState.associatedMeetup!.meetup.id, updatedEntry.id, accessToken);
        }
      }
      userRepository.trackUserEvent(EditDiaryEntry(), accessToken);
      emit(const ExerciseEntryUpdatedAndReadyToPop());
    }

  }


  void _fetchExerciseDiaryEntryInfo(FetchExerciseDiaryEntryInfo event, Emitter<ExerciseDiaryState> emit) async {
    emit(const ExerciseDiaryDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final exerciseDefinition = await diaryRepository.getExerciseInfoByWorkoutId(event.workoutId, accessToken!);
    final Either<CardioDiaryEntry, StrengthDiaryEntry> diaryEntry;

    if (event.isCardio) {
      diaryEntry = Left((await diaryRepository.getCardioUserDiaryEntry(event.userId, event.diaryEntryId, accessToken)));
      if (diaryEntry.left.meetupId != null) {
        final associatedMeetupDetails = await meetupRepository.getDetailedMeetupForUserById(diaryEntry.left.meetupId!, accessToken);
        final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(
            associatedMeetupDetails.participants.map((e) => e.userId).toList(),
            accessToken
        );
        final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
        emit(
            ExerciseDiaryDataLoaded(
                exerciseDefinition: exerciseDefinition,
                diaryEntry: diaryEntry,
                associatedMeetup: associatedMeetupDetails,
                associatedUserIdProfileMap: userIdProfileMap
            )
        );
      }
      else {
        emit(
            ExerciseDiaryDataLoaded(
                exerciseDefinition: exerciseDefinition,
                diaryEntry: diaryEntry
            )
        );
      }
    }
    else {
      diaryEntry = Right((await diaryRepository.getStrengthUserDiaryEntry(event.userId, event.diaryEntryId, accessToken)));
      if (diaryEntry.right.meetupId != null) {
        final associatedMeetupDetails = await meetupRepository.getDetailedMeetupForUserById(diaryEntry.right.meetupId!, accessToken);
        final List<PublicUserProfile> userProfileDetails =
        await userRepository.getPublicUserProfiles(
            associatedMeetupDetails.participants.map((e) => e.userId).toList(),
            accessToken
        );
        final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };
        emit(
            ExerciseDiaryDataLoaded(
                exerciseDefinition: exerciseDefinition,
                diaryEntry: diaryEntry,
                associatedMeetup: associatedMeetupDetails,
                associatedUserIdProfileMap: userIdProfileMap
            )
        );
      }
      else {
        emit(
            ExerciseDiaryDataLoaded(
                exerciseDefinition: exerciseDefinition,
                diaryEntry: diaryEntry
            )
        );
      }
    }

    userRepository.trackUserEvent(ViewDiaryEntry(), accessToken);
  }
}