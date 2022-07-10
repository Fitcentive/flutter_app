import 'package:formz/formz.dart';

enum NewPostValidationError { empty }

class NewPost extends FormzInput<String, NewPostValidationError> {
  const NewPost.pure() : super.pure('');
  const NewPost.dirty([String value = '']) : super.dirty(value);

  @override
  NewPostValidationError? validator(String? value) {
    return value?.isNotEmpty == true ? null : NewPostValidationError.empty;
  }
}
