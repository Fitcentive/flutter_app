import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
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

    // Remove existing participants and add again, this is to ensure all updated changes are captured
    await meetupRepository.removeAllParticipantsToMeetup(event.meetupId, accessToken);
    await Future.wait(event.meetupParticipantUserIds.map((e) => meetupRepository.addParticipantToMeetup(meetup.id, e, accessToken)));

    // No need to emit state, we are done over here
    // todo - should we include meetup decisions too?
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
        meetupLocation: meetupLocation
    ));
  }

}