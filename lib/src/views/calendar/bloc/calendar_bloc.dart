import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_event.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  CalendarBloc({
    required this.userRepository,
    required this.meetupRepository,
    required this.secureStorage,
  }) : super(const CalendarStateInitial()) {

    on<FetchCalendarMeetupData>(_fetchCalendarMeetupData);
  }

  void _fetchCalendarMeetupData(FetchCalendarMeetupData event, Emitter<CalendarState> emit) async {
    emit(const CalendarMeetupDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final meetups = await meetupRepository.getMeetupsForUser(
      event.userId,
      accessToken!,
      ConstantUtils.DEFAULT_MAX_LIMIT,
      ConstantUtils.DEFAULT_OFFSET,
      null,
      null
    );
    final meetupLocations = await Future.wait(meetups.map((e) {
      if (e.locationId != null) {
        return meetupRepository.getLocationByLocationId(e.locationId!, accessToken);
      } else {
        return Future.value(null);
      }
    }));

    final meetupParticipants = { for (var m in meetups) m.id: await meetupRepository.getMeetupParticipants(m.id, accessToken)};
    final meetupDecisions = { for (var m in meetups) m.id: await meetupRepository.getMeetupDecisions(m.id, accessToken)};
    final doesNextPageExist = meetups.length == ConstantUtils.DEFAULT_LIMIT ? true : false;

    final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
    final List<PublicUserProfile> userProfileDetails =
    await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
    final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

    emit(CalendarMeetupUserDataFetched(
        meetups: meetups,
        meetupLocations: meetupLocations,
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