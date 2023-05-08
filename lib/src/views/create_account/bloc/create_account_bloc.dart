import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/new_password.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class CreateAccountBloc extends Bloc<CreateAccountEvent, CreateAccountState> {
  final UserRepository userRepository;

  CreateAccountBloc({required this.userRepository}) : super(const InitialState()) {
    on<EmailAddressChanged>(_emailAddressChanged);
    on<EmailAddressEnteredForVerification>(_emailAddressEnteredForVerification);
    on<EmailVerificationTokenSubmitted>(_emailVerificationTokenSubmitted);
    on<EmailVerificationTokenChanged>(_emailVerificationTokenChanged);
    on<PasswordChanged>(_passwordChanged);
    on<PasswordSubmitted>(_passwordSubmitted);
    on<TermsAndConditionsChanged>(_termsAndConditionsChanged);
    on<CreateNewAccountRequested>(_createNewAccountRequested);
  }

  void _termsAndConditionsChanged(
    TermsAndConditionsChanged event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(TermsAndConditionsModified(
        email: event.email,
        password: event.password,
        verificationToken: event.verificationToken,
        termsAndConditions: event.termsAndConditions,
        marketingEmails: event.marketingEmails,
        privacyPolicy: event.privacyPolicy,
    ));
  }

  void _emailAddressEnteredForVerification(
    EmailAddressEnteredForVerification event,
    Emitter<CreateAccountState> emit,
  ) async {
    final doesUserExist = await userRepository.checkIfUserExistsForEmail(event.email);

    if (doesUserExist) {
      emit(EmailAddressAlreadyInUse(event.email));
    } else {
      emit(VerificationTokenModified(email: event.email));
      await userRepository.requestNewEmailVerificationToken(event.email);
    }
  }

  void _emailVerificationTokenSubmitted(
    EmailVerificationTokenSubmitted event,
    Emitter<CreateAccountState> emit,
  ) async {
    final booleanResult =
        await userRepository.verifyEmailVerificationToken(event.email, event.verificationToken.toUpperCase());

    if (booleanResult) {
      emit(PasswordModified(email: event.email, token: event.verificationToken));
    } else {
      emit(InvalidEmailVerificationToken(event.email, event.verificationToken));
    }
  }

  void _passwordSubmitted(PasswordSubmitted event, Emitter<CreateAccountState> emit) async {
    emit(TermsAndConditionsModified(
        email: event.email,
        password: event.password,
        verificationToken: event.verificationToken,
        termsAndConditions: false,
        marketingEmails: false,
        privacyPolicy: false,
    ));
  }

  void _passwordChanged(PasswordChanged event, Emitter<CreateAccountState> emit) async {
    final password = NewPassword.dirty(event.password);
    final passwordConfirmation = NewPassword.dirty(event.passwordConfirmation);

    final currentState = state;

    if (currentState is PasswordModified) {
      final doPasswordsMatch = password.value == passwordConfirmation.value;
      final newStatus = Formz.validate([password, passwordConfirmation]);
      final finalStatus = doPasswordsMatch ? newStatus : FormzStatus.invalid;

      emit(currentState.copyWith(status: finalStatus, password: password, passwordConfirmation: passwordConfirmation));
    }
  }

  void _emailVerificationTokenChanged(EmailVerificationTokenChanged event, Emitter<CreateAccountState> emit) async {
    final token = EmailVerificationToken.dirty(event.token);
    final currentState = state;

    if (currentState is VerificationTokenModified) {
      emit(currentState.copyWith(
        token: token,
        status: Formz.validate([token]),
      ));
    } else if (currentState is InvalidEmailVerificationToken) {
      emit(VerificationTokenModified(email: event.email, token: token, status: Formz.validate([token])));
    }
  }

  void _createNewAccountRequested(
    CreateNewAccountRequested event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(const AccountBeingCreated());
    await userRepository.createNewUser(
        event.email,
        event.verificationToken.toUpperCase(),
        event.termsAndConditions,
        event.marketingEmails,
        event.privacyPolicy
    );
    await userRepository.resetUserPassword(event.email, event.password, event.verificationToken.toUpperCase());
    emit(AccountCreatedSuccessfully(email: event.email, password: event.password));
  }

  void _emailAddressChanged(
    EmailAddressChanged event,
    Emitter<CreateAccountState> emit,
  ) async {
    final email = Email.dirty(event.email);
    final currentState = state;

    if (currentState is EmailAddressModified) {
      emit(currentState.copyWith(
        email: email,
        status: Formz.validate([email]),
      ));
    } else {
      emit(EmailAddressModified(email: email, status: Formz.validate([email])));
    }
  }
}
