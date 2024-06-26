import 'package:flutter_app/src/infrastructure/repos/rest/chat_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/location/location.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DetailedMeetupBloc extends Bloc<DetailedMeetupEvent, DetailedMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final DiaryRepository diaryRepository;

  Uuid uuid = const Uuid();

  void _dissociateFoodDiaryEntryFromMeetup(
      DissociateFoodDiaryEntryFromMeetup event,
      Emitter<DetailedMeetupState> emit
      ) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteFoodDiaryEntryFromAssociatedMeetup(event.meetupId, event.foodDiaryEntryId, accessToken!);

  }

  DetailedMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository,
    required this.userRepository,
    required this.chatRepository,
    required this.diaryRepository,
  }): super(const DetailedMeetupStateInitial()) {

    on<FetchAdditionalMeetupData>(_fetchAdditionalMeetupData);
    on<SaveAvailabilitiesForCurrentUser>(_saveAvailabilitiesForCurrentUser);
    on<UpdateMeetupDetails>(_updateMeetupDetails);
    on<AddParticipantDecisionToMeetup>(_addParticipantDecisionToMeetup);
    on<FetchAllMeetupData>(_fetchAllMeetupData);
    on<GetDirectMessagePrivateChatRoomForMeetup>(_getDirectMessagePrivateChatRoomForMeetup);
    on<CreateChatRoomForMeetup>(_createChatRoomForMeetup);
    on<DeleteMeetupForUser>(_deleteMeetupForUser);
    on<DissociateCardioDiaryEntryFromMeetup>(_dissociateCardioDiaryEntryFromMeetup);
    on<DissociateStrengthDiaryEntryFromMeetup>(_dissociateStrengthDiaryEntryFromMeetup);
    on<DissociateFoodDiaryEntryFromMeetup>(_dissociateFoodDiaryEntryFromMeetup);
    on<SaveAllDiaryEntriesAssociatedWithMeetup>(_saveAllDiaryEntriesAssociatedWithMeetup);
  }

  void _saveAllDiaryEntriesAssociatedWithMeetup(
      SaveAllDiaryEntriesAssociatedWithMeetup event,
      Emitter<DetailedMeetupState> emit
      ) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // Delete all existing associations for a given a meetup, user combo
    // Save ones in event afresh after that
    await meetupRepository.deleteAllAssociatedDiaryEntriesToMeetupByUser(event.meetupId, event.currentUserId, accessToken!);

    final cardioFut = Future.wait(event.cardioDiaryEntryIds.map((e) => meetupRepository.upsertCardioDiaryEntryToMeetup(event.meetupId, e, accessToken)));
    final strengthFut = Future.wait(event.strengthDiaryEntryIds.map((e) => meetupRepository.upsertStrengthDiaryEntryToMeetup(event.meetupId, e, accessToken)));
    final foodFut = Future.wait(event.foodDiaryEntryIds.map((e) => meetupRepository.upsertFoodDiaryEntryToMeetup(event.meetupId, e, accessToken)));
    final assocFut = diaryRepository.associateDiaryEntriesWithMeetupId(
      event.currentUserId,
      event.meetupId,
      event.cardioDiaryEntryIds,
      event.strengthDiaryEntryIds,
      event.foodDiaryEntryIds,
      accessToken,
    );

    userRepository.trackUserEvent(AssociateDiaryEntryToMeetup(), accessToken);

    await cardioFut;
    await strengthFut;
    await foodFut;
    await assocFut;
  }

  void _dissociateStrengthDiaryEntryFromMeetup(
      DissociateStrengthDiaryEntryFromMeetup event,
      Emitter<DetailedMeetupState> emit
      ) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteStrengthDiaryEntryFromAssociatedMeetup(event.meetupId, event.strengthDiaryEntryId, accessToken!);
  }

  void _dissociateCardioDiaryEntryFromMeetup(
      DissociateCardioDiaryEntryFromMeetup event,
      Emitter<DetailedMeetupState> emit
  ) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteCardioDiaryEntryFromAssociatedMeetup(event.meetupId, event.cardioDiaryEntryId, accessToken!);
  }

  void _deleteMeetupForUser(DeleteMeetupForUser event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteMeetupForUser(event.meetupId, accessToken!);

    emit(const MeetupDeletedAndReadyToPop());
  }

  void _createChatRoomForMeetup(CreateChatRoomForMeetup event, Emitter<DetailedMeetupState> emit) async {
    final currentState = state;
    if (currentState is DetailedMeetupDataFetched) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

      final chatRoom = await chatRepository.getChatRoomForGroupConversationWithName(event.participants, event.roomName, accessToken!);
      final updatedMeetup = await meetupRepository.updateMeetupChatRoom(event.meetup.id, chatRoom.id, accessToken);

      emit(MeetupChatRoomCreated(chatRoomId: chatRoom.id, randomId: uuid.v4()));
      emit(DetailedMeetupDataFetched(
          meetupId: currentState.meetupId,
          userAvailabilities: currentState.userAvailabilities,
          meetupLocation: currentState.meetupLocation,
          meetup: updatedMeetup,
          participants: currentState.participants,
          decisions: currentState.decisions,
          userProfiles: currentState.userProfiles,
          participantDiaryEntriesMap: currentState.participantDiaryEntriesMap,
          rawFoodEntries: currentState.rawFoodEntries,
      ));
    }

  }

  void _getDirectMessagePrivateChatRoomForMeetup(GetDirectMessagePrivateChatRoomForMeetup event, Emitter<DetailedMeetupState> emit) async {
    final currentState = state;
    if (currentState is DetailedMeetupDataFetched) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final chatRoom = await chatRepository.getChatRoomForPrivateConversation(
          event.participants.where((element) => element != event.currentUserProfileId).first, accessToken!
      );

      emit(MeetupChatRoomCreated(chatRoomId: chatRoom.id, randomId: uuid.v4()));
      emit(DetailedMeetupDataFetched(
          meetupId: currentState.meetupId,
          userAvailabilities: currentState.userAvailabilities,
          meetupLocation: currentState.meetupLocation,
          meetup: currentState.meetup,
          participants: currentState.participants,
          decisions: currentState.decisions,
          userProfiles: currentState.userProfiles,
          participantDiaryEntriesMap: currentState.participantDiaryEntriesMap,
          rawFoodEntries: currentState.rawFoodEntries,
      ));
    }
  }

  void _fetchAllMeetupData(FetchAllMeetupData event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    try {
      final meetup = await meetupRepository.getMeetupById(
        event.meetupId,
        accessToken!,
      );

      MeetupLocation? meetupLocation;
      if (meetup.locationId != null) {
        meetupLocation = await meetupRepository.getLocationByLocationId(meetup.locationId!, accessToken);
      }
      final location = meetupLocation == null ? null : await meetupRepository.getLocationByFsqId(meetupLocation.fsqId, accessToken);

      final meetupParticipants = await meetupRepository.getMeetupParticipants(meetup.id, accessToken);
      final meetupDecisions = await meetupRepository.getMeetupDecisions(meetup.id, accessToken);

      final participantIds = meetupParticipants.map((e) => e.userId).toList();
      Map<String, List<MeetupAvailability>> availabilityMap = {};
      Map<String, AllDiaryEntries> participantDiaryEntriesMap = {};

      final availabilities = (await Future.wait(participantIds.map((e) =>
          meetupRepository.getMeetupParticipantAvailabilities(event.meetupId, e, accessToken))
      )).map((mList) =>
          mList.map((m) {
            return MeetupAvailability(
                m.id,
                m.meetupId,
                m.userId,
                m.availabilityStart.toLocal(),
                m.availabilityEnd.toLocal(),
                m.createdAt.toLocal(),
                m.updatedAt.toLocal()
            );
          }
          ).toList()
      ).toList();

      var i = 0;
      while(i < availabilities.length) {
        availabilityMap[participantIds[i]] = availabilities[i];
        i++;
      }


      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(meetupParticipants.map((e) => e.userId).toList(), accessToken);
      
      final List<AllDiaryEntries> diaryEntries =
        await Future.wait(participantIds.map((e) => meetupRepository.getAllDiaryEntriesForMeetupUser(event.meetupId, e, accessToken)));

      var j = 0;
      while(j < diaryEntries.length) {
        participantDiaryEntriesMap[participantIds[j]] = diaryEntries[j];
        j++;
      }

      final allFoodEntriesOnly = diaryEntries.map((e) => e.foodEntries).expand((element) => element).toList();
      final foodEntries = await Future.wait(allFoodEntriesOnly.map((e) => diaryRepository.getFoodById(e.foodId.toString(), accessToken!)));

      userRepository.trackUserEvent(ViewDetailedMeetup(), accessToken);

      emit(DetailedMeetupDataFetched(
          meetupId: event.meetupId,
          userAvailabilities: availabilityMap,
          meetupLocation: location,
          meetup: meetup,
          participants: meetupParticipants,
          decisions: meetupDecisions,
          userProfiles: userProfileDetails,
          participantDiaryEntriesMap: participantDiaryEntriesMap,
          rawFoodEntries: foodEntries
      ));
    } catch (ex) {
      emit(const ErrorState());
    }

  }

  void _addParticipantDecisionToMeetup(AddParticipantDecisionToMeetup event, Emitter<DetailedMeetupState> emit) async {
    final currentState = state;
    if (currentState is DetailedMeetupDataFetched) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

      // Remove previous decision
      // await meetupRepository.deleteUserMeetupDecision(event.meetupId, event.participantId, accessToken!);
      // No need to remove previous as upsert takes care of it

      // Add current decision
      await meetupRepository.upsertMeetupDecision(event.meetupId, event.participantId, event.hasAccepted, accessToken!);
      userRepository.trackUserEvent(RespondToMeetup(), accessToken);

      final now = DateTime.now();
      final updatedDecisions = [
        ...currentState.decisions.where((element) => element.userId != event.participantId).toList(),
        MeetupDecision(event.meetupId, event.participantId, event.hasAccepted, now, now)
      ];

      emit(DetailedMeetupDataFetched(
        meetupId: currentState.meetupId,
        userAvailabilities: currentState.userAvailabilities,
        meetupLocation: currentState.meetupLocation,
        meetup: currentState.meetup,
        participants: currentState.participants,
        decisions: updatedDecisions,
        userProfiles: currentState.userProfiles,
        participantDiaryEntriesMap: currentState.participantDiaryEntriesMap,
        rawFoodEntries: currentState.rawFoodEntries,
      ));
    }
  }
  
  void _updateMeetupDetails(UpdateMeetupDetails event, Emitter<DetailedMeetupState> emit) async {
   final currentState = state;

   if (currentState is DetailedMeetupDataFetched) {
     final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

     final originalMeetup = await meetupRepository.getMeetupById(event.meetupId, accessToken!);

     final updatedMeetup = MeetupUpdate(
       meetupType: "Workout",
       name: event.meetupName,
       time: event.meetupTime,
       durationInMinutes: null, // Need to update things to include a time duration
       locationId: event.location?.locationId,
       chatRoomId: originalMeetup.chatRoomId,
     );

     final meetup = await meetupRepository.updateMeetup(event.meetupId, updatedMeetup, accessToken!);

     final existingSavedMeetupParticipants = await meetupRepository.getMeetupParticipants(event.meetupId, accessToken);
     final existingSavedMeetupParticipantsUserIds = existingSavedMeetupParticipants.map((e) => e.userId);

     /// Creates a new set with the elements of this that are not in [other].
     final participantsToRemove =
     existingSavedMeetupParticipantsUserIds.toSet().difference(event.meetupParticipantProfiles.map((e) => e.userId).toSet());
     final participantsToAdd =
     event.meetupParticipantProfiles.map((e) => e.userId).toSet().difference(existingSavedMeetupParticipantsUserIds.toSet());

     if (participantsToAdd.isNotEmpty) {
       await Future.wait(participantsToAdd.map((e) =>
           meetupRepository.addParticipantToMeetup(meetup.id, e, accessToken)));
     }
     if (participantsToRemove.isNotEmpty) {
       await Future.wait(participantsToRemove.map((e) =>
           meetupRepository.removeParticipantFromMeetup(meetup.id, e, accessToken)));
     }

     final updatedMeetupParticipants = await meetupRepository.getMeetupParticipants(meetup.id, accessToken);

     // Fetch location only if we need to
     Location? updatedLocation;
     if (meetup.locationId != currentState.meetupLocation?.locationId) {
       MeetupLocation? meetupLocation;
       if (meetup.locationId != null) {
         meetupLocation = await meetupRepository.getLocationByLocationId(meetup.locationId!, accessToken);
       }

       updatedLocation = meetupLocation == null ? null : await meetupRepository.getLocationByFsqId(meetupLocation.fsqId, accessToken);
     }

     userRepository.trackUserEvent(EditMeetup(), accessToken);

     emit(DetailedMeetupDataFetched(
         meetupId: currentState.meetupId,
         userAvailabilities: currentState.userAvailabilities,
         meetupLocation: meetup.locationId != currentState.meetupLocation?.locationId ? updatedLocation : currentState.meetupLocation,
         meetup: meetup,
         participants: updatedMeetupParticipants,
         decisions: currentState.decisions,
         userProfiles: event.meetupParticipantProfiles,
         participantDiaryEntriesMap: currentState.participantDiaryEntriesMap,
         rawFoodEntries: currentState.rawFoodEntries,
     ));
   }

  }

  void _saveAvailabilitiesForCurrentUser(SaveAvailabilitiesForCurrentUser event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // Delete all availabilities first, much easier than updating them
    await meetupRepository.deleteMeetupParticipantAvailabilities(event.meetupId, event.currentUserId, accessToken!);
    final updatedAvailabilities =
      await meetupRepository.upsertMeetupParticipantAvailabilities(event.meetupId, event.currentUserId, accessToken, event.availabilities);

    userRepository.trackUserEvent(AddAvailabilityToMeetup(), accessToken);
    // No change in emitted state, this is a background operation

    final currentState = state;
    if (currentState is DetailedMeetupDataFetched) {
      emit(
        DetailedMeetupDataFetched(
            meetupId: currentState.meetupId,
            userAvailabilities: {
              ...currentState.userAvailabilities,
              event.currentUserId: updatedAvailabilities
            },
            meetupLocation: currentState.meetupLocation,
            meetup: currentState.meetup,
            participants: currentState.participants,
            decisions: currentState.decisions,
            userProfiles: currentState.userProfiles,
            participantDiaryEntriesMap: currentState.participantDiaryEntriesMap,
            rawFoodEntries: currentState.rawFoodEntries,
        )
      );
    }

  }

  void _fetchAdditionalMeetupData(FetchAdditionalMeetupData event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    emit(const DetailedMeetupStateLoading());

    final meetupLocation = event.meetupLocationFsqId == null ? null :
      await meetupRepository.getLocationByFsqId(event.meetupLocationFsqId!, accessToken!);

    Map<String, List<MeetupAvailability>> availabilityMap = {};
    Map<String, AllDiaryEntries> participantDiaryEntriesMap = {};

    final availabilities = (await Future.wait(event.participantIds.map((e) => meetupRepository.getMeetupParticipantAvailabilities(event.meetupId, e, accessToken!))))
        .map((mList) =>
            mList.map((m) {
              return MeetupAvailability(
                  m.id,
                  m.meetupId,
                  m.userId,
                  m.availabilityStart.toLocal(),
                  m.availabilityEnd.toLocal(),
                  m.createdAt.toLocal(),
                  m.updatedAt.toLocal()
              );
            }
            ).toList()
    ).toList();

    var i = 0;
    while(i < availabilities.length) {
      availabilityMap[event.participantIds[i]] = availabilities[i];
      i++;
    }

    final List<AllDiaryEntries> diaryEntries =
    await Future.wait(event.participantIds.map((e) => meetupRepository.getAllDiaryEntriesForMeetupUser(event.meetupId, e, accessToken!)));

    var j = 0;
    while(j < diaryEntries.length) {
      participantDiaryEntriesMap[event.participantIds[j]] = diaryEntries[j];
      j++;
    }

    final allFoodEntriesOnly = diaryEntries.map((e) => e.foodEntries).expand((element) => element).toList();
    final foodEntries = await Future.wait(allFoodEntriesOnly.map((e) => diaryRepository.getFoodById(e.foodId.toString(), accessToken!)));

    userRepository.trackUserEvent(ViewDetailedMeetup(), accessToken!);

    emit(DetailedMeetupDataFetched(
        meetupId: event.meetupId,
        userAvailabilities: availabilityMap,
        meetupLocation: meetupLocation,
        meetup: event.meetup,
        participants: event.participants,
        decisions: event.decisions,
        userProfiles: event.userProfiles,
        participantDiaryEntriesMap: participantDiaryEntriesMap,
        rawFoodEntries: foodEntries
    ));
  }

}