import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_event.dart';
import 'package:flutter_app/src/views/meetup_home/bloc/meetup_home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MeetupHomeBloc extends Bloc<MeetupHomeEvent, MeetupHomeState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  MeetupHomeBloc({
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const MeetupHomeStateInitial()) {
    on<TraceViewMeetupHomeEvent>(_traceViewMeetupHomeEvent);
    on<FetchUserMeetupData>(_fetchUserMeetupData);
    on<FetchMoreUserMeetupData>(_fetchMoreUserMeetupData);
    on<DeleteMeetupForUser>(_deleteMeetupForUser);
  }

  void _traceViewMeetupHomeEvent(TraceViewMeetupHomeEvent event, Emitter<MeetupHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewMeetupHome(), accessToken!);
  }

  void _deleteMeetupForUser(DeleteMeetupForUser event, Emitter<MeetupHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteMeetupForUser(event.meetupId, accessToken!);
  }

  void _fetchMoreUserMeetupData(FetchMoreUserMeetupData event, Emitter<MeetupHomeState> emit) async {
    final currentState = state;
    if (currentState is MeetupUserDataFetched && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

      final meetups = await meetupRepository.getDetailedMeetupsForUser(
          event.userId,
          accessToken!,
          ConstantUtils.DEFAULT_MEETUP_LIMIT,
          currentState.meetups.length,
          event.selectedFilterByOption,
          event.selectedStatusOption,
      );
      // final meetupLocations = await Future.wait(meetups.map((e) {
      //   if (e.locationId != null) {
      //     return meetupRepository.getLocationByLocationId(e.locationId!, accessToken);
      //   } else {
      //     return Future.value(null);
      //   }
      // }));
      //
      // final meetupParticipants = { for (var m in meetups) m.id: await meetupRepository.getMeetupParticipants(m.id, accessToken)};
      // final meetupDecisions = { for (var m in meetups) m.id: await meetupRepository.getMeetupDecisions(m.id, accessToken)};
      final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_MEETUP_LIMIT ? true : false;
      final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
      final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

      final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      emit(MeetupUserDataFetched(
        meetups: [...currentState.meetups, ...meetups.map((e) => e.meetup)],
        meetupLocations: [...currentState.meetupLocations, ...meetups.map((e) => e.location)],
        meetupDecisions: {...meetupDecisions, ...currentState.meetupDecisions},
        meetupParticipants: {...meetupParticipants, ...currentState.meetupParticipants},
        doesNextPageExist: doesNextPageExist,
        userIdProfileMap: {...currentState.userIdProfileMap, ...userIdProfileMap},
      ));
    }
  }

  void _fetchUserMeetupData(FetchUserMeetupData event, Emitter<MeetupHomeState> emit) async {
    emit(const MeetupDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final meetups = await meetupRepository.getDetailedMeetupsForUser(
        event.userId,
        accessToken!,
        ConstantUtils.DEFAULT_MEETUP_LIMIT,
        ConstantUtils.DEFAULT_OFFSET,
        event.selectedFilterByOption,
        event.selectedStatusOption,
    );
    // final meetupLocations = await Future.wait(meetups.map((e) {
    //   if (e.locationId != null) {
    //     return meetupRepository.getLocationByLocationId(e.locationId!, accessToken);
    //   } else {
    //     return Future.value(null);
    //   }
    // }));
    //
    // final meetupParticipants = { for (var m in meetups) m.id: await meetupRepository.getMeetupParticipants(m.id, accessToken)};
    // final meetupDecisions = { for (var m in meetups) m.id: await meetupRepository.getMeetupDecisions(m.id, accessToken)};
    final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_MEETUP_LIMIT ? true : false;

    final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
    final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

    final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(MeetupUserDataFetched(
      meetups: meetups.map((e) => e.meetup).toList(),
      meetupLocations: meetups.map((e) => e.location).toList(),
      meetupDecisions: meetupDecisions,
      meetupParticipants: meetupParticipants,
      doesNextPageExist: doesNextPageExist,
      userIdProfileMap: userIdProfileMap
    ));
  }

  List<String> _getRelevantUserIdsFromParticipants(Map<String, List<MeetupParticipant>> participants) {
    return participants
        .entries
        .map((e) => e.value.map((m) => m.userId).toSet().toList())
        .expand((i) => i)
        .toList();
  }
}