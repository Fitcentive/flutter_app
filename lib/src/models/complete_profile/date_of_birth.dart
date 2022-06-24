import 'package:formz/formz.dart';

enum DateOfBirthValidationError { empty, invalidLength, invalidRange }

class DateOfBirth extends FormzInput<String, DateOfBirthValidationError> {

  const DateOfBirth.pure() : super.pure("2022-01-01");
  const DateOfBirth.dirty([String value = "2022-01-01" ]) : super.dirty(value);

  @override
  DateOfBirthValidationError? validator(String? value) {
    if (value == null) {
      return DateOfBirthValidationError.empty;
    }
    else if (value.isEmpty) {
      return DateOfBirthValidationError.empty;
    }
    else if (value.length != 10) {
      return DateOfBirthValidationError.invalidLength;
    }
    else {
      final dateTime = DateTime.parse(value);
      if (dateTime.year >= 1900 && dateTime.year <= 2010) {
        return null;
      }
      else {
        return DateOfBirthValidationError.invalidRange;
      }
    }
  }

}
