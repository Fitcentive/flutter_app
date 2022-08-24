import 'package:formz/formz.dart';

enum LoginPasswordValidationError { empty }

class LoginPassword extends FormzInput<String, LoginPasswordValidationError> {
  const LoginPassword.pure() : super.pure('');
  const LoginPassword.dirty([String value = '']) : super.dirty(value);

  @override
  LoginPasswordValidationError? validator(String? value) {
    return value?.isNotEmpty == true ? null : LoginPasswordValidationError.empty;
  }
}
