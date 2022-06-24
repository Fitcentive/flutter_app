import 'package:formz/formz.dart';

enum NameValidationError { empty }

class Name extends FormzInput<String, NameValidationError> {
  const Name.pure() : super.pure('');

  const Name.dirty([String value = '']) : super.dirty(value);

  @override
  NameValidationError? validator(String? value) {
    if (value == null) {
      return NameValidationError.empty;
    }
    else if (value.isEmpty) {
      return NameValidationError.empty;
    }
    else {
      return null;
    }
  }

}
