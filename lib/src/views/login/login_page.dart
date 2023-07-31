import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/firebase/push_notification_settings.dart';
import 'login_form.dart';
class LoginPage extends StatefulWidget {

  static const String routeName = "login";

  const LoginPage({super.key});


  static Route route() {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => const LoginPage()
    );
  }

  @override
  State createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {


  @override
  void initState() {
    super.initState();

    // Only request permissions here, do actual setup in homepage for context reasons
    // If we do not ask permissions here, then an error could happen when syncing FCM device token with BE
    PushNotificationSettings.requestPermissionsIfNeeded(FirebaseMessaging.instance);
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
