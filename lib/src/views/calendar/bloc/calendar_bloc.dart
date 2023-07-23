import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_event.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final DiaryRepository diaryRepository;
  final UserRepository userRepository;

  CalendarBloc({
    required this.userRepository,
    required this.meetupRepository,
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const CalendarStateInitial()) {

    on<FetchCalendarMeetupData>(_fetchCalendarMeetupAndDiaryData);
    on<TrackViewCalendarEvent>(_trackViewCalendarEvent);
  }

  void _trackViewCalendarEvent(TrackViewCalendarEvent event, Emitter<CalendarState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewCalendar(), accessToken!);
  }
  void _fetchCalendarMeetupAndDiaryData(FetchCalendarMeetupData event, Emitter<CalendarState> emit) async {
    final currentState = state;
    if (currentState is CalendarMeetupUserDataFetched) {
      // emit(const CalendarMeetupDataLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

      final diaryEntriesFut = diaryRepository.getAllDiaryEntriesForUserByMonth(
          event.userId,
          DateFormat("yyyy-MM-dd")
              .format(DateTime(event.currentSelectedDateTime.year, event.currentSelectedDateTime.month, 0)
              .add(const Duration(days: 1))),
          DateTime.now().timeZoneOffset.inMinutes,
          accessToken!
      );
      final meetups = await meetupRepository.getDetailedMeetupsForUserByMonth(
        accessToken!,
        DateFormat("yyyy-MM-dd")
            .format(DateTime(event.currentSelectedDateTime.year, event.currentSelectedDateTime.month, 0)
            .add(const Duration(days: 1))),
        DateTime.now().timeZoneOffset.inMinutes,
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
      final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
      final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

      // Check previous state for info if it already exists
      final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
      final netNewUserIds = distinctUserIdsFromParticipants
          .where((element) => !currentState.userIdProfileMap.keys.contains(element))
          .toList();
      final List<PublicUserProfile> newUserProfileDetails =
        await userRepository.getPublicUserProfiles(netNewUserIds, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in [...newUserProfileDetails, ...currentState.userIdProfileMap.values]) (e).userId : e };

      final diaryEntries = await diaryEntriesFut;
      final distinctFoodIds = diaryEntries.entries.values.map((e) => e.foodEntries).expand((e) => e).map((e) => e.foodId).toSet().toList();
      final foodEntriesTotal = await Future.wait(distinctFoodIds.map((e) => diaryRepository.getFoodById(e.toString(), accessToken)));

      emit(CalendarMeetupUserDataFetched(
          meetups: meetups.map((e) => e.meetup).toList(),
          meetupLocations: meetups.map((e) => e.location).toList(),
          meetupDecisions: meetupDecisions,
          meetupParticipants: meetupParticipants,
          userIdProfileMap: userIdProfileMap,
          foodDiaryEntries: foodEntriesTotal,
          allDiaryEntries: diaryEntries,
      ));
    }

    else {
      emit(const CalendarMeetupDataLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final meetups = await meetupRepository.getDetailedMeetupsForUserByMonth(
        accessToken!,
        DateFormat("yyyy-MM-dd")
            .format(DateTime(event.currentSelectedDateTime.year, event.currentSelectedDateTime.month, 0)
            .add(const Duration(days: 1))),
        DateTime.now().timeZoneOffset.inMinutes,
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
      final meetupDecisions = { for (var m in meetups) m.meetup.id: m.decisions};
      final meetupParticipants = { for (var m in meetups) m.meetup.id: m.participants};

      final distinctUserIdsFromParticipants = _getRelevantUserIdsFromParticipants(meetupParticipants);
      final List<PublicUserProfile> userProfileDetails =
      await userRepository.getPublicUserProfiles(distinctUserIdsFromParticipants, accessToken);
      final Map<String, PublicUserProfile> userIdProfileMap = { for (var e in userProfileDetails) (e).userId : e };

      final diaryEntries = await diaryRepository.getAllDiaryEntriesForUserByMonth(
          event.userId,
          DateFormat("yyyy-MM-dd")
              .format(DateTime(event.currentSelectedDateTime.year, event.currentSelectedDateTime.month, 0)
              .add(const Duration(days: 1))),
          DateTime.now().timeZoneOffset.inMinutes,
          accessToken!
      );
      final distinctFoodIds = diaryEntries.entries.values.map((e) => e.foodEntries).expand((e) => e).map((e) => e.foodId).toSet().toList();
      final foodEntriesTotal = await Future.wait(distinctFoodIds.map((e) => diaryRepository.getFoodById(e.toString(), accessToken)));

      emit(CalendarMeetupUserDataFetched(
          meetups: meetups.map((e) => e.meetup).toList(),
          meetupLocations: meetups.map((e) => e.location).toList(),
          meetupDecisions: meetupDecisions,
          meetupParticipants: meetupParticipants,
          userIdProfileMap: userIdProfileMap,
          foodDiaryEntries: foodEntriesTotal,
          allDiaryEntries: diaryEntries,
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