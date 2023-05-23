import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/login/email_and_password.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_bloc.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_event.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_state.dart';
import 'package:flutter_app/src/views/reset_password/views/enter_email_address_view.dart';
import 'package:flutter_app/src/views/reset_password/views/enter_reset_password_view.dart';
import 'package:flutter_app/src/views/reset_password/views/enter_reset_verification_token.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class ResetPasswordPage extends StatefulWidget {
  static const String routeName = "reset-password";

  const ResetPasswordPage({Key? key}) : super(key: key);

  static Route<EmailAndPassword> route() {
    return MaterialPageRoute<EmailAndPassword>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<ResetPasswordBloc>(
                create: (context) => ResetPasswordBloc(
                  userRepository: RepositoryProvider.of<UserRepository>(context),
                )),
          ],
          child: const ResetPasswordPage(),
        ));
  }

  @override
  State createState() {
    return ResetPasswordPageState();
  }
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  late ResetPasswordBloc _resetPasswordBloc;
  final PageController _pageController = PageController();

  static const int ENTER_EMAIL_PAGE = 0;
  static const int ENTER_VERIFICATION_TOKENS_PAGE = 1;
  static const int ENTER_PASSWORD_PAGE = 2;

  static const MaterialColor BUTTON_AVAILABLE = Colors.teal;
  static const MaterialColor BUTTON_DISABLED = Colors.grey;


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _resetPasswordBloc = BlocProvider.of<ResetPasswordBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _pageViews(),
      floatingActionButton: _nextButton(),
    );
  }

  _nextButton() {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
        builder: (context, state) {
          return FloatingActionButton(
              heroTag: "ResetPasswordPageNextButton",
              onPressed: _onFloatingActionButtonPress,
              backgroundColor: _getBackgroundColor(),
              child: const Icon(Icons.navigate_next_sharp, color: Colors.white));
        });
  }

  VoidCallback? _onFloatingActionButtonPress() {
    final currentState = _resetPasswordBloc.state;
    if (currentState is EmailAddressModified && currentState.status.isValid) {
      _resetPasswordBloc.add(EmailAddressEnteredForVerification(currentState.email.value));
      SnackbarUtils.showSnackBarShort(context, "Hang on while we verify your email...");
    } else if (currentState is VerificationTokenModified && currentState.status.isValid) {
      _resetPasswordBloc.add(EmailVerificationTokenSubmitted(currentState.email, currentState.token.value));
      SnackbarUtils.showSnackBarShort(context, "Hang on while we verify your token...");
    } else if (currentState is PasswordModified && currentState.status.isValid) {
      SnackbarUtils.showSnackBarShort(context, "Almost there... hold on while we reset your password");
      _resetPasswordBloc.add(
          PasswordSubmitted(
              email: currentState.email,
              password: currentState.password.value,
              verificationToken: currentState.token
          )
      );
    }
    return null;
  }

  MaterialColor _getBackgroundColor() {
    final currentState = _resetPasswordBloc.state;
    if (currentState is EmailAddressModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is VerificationTokenModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is PasswordModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else {
      return BUTTON_DISABLED;
    }
  }

  Widget _pageViews() {
    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is VerificationTokenModified) {
          _pageController.animateToPage(ENTER_VERIFICATION_TOKENS_PAGE, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is PasswordModified) {
          _pageController.animateToPage(ENTER_PASSWORD_PAGE, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is PasswordResetSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successful!')),
          );
          Navigator.pop(context, EmailAndPassword(email: state.email, password: state.password));
        }
        if (state is InvalidEmailVerificationToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email verification token!')),
          );
        }
        if (state is UnrecognizedEmailAddress) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email address not found!')),
          );
        }
      },
      child: BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
          builder: (context, state) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                EnterEmailAddressView(),
                EnterResetVerificationTokenView(),
                EnterResetPasswordView(),
              ],
            );
          }),
    );
  }
}
