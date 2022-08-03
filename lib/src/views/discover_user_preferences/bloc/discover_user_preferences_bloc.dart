import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/discover/user_discovery_preferences.dart';
import 'package:flutter_app/src/models/discover/user_fitness_preferences.dart';
import 'package:flutter_app/src/models/discover/user_personal_preferences.dart';
import 'package:flutter_app/src/models/spatial/coordinates.dart';
import 'package:flutter_app/src/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DiscoverUserPreferencesBloc extends Bloc<DiscoverUserPreferencesEvent, DiscoverUserPreferencesState> {
  final FlutterSecureStorage secureStorage;
  final DiscoverRepository discoverRepository;

  DiscoverUserPreferencesBloc({
    required this.discoverRepository,
    required this.secureStorage,
  }) : super(const DiscoverUserPreferencesStateInitial()) {
    on<DiscoverUserPreferencesInitial>(_discoverUserPreferencesInitial);
    on<UserDiscoverPreferencesChanged>(_userDiscoverPreferencesChanged);
    on<UserDiscoverLocationPreferencesChanged>(_userDiscoverLocationPreferencesChanged);
    on<UserDiscoverPreferredTransportModePreferencesChanged>(_userDiscoverPreferredTransportModePreferencesChanged);
    on<UserDiscoverActivityPreferencesChanged>(_userDiscoverActivityPreferencesChanged);
    on<UserDiscoverFitnessGoalsPreferencesChanged>(_userDiscoverFitnessGoalsPreferencesChanged);
    on<UserDiscoverBodyTypePreferencesChanged>(_userDiscoverBodyTypePreferencesChanged);
    on<UserDiscoverGenderPreferencesChanged>(_userDiscoverGenderPreferencesChanged);
    on<UserDiscoverDayPreferencesChanged>(_userDiscoverDayPreferencesChanged);
  }

  void _userDiscoverPreferencesChanged(
      UserDiscoverPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    emit(UserDiscoverPreferencesModified(
        userProfile: event.userProfile,
        locationCenter: event.locationCenter,
        locationRadius: event.locationRadius,
        preferredTransportMode: event.preferredTransportMode,
        activitiesInterestedIn: event.activitiesInterestedIn,
        fitnessGoals: event.fitnessGoals,
        desiredBodyTypes: event.desiredBodyTypes,
        gendersInterestedIn: event.gendersInterestedIn,
        preferredDays: event.preferredDays,
        minimumAge: event.minimumAge,
        maximumAge: event.maximumAge,
        hoursPerWeek: event.hoursPerWeek
    ));
  }

  void _discoverUserPreferencesInitial(
      DiscoverUserPreferencesInitial event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final latLng = event.discoveryPreferences == null ? null :
      LatLng(event.discoveryPreferences!.locationCenter.latitude, event.discoveryPreferences!.locationCenter.longitude);
    emit(UserDiscoverPreferencesModified(
        userProfile: event.userProfile,
        locationCenter: latLng,
        locationRadius: event.discoveryPreferences?.locationRadius,
        preferredTransportMode: event.discoveryPreferences?.preferredTransportMode,
        activitiesInterestedIn: event.fitnessPreferences?.activitiesInterestedIn,
        fitnessGoals: event.fitnessPreferences?.fitnessGoals,
        desiredBodyTypes: event.fitnessPreferences?.desiredBodyTypes,
        gendersInterestedIn: event.personalPreferences?.gendersInterestedIn,
        preferredDays: event.personalPreferences?.preferredDays,
        minimumAge: event.personalPreferences?.minimumAge,
        maximumAge: event.personalPreferences?.maximumAge,
        hoursPerWeek: event.personalPreferences?.hoursPerWeek
    ));
  }

  void _userDiscoverLocationPreferencesChanged(
      UserDiscoverLocationPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
  ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: event.locationCenter,
          locationRadius: event.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          preferredDays: currentState.preferredDays,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverPreferredTransportModePreferencesChanged(
      UserDiscoverPreferredTransportModePreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final userDiscoverPreferences = UserDiscoveryPreferencesPost(
          userId: currentState.userProfile.userId,
          preferredTransportMode: currentState.preferredTransportMode!,
          locationCenter: Coordinates(currentState.locationCenter!.latitude, currentState.locationCenter!.longitude),
          locationRadius: currentState.locationRadius!
      );
      // final response = await discoverRepository.upsertUserDiscoveryPreferences(
      //     currentState.userProfile.userId,
      //     userDiscoverPreferences,
      //     accessToken!
      // );

      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: event.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          preferredDays: currentState.preferredDays,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverActivityPreferencesChanged(
      UserDiscoverActivityPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: event.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          preferredDays: currentState.preferredDays,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverFitnessGoalsPreferencesChanged(
      UserDiscoverFitnessGoalsPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: event.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          preferredDays: currentState.preferredDays,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverBodyTypePreferencesChanged(
      UserDiscoverBodyTypePreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final prefs = UserFitnessPreferencesPost(
          userId: currentState.userProfile.userId,
          activitiesInterestedIn: currentState.activitiesInterestedIn!,
          fitnessGoals: currentState.fitnessGoals!,
          desiredBodyTypes: currentState.desiredBodyTypes!
      );
      // final response = await discoverRepository.upsertUserFitnessPreferences(
      //     currentState.userProfile.userId,
      //     prefs,
      //     accessToken!
      // );

      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: event.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          preferredDays: currentState.preferredDays,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverGenderPreferencesChanged(
      UserDiscoverGenderPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          preferredDays: currentState.preferredDays,
          gendersInterestedIn: event.gendersInterestedIn,
          minimumAge: event.minimumAge,
          maximumAge: event.maximumAge,
          hoursPerWeek: currentState.hoursPerWeek
      ));
    }
  }

  void _userDiscoverDayPreferencesChanged(
      UserDiscoverDayPreferencesChanged event,
      Emitter<DiscoverUserPreferencesState> emit
      ) async {

    final currentState = state;
    if (currentState is UserDiscoverPreferencesModified) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final prefs = UserPersonalPreferencesPost(
          userId: currentState.userProfile.userId,
          gendersInterestedIn: currentState.gendersInterestedIn!,
          preferredDays: currentState.preferredDays!,
          hoursPerWeek: currentState.hoursPerWeek!,
          minimumAge: currentState.minimumAge!,
          maximumAge: currentState.maximumAge!,
      );
      // final response = await discoverRepository.upsertUserPersonalPreferences(
      //     currentState.userProfile.userId,
      //     prefs,
      //     accessToken!
      // );
      // todo - re enable saving preferences once UI is stable

      emit(UserDiscoverPreferencesModified(
          userProfile: currentState.userProfile,
          locationCenter: currentState.locationCenter,
          locationRadius: currentState.locationRadius,
          preferredTransportMode: currentState.preferredTransportMode,
          activitiesInterestedIn: currentState.activitiesInterestedIn,
          fitnessGoals: currentState.fitnessGoals,
          desiredBodyTypes: currentState.desiredBodyTypes,
          gendersInterestedIn: currentState.gendersInterestedIn,
          minimumAge: currentState.minimumAge,
          maximumAge: currentState.maximumAge,
          preferredDays: event.preferredDays,
          hoursPerWeek: event.hoursPerWeek,
      ));
    }
  }
}