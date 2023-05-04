import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/misc_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/views/add_owner_availabilities_view.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateNewMeetupBloc extends Bloc<CreateNewMeetupEvent, CreateNewMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  List<Color> usedColoursThusFar = [];
  Map<int, DateTime> timeSegmentToDateTimeMap = {};

  CreateNewMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository,
    required this.userRepository
  }) : super(const CreateNewMeetupStateInitial()) {

    _setUpTimeSegmentDateTimeMap();
    on<NewMeetupChanged>(_newMeetupChanged);
    on<SaveNewMeetup>(_saveNewMeetup);
  }

  _setUpTimeSegmentDateTimeMap() {
    final now = DateTime.now();
    const numberOfIntervals = (AddOwnerAvailabilitiesViewState.availabilityEndHour - AddOwnerAvailabilitiesViewState.availabilityStartHour) * 2;
    final intervalsList = List.generate(numberOfIntervals, (i) => i);
    var i = 0;
    var k = 0;
    while (i < intervalsList.length) {
      timeSegmentToDateTimeMap[i] =
          DateTime(now.year, now.month, now.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 0, 0);
      timeSegmentToDateTimeMap[i+1] =
          DateTime(now.year, now.month, now.day, k + AddOwnerAvailabilitiesViewState.availabilityStartHour, 30, 0);

      i += 2;
      k += 1;
    }
  }

  void _saveNewMeetup(SaveNewMeetup event, Emitter<CreateNewMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    List <MeetupAvailabilityUpsert> availabilitiesToSave = MiscUtils.convertBooleanMatrixToAvailabilities(
        event.currentUserAvailabilities,
        timeSegmentToDateTimeMap,
    ).map((e) => MeetupAvailabilityUpsert(
      e.availabilityStart,
      e.availabilityEnd,
    )).toList();

    final newMeetup = MeetupCreate(
        ownerId: event.currentUserProfile.userId,
        meetupType: "Workout",
        name: event.meetupName,
        time: event.meetupTime,
        durationInMinutes: null, // Need to update things to include a time duration
        locationId: event.location?.locationId,
    );
    final meetup = await meetupRepository.createMeetup(newMeetup, accessToken!);
    // Add current user to participants list
    await meetupRepository.addParticipantToMeetup(meetup.id, event.currentUserProfile.userId, accessToken);
    await Future.wait(event.meetupParticipantUserIds.map((e) => meetupRepository.addParticipantToMeetup(meetup.id, e, accessToken)));
    // Add availabilities
    await meetupRepository.upsertMeetupParticipantAvailabilities(
        meetup.id,
        event.currentUserProfile.userId,
        accessToken,
        availabilitiesToSave
    );

    // Add owner decision as yes - since they control the details, they should be ok with it!
    await meetupRepository.upsertMeetupDecision(meetup.id, event.currentUserProfile.userId, true, accessToken);
  }

  void _newMeetupChanged(NewMeetupChanged event, Emitter<CreateNewMeetupState> emit) async {
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

      Map<String, BitmapDescriptor> userIdToMapMarkerIconSet = {};
      Map<String, Color> userIdToColorSet = {};
      final _random = Random();
      for (var element in [...userProfiles, event.currentUserProfile]) {
        // Generate colour
        var nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
        while (usedColoursThusFar.contains(nextColour)) {
          nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
        }
        userIdToColorSet[element.userId] = nextColour;

        // Generate marker
        userIdToMapMarkerIconSet[element.userId] = await _generateCustomMarkerForUser(element, userIdToColorSet[element.userId]!);
      }

      emit(MeetupModified(
          currentUserProfile: event.currentUserProfile,
          meetupTime: event.meetupTime,
          meetupName: event.meetupName,
          location: event.location,
          participantUserProfiles: userProfiles,
          participantUserProfilesCache: Map.fromEntries(userProfiles.map((e) => MapEntry(e.userId, e))),
          currentUserAvailabilities: event.currentUserAvailabilities,
          userIdToMapMarkerIconSet: userIdToMapMarkerIconSet,
          userIdToColorSet: userIdToColorSet,
      ));
    }
    else if (currentState is MeetupModified) {
      if (event.meetupParticipantUserIds.isNotEmpty) {
        bool doProfilesAlreadyExistForAll = event
            .meetupParticipantUserIds
            .map((element) => currentState
              .participantUserProfilesCache
              .entries
              .map((e) => e.key).contains(element))
            .reduce((value, element) => value && element);

        if (doProfilesAlreadyExistForAll) {
          emit(MeetupModified(
            currentUserProfile: event.currentUserProfile,
            meetupTime: event.meetupTime,
            meetupName: event.meetupName,
            location: event.location,
            participantUserProfiles: currentState
                .participantUserProfilesCache
                .entries
                .map((e) => e.value)
                .where((element) => event.meetupParticipantUserIds.contains(element.userId))
                .toList(),
            participantUserProfilesCache: currentState.participantUserProfilesCache,
            currentUserAvailabilities: event.currentUserAvailabilities,
            userIdToMapMarkerIconSet: currentState.userIdToMapMarkerIconSet,
            userIdToColorSet: currentState.userIdToColorSet,
          ));
        }
        else {
          final additionalUserIdsToGetProfilesFor = event
              .meetupParticipantUserIds
              .where((meetupParticipantId) => !currentState.participantUserProfiles.map((e) => e.userId).contains(meetupParticipantId))
              .toList();

          // Check cache to see if it exists
          final cacheProfilesOpt = additionalUserIdsToGetProfilesFor
              .map((e) => currentState.participantUserProfilesCache[e])
              .toList();

          final cacheHits = WidgetUtils.skipNulls(cacheProfilesOpt);
          final cacheMissesToFetchFor = additionalUserIdsToGetProfilesFor
              .where((element) => currentState.participantUserProfilesCache[element] == null)
              .toList();

          final additionalUserProfilesFetched =
            await userRepository.getPublicUserProfiles(cacheMissesToFetchFor, accessToken!);

          final additionalUserProfiles = [...additionalUserProfilesFetched, ...cacheHits];

          Map<String, BitmapDescriptor> additionalUserIdToMapMarkerIconSet = {};
          Map<String, Color> additionalUserIdToColorSet = {};
          final _random = Random();

          for (var element in additionalUserProfiles) {
            // Generate colour
            var nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
            while (usedColoursThusFar.contains(nextColour)) {
              nextColour = ColorUtils.circleColours[_random.nextInt(ColorUtils.circleColours.length)];
            }
            additionalUserIdToColorSet[element.userId] = nextColour;

            // Generate marker
            additionalUserIdToMapMarkerIconSet[element.userId] = await _generateCustomMarkerForUser(element, additionalUserIdToColorSet[element.userId]!);
          }

          final updatedProfileList = {...currentState.participantUserProfiles, ...additionalUserProfiles}.toList();
          emit(MeetupModified(
            currentUserProfile: event.currentUserProfile,
            meetupTime: event.meetupTime,
            meetupName: event.meetupName,
            location: event.location,
            participantUserProfiles: updatedProfileList,
            participantUserProfilesCache: Map.fromEntries(updatedProfileList.map((e) => MapEntry(e.userId, e))),
            currentUserAvailabilities: event.currentUserAvailabilities,
            userIdToMapMarkerIconSet: {...currentState.userIdToMapMarkerIconSet, ...additionalUserIdToMapMarkerIconSet},
            userIdToColorSet: {...currentState.userIdToColorSet, ...additionalUserIdToColorSet}
          ));
        }
      }
      else {
        final nextIconMap = currentState.userIdToMapMarkerIconSet;
        nextIconMap.removeWhere((key, value) => key != currentState.currentUserProfile.userId);
        final nextColorMap = currentState.userIdToColorSet;
        nextIconMap.removeWhere((key, value) => key != currentState.currentUserProfile.userId);

        emit(MeetupModified(
          currentUserProfile: event.currentUserProfile,
          meetupTime: event.meetupTime,
          meetupName: event.meetupName,
          location: event.location,
          participantUserProfiles: const [],
          participantUserProfilesCache: currentState.participantUserProfilesCache,
          currentUserAvailabilities: event.currentUserAvailabilities,
          userIdToMapMarkerIconSet: nextIconMap,
          userIdToColorSet: nextColorMap,
        ));
      }


    }

  }

  Future<BitmapDescriptor> _generateCustomMarkerForUser(PublicUserProfile userProfile, Color color) async {
    final fullImageUrl = ImageUtils.getFullImageUrl(userProfile.photoUrl, 96, 96);
    final request = await http.get(Uri.parse(fullImageUrl));
    return await ImageUtils.getMarkerIcon(request.bodyBytes, const Size(96, 96), color);
  }
}