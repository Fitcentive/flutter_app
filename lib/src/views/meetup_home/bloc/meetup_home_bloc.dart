import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
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
    on<FetchUserMeetupData>(_fetchUserMeetupData);
    on<FetchMoreUserMeetupData>(_fetchMoreUserMeetupData);
    on<DeleteMeetupForUser>(_deleteMeetupForUser);
  }

  void _deleteMeetupForUser(DeleteMeetupForUser event, Emitter<MeetupHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await meetupRepository.deleteMeetupForUser(event.meetupId, accessToken!);
  }

  void _fetchMoreUserMeetupData(FetchMoreUserMeetupData event, Emitter<MeetupHomeState> emit) async {
    final currentState = state;
    if (currentState is MeetupUserDataFetched && currentState.doesNextPageExist) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

      final meetups = await meetupRepository.getMeetupsForUser(
          event.userId,
          accessToken!,
          ConstantUtils.DEFAULT_LIMIT,
          ConstantUtils.DEFAULT_OFFSET
      );
      final meetupParticipants = { for (var m in meetups) m.id: await meetupRepository.getMeetupParticipants(m.id, accessToken)};
      final meetupDecisions = { for (var m in meetups) m.id: await meetupRepository.getMeetupDecisions(m.id, accessToken)};
      final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

      final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final updatedUserIdProfileMap = {...currentState.userIdProfileMap, ...userIdProfileMap};

      emit(MeetupUserDataFetched(
        meetups: [...currentState.meetups, ...meetups],
        meetupDecisions: meetupDecisions,
        meetupParticipants: meetupParticipants,
        doesNextPageExist: doesNextPageExist,
        userIdProfileMap: updatedUserIdProfileMap,
      ));
    }
  }

  void _fetchUserMeetupData(FetchUserMeetupData event, Emitter<MeetupHomeState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final meetups = await meetupRepository.getMeetupsForUser(
        event.userId,
        accessToken!,
        ConstantUtils.DEFAULT_LIMIT,
        ConstantUtils.DEFAULT_OFFSET
    );
    final meetupParticipants = { for (var m in meetups) m.id: await meetupRepository.getMeetupParticipants(m.id, accessToken)};
    final meetupDecisions = { for (var m in meetups) m.id: await meetupRepository.getMeetupDecisions(m.id, accessToken)};
    final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

    final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(MeetupUserDataFetched(
      meetups: meetups,
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