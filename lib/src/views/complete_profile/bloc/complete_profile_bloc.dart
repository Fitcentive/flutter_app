import 'dart:async';

import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/date_of_birth.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:flutter_app/src/models/complete_profile/username.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/models/user_agreements.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';

class CompleteProfileBloc extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final UserRepository userRepository;
  final AuthenticatedUserStreamRepository authUserStreamRepository;
  final FlutterSecureStorage secureStorage;

  CompleteProfileBloc({
    required this.userRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const InitialState()) {
    on<InitialEvent>(_initialEvent);
    on<CompleteProfileTermsAndConditionsChanged>(_termsAndConditionsChanged);
    on<CompleteProfileTermsAndConditionsSubmitted>(_termsAndConditionsSubmitted);
    on<ProfileInfoSubmitted>(_profileInfoSubmitted);
    on<ProfileInfoChanged>(_profileInfoChanged);
    on<UsernameChanged>(_usernameChanged);
    on<UsernameSubmitted>(_usernameSubmitted);
  }

  void _usernameSubmitted(
      UsernameSubmitted event,
      Emitter<CompleteProfileState> emit
      ) async {
    final currentState = state;
    if (currentState is UsernameModified) {
      final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
      final updateUser = UpdateUserPatch(accountStatus: "LoginReady", username: event.username);
      final updatedUser = await userRepository.updateUserPatch(event.user.user.id, updateUser, accessToken!);
      final updatedAuthenticatedUser = AuthenticatedUser(
          user: updatedUser,
          userAgreements: event.user.userAgreements,
          userProfile: event.user.userProfile,
          authTokens: event.user.authTokens,
          authProvider: event.user.authProvider
      );
      authUserStreamRepository.newUser(updatedAuthenticatedUser);
      emit(const ProfileInfoComplete());
    }
  }

  void _usernameChanged(
      UsernameChanged event,
      Emitter<CompleteProfileState> emit
      ) async {
    final username = Username.dirty(event.username);
    final currentState = state;
    final newStatus = Formz.validate([username]);

    if (currentState is UsernameModified) {
      if (newStatus.isValid) {
        final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
        final doesUsernameExistAlready = await userRepository.checkIfUsernameExists(event.username, accessToken!);
        emit(currentState.copyWith(
            status: newStatus,
            username: username,
            doesUsernameExistAlready: doesUsernameExistAlready
        ));
      }
      else {
        emit(currentState.copyWith(status: newStatus, username: username));
      }
    }
  }

  void _profileInfoSubmitted(ProfileInfoSubmitted event,
      Emitter<CompleteProfileState> emit,) async {
    final updateUserProfile = UpdateUserProfile(firstName: event.firstName,
        lastName: event.lastName,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(event.dateOfBirth)
    );
    const updateUser = UpdateUserPatch(accountStatus: "UsernameCreationRequired");
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final userProfile = await userRepository.createOrUpdateUserProfile(event.user.user.id, updateUserProfile, accessToken!);
    final updatedUser = await userRepository.updateUserPatch(event.user.user.id, updateUser, accessToken);
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: updatedUser,
        userAgreements: event.user.userAgreements,
        userProfile: userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);
    emit(UsernameModified(user: updatedAuthenticatedUser));
  }

  void _profileInfoChanged(ProfileInfoChanged event,
      Emitter<CompleteProfileState> emit,) async {
    final firstName = Name.dirty(event.firstName);
    final lastname = Name.dirty(event.lastName);
    final dateOfBirth = DateOfBirth.dirty(DateFormat('yyyy-MM-dd').format(event.dateOfBirth));
    final currentState = state;
    final newStatus = Formz.validate([firstName, lastname, dateOfBirth]);

    if (currentState is ProfileInfoModified) {
      emit(currentState.copyWith(
          status: newStatus,
          firstName: firstName,
          lastName: lastname,
          dateOfBirth: dateOfBirth
      ));
    }
  }

  void _termsAndConditionsSubmitted(CompleteProfileTermsAndConditionsSubmitted event,
      Emitter<CompleteProfileState> emit,) async {
    final updateAgreements = UpdateUserAgreements(
        termsAndConditionsAccepted: event.termsAndConditions,
        subscribeToEmails: event.marketingEmails
    );
    const updateUser = UpdateUserPatch(accountStatus: "ProfileInfoRequired");
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final userAgreements = await userRepository.updateUserAgreements(event.user.user.id, updateAgreements, accessToken!);
    final updatedUser =  await userRepository.updateUserPatch(event.user.user.id, updateUser, accessToken);
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: updatedUser,
        userAgreements: userAgreements,
        userProfile: event.user.userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);
    emit(ProfileInfoModified(user: updatedAuthenticatedUser));
  }

  void _termsAndConditionsChanged(CompleteProfileTermsAndConditionsChanged event,
      Emitter<CompleteProfileState> emit,) async {
    emit(CompleteProfileTermsAndConditionsModified(
        user: event.user, termsAndConditions: event.termsAndConditions, marketingEmails: event.marketingEmails));
  }

  void _initialEvent(InitialEvent event,
      Emitter<CompleteProfileState> emit,) async {
    switch (event.user.user.accountStatus) {
      case "TermsAndConditionsRequired":
        emit(CompleteProfileTermsAndConditionsModified(
            user: event.user, termsAndConditions: false, marketingEmails: false));
        break;
      case "ProfileInfoRequired":
        emit(ProfileInfoModified(user: event.user));
        break;
      case "UsernameCreationRequired":
        emit(UsernameModified(user: event.user));
        break;
      case "LoginReady":
        emit(const ProfileInfoComplete());
        break;
    }
  }
}
