import 'package:formz/formz.dart';

enum UsernameValidationError { empty, tooShort }

class Username extends FormzInput<String, UsernameValidationError> {
  const Username.pure() : super.pure('');

  const Username.dirty([String value = '']) : super.dirty(value);

  @override
  UsernameValidationError? validator(String? value) {
    if (value == null) {
      return UsernameValidationError.empty;
    }
    else if (value.isEmpty) {
      return UsernameValidationError.empty;
    }
    else if (value.length < 4) {
      return UsernameValidationError.tooShort;
    }
    else {
      return null;
    }
  }

}
