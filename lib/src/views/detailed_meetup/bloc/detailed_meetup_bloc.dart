import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedMeetupBloc extends Bloc<DetailedMeetupEvent, DetailedMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  DetailedMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository,
    required this.userRepository
  }): super(const DetailedMeetupStateInitial()) {

    on<FetchAdditionalMeetupData>(_fetchAdditionalMeetupData);
    on<SaveAvailabilitiesForCurrentUser>(_saveAvailabilitiesForCurrentUser);
    on<UpdateMeetupDetails>(_updateMeetupDetails);
    on<AddParticipantDecisionToMeetup>(_addParticipantDecisionToMeetup);
    on<FetchAllMeetupData>(_fetchAllMeetupData);
  }

  void _fetchAllMeetupData(FetchAllMeetupData event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

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
    final availabilities = await Future.wait(participantIds.map((e) =>
        meetupRepository.getMeetupParticipantAvailabilities(event.meetupId, e, accessToken!))
    );

    var i = 0;
    while(i < availabilities.length) {
      availabilityMap[participantIds[i]] = availabilities[i];
      i++;
    }


    final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(meetupParticipants.map((e) => e.userId).toList(), accessToken);

    emit(DetailedMeetupDataFetched(
        meetupId: event.meetupId,
        userAvailabilities: availabilityMap,
        meetupLocation: location,
        meetup: meetup,
        participants: meetupParticipants,
        decisions: meetupDecisions,
        userProfiles: userProfileDetails
    ));
  }

  void _addParticipantDecisionToMeetup(AddParticipantDecisionToMeetup event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    
    // Remove previous decision
    // await meetupRepository.deleteUserMeetupDecision(event.meetupId, event.participantId, accessToken!);
    // No need to remove previous as upsert takes care of it

    // Add current decision
    await meetupRepository.upsertMeetupDecision(event.meetupId, event.participantId, event.hasAccepted, accessToken!);
  }
  
  void _updateMeetupDetails(UpdateMeetupDetails event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final updatedMeetup = MeetupUpdate(
      meetupType: "Workout",
      name: event.meetupName,
      time: event.meetupTime,
      durationInMinutes: null, // Need to update things to include a time duration
      locationId: event.location?.locationId,
    );

    final meetup = await meetupRepository.updateMeetup(event.meetupId, updatedMeetup, accessToken!);

    final existingSavedMeetupParticipants = await meetupRepository.getMeetupParticipants(event.meetupId, accessToken);
    final existingSavedMeetupParticipantsUserIds = existingSavedMeetupParticipants.map((e) => e.userId);

    /// Creates a new set with the elements of this that are not in [other].
    final participantsToRemove =
      existingSavedMeetupParticipantsUserIds.toSet().difference(event.meetupParticipantUserIds.toSet());
    final participantsToAdd =
      event.meetupParticipantUserIds.toSet().difference(existingSavedMeetupParticipantsUserIds.toSet());

    if (participantsToAdd.isNotEmpty) {
      await Future.wait(participantsToAdd.map((e) =>
          meetupRepository.addParticipantToMeetup(meetup.id, e, accessToken)));
    }
    if (participantsToRemove.isNotEmpty) {
      await Future.wait(participantsToRemove.map((e) =>
          meetupRepository.removeParticipantFromMeetup(meetup.id, e, accessToken)));
    }
  }

  void _saveAvailabilitiesForCurrentUser(SaveAvailabilitiesForCurrentUser event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // Delete all availabilities first, much easier than updating them
    await meetupRepository.deleteMeetupParticipantAvailabilities(event.meetupId, event.currentUserId, accessToken!);
    await meetupRepository.upsertMeetupParticipantAvailabilities(event.meetupId, event.currentUserId, accessToken, event.availabilities);

    // No change in emitted state, this is a background operation
  }

  void _fetchAdditionalMeetupData(FetchAdditionalMeetupData event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    emit(const DetailedMeetupStateLoading());

    final meetupLocation = event.meetupLocationFsqId == null ? null :
      await meetupRepository.getLocationByFsqId(event.meetupLocationFsqId!, accessToken!);

    Map<String, List<MeetupAvailability>> availabilityMap = {};
    final availabilities = await Future.wait(event.participantIds.map((e) =>
        meetupRepository.getMeetupParticipantAvailabilities(event.meetupId, e, accessToken!))
    );

    var i = 0;
    while(i < availabilities.length) {
      availabilityMap[event.participantIds[i]] = availabilities[i];
      i++;
    }

    emit(DetailedMeetupDataFetched(
        meetupId: event.meetupId,
        userAvailabilities: availabilityMap,
        meetupLocation: meetupLocation,
        meetup: event.meetup,
        participants: event.participants,
        decisions: event.decisions,
        userProfiles: event.userProfiles
    ));
  }

}