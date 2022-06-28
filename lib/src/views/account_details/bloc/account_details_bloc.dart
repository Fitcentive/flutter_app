import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

class AccountDetailsBloc extends Bloc<AccountDetailsEvent, AccountDetailsState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  AccountDetailsBloc({
    required this.userRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const InitialState()) {
    on<AccountDetailsChanged>(_accountDetailsChanged);
    on<AccountDetailsSaved>(_accountDetailsSaved);
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
          photoUrl: event.photoUrl
      ));
    } else if (currentState is AccountDetailsModified) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(currentState.copyWith(
          status: formValidationStatus, firstName: firstName, lastName: lastName, photoUrl: event.photoUrl));
    } else if (currentState is AccountDetailsUpdatedSuccessfully) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(AccountDetailsModified(
          user: event.user,
          status: formValidationStatus,
          firstName: firstName,
          lastName: lastName,
          photoUrl: event.photoUrl
      ));
    }
  }

  void _accountDetailsSaved(AccountDetailsSaved event, Emitter<AccountDetailsState> emit) async {
    final accessToken = await secureStorage.read(key: event.user.authTokens.accessTokenSecureStorageKey);
    final updateUserProfile = UpdateUserProfile(
      firstName: event.firstName,
      lastName: event.lastName,
      photoUrl: event.photoUrl,
      dateOfBirth: event.user.userProfile?.dateOfBirth
    );
    final updatedUserProfile = await userRepository.updateUserProfilePost(event.user.user.id, updateUserProfile, accessToken!);
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: event.user.user,
        userAgreements: event.user.userAgreements,
        userProfile: updatedUserProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);

    final currentState = state;
    if (currentState is AccountDetailsModified) {
      emit(AccountDetailsUpdatedSuccessfully(
          user: event.user,
          status: currentState.status,
          firstName: currentState.firstName,
          lastName: currentState.lastName,
          photoUrl: event.photoUrl
      ));
    }
  }
}
