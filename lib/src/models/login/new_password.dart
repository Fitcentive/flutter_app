import 'package:formz/formz.dart';

enum NewPasswordValidationError { empty, tooWeak }

class NewPassword extends FormzInput<String, NewPasswordValidationError> {
  const NewPassword.pure() : super.pure('');
  const NewPassword.dirty([String value = '']) : super.dirty(value);

  @override
  NewPasswordValidationError? validator(String? value) {
    if (value?.isEmpty ?? false) {
      return NewPasswordValidationError.empty;
    }
    else {
      return value?.isNotEmpty == true && isPasswordValid(value) ? null : NewPasswordValidationError.tooWeak;
    }
  }

  /* Regex explanation
  r'^
    (?=.*[A-Z])             // should contain at least one upper case
    (?=.*[a-z])             // should contain at least one lower case
    (?=.*?[0-9])            // should contain at least one digit
    (?=.*?[!@#\$&*~^-_=+])  // should contain at least one Special character
    .{8,}                   // Must be at least 8 characters in length
  $
   */
  bool isPasswordValid(password) =>
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~^-_=+]).{8,}$').hasMatch(password);

}
