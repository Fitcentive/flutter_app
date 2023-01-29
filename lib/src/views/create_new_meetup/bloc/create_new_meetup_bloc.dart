import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateNewMeetupBloc extends Bloc<CreateNewMeetupEvent, CreateNewMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  CreateNewMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository,
    required this.userRepository
  }) : super(const CreateNewMeetupStateInitial()) {
    on<NewMeetupChanged>(_newMeetupChanged);
  }

  void _newMeetupChanged(
      NewMeetupChanged event,
      Emitter<CreateNewMeetupState> emit
      ) async {
    final currentState = state;
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    if (currentState is CreateNewMeetupStateInitial) {
      final List<PublicUserProfile> userProfiles;
      if (event.meetupParticipantUserIds.isNotEmpty) {
        userProfiles = await userRepository.getPublicUserProfiles(event.meetupParticipantUserIds, accessToken!);
      }
      else {
        userProfiles = [];
      }
      emit(MeetupModified(
          meetupTime: event.meetupTime,
          meetupName: event.meetupName,
          locationId: event.locationId,
          participantUserProfiles: userProfiles,
          currentUserAvailabilities: event.currentUserAvailabilities,
      ));
    }
    else if (currentState is MeetupModified) {
      final List<PublicUserProfile> userProfiles;
      if (event.meetupParticipantUserIds.isNotEmpty) {
        userProfiles = await userRepository.getPublicUserProfiles(event.meetupParticipantUserIds, accessToken!);
      }
      else {
        userProfiles = [];
      }
      emit(MeetupModified(
        meetupTime: event.meetupTime,
        meetupName: event.meetupName,
        locationId: event.locationId,
        participantUserProfiles: userProfiles,
        currentUserAvailabilities: event.currentUserAvailabilities,
      ));


      // bool doProfilesAlreadyExistForAll = event
      //     .meetupParticipantUserIds
      //     .map((element) => currentState.participantUserProfiles.map((e) => e.userId).contains(element))
      //     .reduce((value, element) => value && element);
      // if (doProfilesAlreadyExistForAll) {
      //   emit(MeetupModified(
      //     meetupTime: event.meetupTime,
      //     meetupName: event.meetupName,
      //     locationId: event.locationId,
      //     participantUserProfiles: currentState.participantUserProfiles,
      //     currentUserAvailabilities: event.currentUserAvailabilities,
      //   ));
      // }
      // else {
      //   final additionalUserIdsToGetProfilesFor = event
      //       .meetupParticipantUserIds
      //       .where((meetupParticipantId) => !currentState.participantUserProfiles.map((e) => e.userId).contains(meetupParticipantId))
      //       .toList();
      //
      //   final additionalUserProfiles =
      //     await userRepository.getPublicUserProfiles(additionalUserIdsToGetProfilesFor, accessToken!);
      //   emit(MeetupModified(
      //     meetupTime: event.meetupTime,
      //     meetupName: event.meetupName,
      //     locationId: event.locationId,
      //     participantUserProfiles: [...currentState.participantUserProfiles, ...additionalUserProfiles],
      //     currentUserAvailabilities: event.currentUserAvailabilities,
      //   ));
      // }
    }

  }
}