import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_app/src/views/create_account/views/enter_new_email_view.dart';
import 'package:flutter_app/src/views/create_account/views/enter_new_password_view.dart';
import 'package:flutter_app/src/views/create_account/views/enter_verification_token_view.dart';
import 'package:flutter_app/src/views/create_account/views/terms_and_conditions_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const CreateAccountPage());
  }

  @override
  State createState() {
    return CreateAccountPageState();
  }
}

class CreateAccountPageState extends State<CreateAccountPage> {
  late CreateAccountBloc _createAccountBloc;
  final PageController _pageController = PageController();

  static const int ENTER_NEW_EMAIL_PAGE = 0;
  static const int ENTER_VERIFICATION_TOKENS_PAGE = 1;
  static const int ENTER_PASSWORD_PAGE = 2;
  static const int ENTER_TERMS_PAGE = 3;

  static const MaterialColor BUTTON_AVAILABLE = Colors.teal;
  static const MaterialColor BUTTON_DISABLED = Colors.grey;


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _createAccountBloc = BlocProvider.of<CreateAccountBloc>(context);
    _createAccountBloc.add(const InitiateCreateAccountFlow());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _onBackPressed();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Sign up')),
          body: _pageViews(),
          floatingActionButton: _nextButton(),
        ));
  }

  _onBackPressed() {
    _createAccountBloc.add(const InitiateCreateAccountFlow());
  }

  _nextButton() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          return FloatingActionButton(
              onPressed: _onFloatingActionButtonPress,
              backgroundColor: _getBackgroundColor(),
              child: const Icon(Icons.navigate_next_sharp));
        });
  }

  VoidCallback? _onFloatingActionButtonPress() {
    final currentState = _createAccountBloc.state;
    if (currentState is EmailAddressModified && currentState.status.isValid) {
      _createAccountBloc.add(EmailAddressEnteredForVerification(currentState.email.value));
    } else if (currentState is VerificationTokenModified && currentState.status.isValid) {
      _createAccountBloc.add(EmailVerificationTokenSubmitted(currentState.email, currentState.token.value));
    } else if (currentState is PasswordModified && currentState.status.isValid) {
      _createAccountBloc.add(PasswordSubmitted(
          email: currentState.email, password: currentState.password.value, verificationToken: currentState.token));
    } else if (currentState is TermsAndConditionsModified && currentState.isValidState()) {
      _createAccountBloc.add(CreateNewAccountRequested(
        email: currentState.email,
        verificationToken: currentState.verificationToken,
        password: currentState.password,
        termsAndConditions: currentState.termsAndConditions,
        marketingEmails: currentState.marketingEmails,
      ));
    }
    return null;
  }

  MaterialColor _getBackgroundColor() {
    final currentState = _createAccountBloc.state;
    if (currentState is EmailAddressModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is VerificationTokenModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is PasswordModified && currentState.status.isValid) {
      return BUTTON_AVAILABLE;
    } else if (currentState is TermsAndConditionsModified && currentState.isValidState()) {
      return BUTTON_AVAILABLE;
    } else {
      return BUTTON_DISABLED;
    }
  }

  Widget _pageViews() {
    return BlocListener<CreateAccountBloc, CreateAccountState>(
      listener: (context, state) {
        if (state is UnverifiedEmailAddress) {
          _pageController.animateToPage(ENTER_VERIFICATION_TOKENS_PAGE, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is VerifiedEmailAddress) {
          _pageController.animateToPage(ENTER_PASSWORD_PAGE, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is PasswordConfirmed) {
          _pageController.animateToPage(ENTER_TERMS_PAGE, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is AccountCreatedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          Navigator.pop(context);
        }
        if (state is InvalidEmailVerificationToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email verification token!')),
          );
        }
        if (state is EmailAddressAlreadyInUse) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email address already in use!')),
          );
        }
      },
      child: BlocBuilder<CreateAccountBloc, CreateAccountState>(
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                EnterNewEmailView(),
                EnterVerificationTokenView(),
                EnterNewPasswordView(),
                TermsAndConditionsView(),
              ],
            );
          }),
    );
  }
}
