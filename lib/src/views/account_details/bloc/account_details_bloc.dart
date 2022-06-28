import 'package:flutter_app/src/models/complete_profile/name.dart';
import 'package:flutter_app/src/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_event.dart';
import 'package:flutter_app/src/views/account_details/bloc/account_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formz/formz.dart';

class AccountDetailsBloc extends Bloc<AccountDetailsEvent, AccountDetailsState> {
  final UserRepository userRepository;
  final FlutterSecureStorage secureStorage;

  AccountDetailsBloc({required this.userRepository, required this.secureStorage}) : super(const InitialState()) {
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
          status: formValidationStatus, firstName: firstName, lastName: lastName, photoUrl: event.photoUrl));
    } else if (currentState is AccountDetailsModified) {
      final formValidationStatus = Formz.validate([firstName, lastName]);
      emit(currentState.copyWith(
          status: formValidationStatus, firstName: firstName, lastName: lastName, photoUrl: event.photoUrl));
    }
  }

  void _accountDetailsSaved(AccountDetailsSaved event, Emitter<AccountDetailsState> emit) async {
    print("No implementation yet");
  }
}
