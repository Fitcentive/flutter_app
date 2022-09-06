import 'package:flutter/material.dart';
import 'login_form.dart';

class LoginPage extends StatelessWidget {
  static const String routeName = "login";

  const LoginPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => const LoginPage()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LoginForm(),
          ),
        ),
      ),
    );
  }

}
