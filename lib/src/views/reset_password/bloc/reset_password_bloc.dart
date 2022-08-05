import 'package:flutter_app/src/models/login/email.dart';
import 'package:flutter_app/src/models/login/email_verification_token.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_event.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final UserRepository userRepository;

  ResetPasswordBloc({required this.userRepository}) : super(const InitialState()) {
    on<EmailAddressChanged>(_emailAddressChanged);
    on<EmailAddressEnteredForVerification>(_emailAddressEnteredForVerification);
    on<EmailVerificationTokenSubmitted>(_emailVerificationTokenSubmitted);
    on<EmailVerificationTokenChanged>(_emailVerificationTokenChanged);
    on<PasswordChanged>(_passwordChanged);
    on<PasswordSubmitted>(_passwordSubmitted);
  }

  void _emailAddressChanged(
    EmailAddressChanged event,
    Emitter<ResetPasswordState> emit,
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

  void _emailAddressEnteredForVerification(
    EmailAddressEnteredForVerification event,
    Emitter<ResetPasswordState> emit,
  ) async {
    final isVerificationTokenRequestSuccessful =
        await userRepository.requestPasswordResetVerificationToken(event.email);

    if (isVerificationTokenRequestSuccessful) {
      emit(VerificationTokenModified(email: event.email));
    } else {
      emit(UnrecognizedEmailAddress(event.email));
    }
  }

  void _emailVerificationTokenSubmitted(
      EmailVerificationTokenSubmitted event,
      Emitter<ResetPasswordState> emit,
      ) async {
    final booleanResult =
    await userRepository.verifyEmailVerificationToken(event.email, event.verificationToken.toUpperCase());

    if (booleanResult) {
      emit(PasswordModified(email: event.email, token: event.verificationToken));
    } else {
      emit(InvalidEmailVerificationToken(event.email, event.verificationToken));
    }
  }

  void _emailVerificationTokenChanged(EmailVerificationTokenChanged event, Emitter<ResetPasswordState> emit) async {
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

  void _passwordSubmitted(PasswordSubmitted event, Emitter<ResetPasswordState> emit) async {
    await userRepository.resetUserPassword(event.email, event.password, event.verificationToken.toUpperCase());
    emit(const PasswordResetSuccessfully());
  }

  void _passwordChanged(PasswordChanged event, Emitter<ResetPasswordState> emit) async {
    final password = Password.dirty(event.password);
    final passwordConfirmation = Password.dirty(event.passwordConfirmation);

    final currentState = state;
    if (currentState is PasswordModified) {
      final doPasswordsMatch = password.value == passwordConfirmation.value;
      final newStatus = Formz.validate([password, passwordConfirmation]);
      final finalStatus = doPasswordsMatch ? newStatus : FormzStatus.invalid;

      emit(currentState.copyWith(status: finalStatus, password: password, passwordConfirmation: passwordConfirmation));
    }
  }
}
