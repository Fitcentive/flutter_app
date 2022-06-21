import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/repos/user_repository.dart';
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
    on<PasswordResetRequested>(_passwordResetRequested);
  }

  void _emailAddressEnteredForVerification(
    EmailAddressEnteredForVerification event,
    Emitter<CreateAccountState> emit,
  ) async {
    await userRepository.requestNewEmailVerificationToken(event.email);
    emit(UnverifiedEmailAddress(event.email));
  }

  void _emailVerificationTokenSubmitted(
    EmailVerificationTokenSubmitted event,
    Emitter<CreateAccountState> emit,
  ) async {
    final booleanResult =
        await userRepository.verifyEmailVerificationToken(event.email, event.verificationToken.toUpperCase());

    if (booleanResult) {
      emit(VerifiedEmailAddress(event.email, event.verificationToken));
    } else {
      emit(InvalidEmailVerificationToken(event.email, event.verificationToken));
    }
  }

  void _passwordChanged(PasswordChanged event, Emitter<CreateAccountState> emit) async {
    final password = Password.dirty(event.password);
    final passwordConfirmation = Password.dirty(event.passwordConfirmation);

    final currentState = state;

    if (currentState is VerifiedEmailAddress) {
      emit(PasswordModified(email: event.email, token: currentState.verificationToken));
    }
    else if (currentState is PasswordModified) {

      final doPasswordsMatch = password.value == passwordConfirmation.value;
      final newStatus = Formz.validate([password, passwordConfirmation]);
      final finalStatus = doPasswordsMatch ? newStatus : FormzStatus.invalid;

      emit(currentState.copyWith(
        status: finalStatus,
        password: password,
        passwordConfirmation: passwordConfirmation
      ));
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
    } else if (currentState is UnverifiedEmailAddress) {
      emit(VerificationTokenModified(email: event.email, token: token, status: Formz.validate([token])));
    } else if (currentState is InvalidEmailVerificationToken) {
      emit(VerificationTokenModified(email: event.email, token: token, status: Formz.validate([token])));
    }
  }

  void _passwordResetRequested(
    PasswordResetRequested event,
    Emitter<CreateAccountState> emit,
  ) async {
    await userRepository.createNewUser(event.email, event.verificationToken);
    await userRepository.resetUserPassword(event.email, event.password, event.verificationToken);
    emit(const AccountCreatedSuccessfully());
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
    } else if (currentState is InitialState) {
      emit(EmailAddressModified(email: email, status: Formz.validate([email])));
    }
  }
}
