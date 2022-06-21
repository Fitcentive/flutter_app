import 'package:formz/formz.dart';

enum EmailValidationError { empty }

class EmailVerificationToken extends FormzInput<String, EmailValidationError> {
  const EmailVerificationToken.pure() : super.pure('');

  const EmailVerificationToken.dirty([String value = '']) : super.dirty(value);

  @override
  EmailValidationError? validator(String? value) {
    return value?.isNotEmpty == true && isTokenValid(value) ? null : EmailValidationError.empty;
  }

  bool isTokenValid(String? token) => token?.length == 6;
}