import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/bloc/select_from_meetups_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/bloc/select_from_meetups_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectFromMeetupsBloc extends Bloc<SelectFromMeetupsEvent, SelectFromMeetupsState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  SelectFromMeetupsBloc({
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const SelectFromMeetupsStateInitial()) {
    on<FetchUserMeetupData>(_fetchUserMeetupData);
    on<FetchMoreUserMeetupData>(_fetchMoreUserMeetupData);
  }

  void _fetchUserMeetupData(FetchUserMeetupData event, Emitter<SelectFromMeetupsState> emit) async {
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

    final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_MEETUP_LIMIT ? true : false;

    final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
    final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

    final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(MeetupUserDataFetched(
        meetups: meetups.map((e) => e.meetup).toList(),
        meetupDecisions: meetupDecisions,
        meetupParticipants: meetupParticipants,
        doesNextPageExist: doesNextPageExist,
        userIdProfileMap: userIdProfileMap
    ));
  }

  void _fetchMoreUserMeetupData(FetchMoreUserMeetupData event, Emitter<SelectFromMeetupsState> emit) async {
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

      final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_MEETUP_LIMIT ? true : false;
      final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
      final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

      final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      emit(MeetupUserDataFetched(
        meetups: [...currentState.meetups, ...meetups.map((e) => e.meetup)],
        meetupDecisions: {...meetupDecisions, ...currentState.meetupDecisions},
        meetupParticipants: {...meetupParticipants, ...currentState.meetupParticipants},
        doesNextPageExist: doesNextPageExist,
        userIdProfileMap: {...currentState.userIdProfileMap, ...userIdProfileMap},
      ));
    }
  }

  List<String> _getRelevantUserIdsFromParticipants(Map<String, List<MeetupParticipant>> participants) {
    return participants
        .entries
        .map((e) => e.value.map((m) => m.userId).toSet().toList())
        .expand((i) => i)
        .toList();
  }
}