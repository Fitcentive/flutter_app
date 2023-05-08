import 'package:equatable/equatable.dart';

class EmailAndPassword extends Equatable {
  final String email;
  final String password;

  const EmailAndPassword({
    required this.email,
    required this.password
  });

  @override
  List<Object> get props => [email, password];
}