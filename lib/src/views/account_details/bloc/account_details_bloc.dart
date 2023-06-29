import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/authenticated_user_stream_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:flutter_app/src/models/track/user_tracking_event.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

class AccountDetailsBloc extends Bloc<AccountDetailsEvent, AccountDetailsState> {
  final UserRepository userRepository;
  final PublicGatewayRepository publicGatewayRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  AccountDetailsBloc({
    required this.userRepository,
    required this.publicGatewayRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const InitialState()) {
    on<TrackViewCurrentUserAccountDetailsEvent>(_trackViewCurrentUserAccountDetailsEvent);
    on<AccountDetailsChanged>(_accountDetailsChanged);
    on<AccountDetailsSaved>(_accountDetailsSaved);
    on<EnablePremiumAccountStatusForUser>(_enablePremiumAccountStatusForUser);
    on<DisablePremiumAccountStatusForUser>(_disablePremiumAccountStatusForUser);
  }

  void _trackViewCurrentUserAccountDetailsEvent(TrackViewCurrentUserAccountDetailsEvent event, Emitter<AccountDetailsState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    userRepository.trackUserEvent(ViewCurrentUserAccountDetails(), accessToken!);
  }

  void _disablePremiumAccountStatusForUser(DisablePremiumAccountStatusForUser event, Emitter<AccountDetailsState> emit) async {
    final newPleb = User(
        event.user.user.id,
        event.user.user.email,
        event.user.user.username,
        event.user.user.accountStatus,
        event.user.user.authProvider,
        event.user.user.enabled,
        false,
        event.user.user.createdAt,
        event.user.user.updatedAt
    );
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: newPleb,
        userAgreements: event.user.userAgreements,
        userProfile: event.user.userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider,
        userTutorialStatus: event.user.userTutorialStatus,
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);

    final currentState = state;
    if (currentState is AccountDetailsModified) {
      emit(AccountDetailsUpdatedSuccessfully(
        user: updatedAuthenticatedUser,
        status: currentState.status,
        firstName: currentState.firstName,
        lastName: currentState.lastName,
        photoUrl: currentState.photoUrl,
        gender: currentState.gender,
      ));
    }
  }

  void _enablePremiumAccountStatusForUser(EnablePremiumAccountStatusForUser event, Emitter<AccountDetailsState> emit) async {
    final newPremiumUser = User(
        event.user.user.id,
        event.user.user.email,
        event.user.user.username,
        event.user.user.accountStatus,
        event.user.user.authProvider,
        event.user.user.enabled,
        true,
        event.user.user.createdAt,
        event.user.user.updatedAt
    );
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: newPremiumUser,
        userAgreements: event.user.userAgreements,
        userProfile: event.user.userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider,
        userTutorialStatus: event.user.userTutorialStatus,
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);

    final currentState = state;
    if (currentState is AccountDetailsModified) {
      emit(AccountDetailsUpdatedSuccessfully(
        user: updatedAuthenticatedUser,
        status: currentState.status,
        firstName: currentState.firstName,
        lastName: currentState.lastName,
        photoUrl: currentState.photoUrl,
        gender: currentState.gender,
      ));
    }
  }

  void _accountDetailsChanged(AccountDetailsChanged event, Emitter<AccountDetailsState> emit) async {
    final firstName = Name.dirty(event.firstName);
    final lastName = Name.dirty(event.lastName);
    final currentState = state;

    if (currentState is InitialState) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(AccountDetailsModified(
          user: event.user,
          status: formValidationStatus,
          firstName: firstName,
          lastName: lastName,
          photoUrl: event.photoUrl,
          gender: event.gender,
      ));
    } else if (currentState is AccountDetailsModified) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(currentState.copyWith(
          status: formValidationStatus,
          firstName: firstName,
          lastName: lastName,
          photoUrl: event.photoUrl,
          selectedImage: event.selectedImage,
          selectedImageName: event.selectedImageName,
          gender: event.gender,
      ));
    } else if (currentState is AccountDetailsUpdatedSuccessfully) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(AccountDetailsModified(
          user: event.user,
          status: formValidationStatus,
          firstName: firstName,
          lastName: lastName,
          photoUrl: event.photoUrl,
          gender: event.gender
      ));
    }
  }

  void _accountDetailsSaved(AccountDetailsSaved event, Emitter<AccountDetailsState> emit) async {
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    String? newPhotoUrl;
    if (event.selectedImage != null) {
      final filePath = "users/${event.user.user.id}/profile-photos/${event.selectedImageName}";
      newPhotoUrl = await publicGatewayRepository.uploadImage(filePath, event.selectedImage!, accessToken!);
    }
    final updateUserProfile = UpdateUserProfile(
      firstName: event.firstName,
      lastName: event.lastName,
      photoUrl: newPhotoUrl ?? event.photoUrl,
      dateOfBirth: event.user.userProfile?.dateOfBirth,
      gender: event.gender,
      locationCenter: event.user.userProfile?.locationCenter,
      locationRadius: event.user.userProfile?.locationRadius,
    );
    final updatedUserProfile = await userRepository.updateUserProfilePost(event.user.user.id, updateUserProfile, accessToken!);
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: event.user.user,
        userAgreements: event.user.userAgreements,
        userProfile: updatedUserProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider,
        userTutorialStatus: event.user.userTutorialStatus,
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);

    final currentState = state;
    if (currentState is AccountDetailsModified) {
      emit(AccountDetailsUpdatedSuccessfully(
          user: event.user,
          status: currentState.status,
          firstName: currentState.firstName,
          lastName: currentState.lastName,
          photoUrl: event.photoUrl,
          gender: event.gender,
      ));
    }

    userRepository.trackUserEvent(EditCurrentUserAccountDetails(), accessToken);
  }
}
