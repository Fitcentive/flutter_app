import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
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
          appBar: AppBar(title: const Text('Create new account')),
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
      _createAccountBloc.add(
          CreateNewAccountRequested(currentState.email, currentState.verificationToken, currentState.password));
    }
    return null;
  }

  MaterialColor _getBackgroundColor() {
    final currentState = _createAccountBloc.state;
    if (currentState is EmailAddressModified && currentState.status.isValid) {
      return Colors.blue;
    } else if (currentState is VerificationTokenModified && currentState.status.isValid) {
      return Colors.blue;
    } else if (currentState is PasswordModified && currentState.status.isValid) {
      return Colors.blue;
    } else if (currentState is TermsAndConditionsModified && currentState.isValidState()) {
      return Colors.blue;
    }
    else {
      return Colors.grey;
    }
  }

  Widget _pageViews() {
    return BlocListener<CreateAccountBloc, CreateAccountState>(
      listener: (context, state) {
        if (state is UnverifiedEmailAddress) {
          _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is VerifiedEmailAddress) {
          _pageController.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        }
        if (state is PasswordConfirmed) {
          _pageController.animateToPage(3, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
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
              children: [
                _enterNewEmailView(),
                _enterVerificationTokenView(),
                _enterNewPasswordView(),
                _termsAndConditionsView(),
              ],
            );
          }),
    );
  }

  Widget _termsAndConditionsView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please review the terms and conditions"),
            const Padding(padding: EdgeInsets.all(12)),
            _createCheckBox("I have read and accept to the terms and conditions", "termsAndConditions"),
            const Padding(padding: EdgeInsets.all(12)),
            _createCheckBox("I would like to subscribe to marketing emails", "marketingEmails"),
          ],
        ),
      ),
    );
  }

  _createCheckBox(String title, String key) {
    return CheckboxListTile(
      title: Text(title),
      value: _getCheckboxValue(key),
      onChanged: (newValue) {
        _onCheckBoxChanged(key, newValue ?? false);
      },
    );
  }

  _onCheckBoxChanged(String text, bool checkBoxState) {
    final currentState = _createAccountBloc.state;
    if (currentState is TermsAndConditionsModified) {
      if (text == "termsAndConditions") {
        _createAccountBloc.add(
            TermsAndConditionsChanged(
                email: currentState.email,
                password: currentState.password,
                verificationToken: currentState.verificationToken,
                termsAndConditions: checkBoxState,
                marketingEmails: currentState.marketingEmails
            ));
      }
      else {
        _createAccountBloc.add(
            TermsAndConditionsChanged(
                email: currentState.email,
                password: currentState.password,
                verificationToken: currentState.verificationToken,
                termsAndConditions: currentState.termsAndConditions,
                marketingEmails: checkBoxState
            ));
      }
    }
    else if (currentState is PasswordConfirmed) {
      if (text == "termsAndConditions") {
        _createAccountBloc.add(
            TermsAndConditionsChanged(
                email: currentState.email,
                password: currentState.password,
                verificationToken: currentState.verificationToken,
                termsAndConditions: checkBoxState,
                marketingEmails: false
            ));
      }
      else {
        _createAccountBloc.add(
            TermsAndConditionsChanged(
                email: currentState.email,
                password: currentState.password,
                verificationToken: currentState.verificationToken,
                termsAndConditions: false,
                marketingEmails: checkBoxState
            ));
      }
    }
  }

  _getCheckboxValue(String text) {
    final currentState = _createAccountBloc.state;
    if (currentState is TermsAndConditionsModified) {
      return text == "termsAndConditions" ? currentState.termsAndConditions : currentState.marketingEmails;
    }
    else {
      return false;
    }

  }

  Widget _enterNewPasswordView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _passwordWidget(),
            const Padding(padding: EdgeInsets.all(12)),
            _passwordConfirmationWidget(),
            const Padding(padding: EdgeInsets.all(12)),
          ],
        ),
      ),
    );
  }

  Widget _passwordWidget() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
            key: const Key('createAccountForm_passwordInput_textField'),
            onChanged: (password) {
              final currentState = _createAccountBloc.state;
              if (currentState is VerifiedEmailAddress) {
                context.read<CreateAccountBloc>().add(PasswordChanged(currentState.email, password, ""));
              } else if (currentState is PasswordModified) {
                _createAccountBloc
                    .add(PasswordChanged(currentState.email, password, currentState.passwordConfirmation.value));
              }
            },
            obscureText: true,
            decoration: _getPasswordWidgetDecoration("password"));
      },
    );
  }

  Widget _passwordConfirmationWidget() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
            key: const Key('createAccountForm_passwordInputConfirmation_textField'),
            onChanged: (password) {
              final currentState = _createAccountBloc.state;
              if (currentState is VerifiedEmailAddress) {
                context.read<CreateAccountBloc>().add(PasswordChanged(currentState.email, "", password));
              } else if (currentState is PasswordModified) {
                _createAccountBloc.add(PasswordChanged(currentState.email, currentState.password.value, password));
              }
            },
            obscureText: true,
            decoration: _getPasswordWidgetDecoration("passwordConfirmation"));
      },
    );
  }

  InputDecoration? _getPasswordWidgetDecoration(String key) {
    final currentState = _createAccountBloc.state;
    if (currentState is PasswordModified) {
      return InputDecoration(
        labelText: 'password',
        errorText: key == "password"
            ? (currentState.password.invalid ? 'invalid password' : null)
            : (currentState.doPasswordMatch()
            ? (currentState.passwordConfirmation.invalid ? 'invalid password' : null)
            : 'passwords do not match!'),
      );
    } else if (currentState is VerifiedEmailAddress) {
      return const InputDecoration(labelText: 'password');
    }
    return null;
  }

  Widget _enterVerificationTokenView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("Enter the verification token you received via email"),
            const Padding(padding: EdgeInsets.all(12)),
            BlocBuilder<CreateAccountBloc, CreateAccountState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return TextField(
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    key: const Key('createAccountForm_usernameInput_textField'),
                    onChanged: (token) {
                      final currentState = _createAccountBloc.state;

                      if (currentState is UnverifiedEmailAddress) {
                        context.read<CreateAccountBloc>().add(EmailVerificationTokenChanged(currentState.email, token));
                      } else if (currentState is VerificationTokenModified) {
                        context.read<CreateAccountBloc>().add(EmailVerificationTokenChanged(currentState.email, token));
                      } else if (currentState is InvalidEmailVerificationToken) {
                        context.read<CreateAccountBloc>().add(EmailVerificationTokenChanged(currentState.email, token));
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Verification Token',
                      alignLabelWithHint: true,
                      errorText: null,
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _enterNewEmailView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text("Enter the email address you wish to use"),
              const Padding(padding: EdgeInsets.all(12)),
              _usernameInput(),
              const Padding(padding: EdgeInsets.all(12)),
            ],
          )),
    );
  }

  _usernameInput() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
            key: const Key('createAccountForm_usernameInput_textField'),
            onChanged: (email) => context.read<CreateAccountBloc>().add(EmailAddressChanged(email)),
            decoration: _getDecoration(state));
      },
    );
  }

  InputDecoration _getDecoration(CreateAccountState state) {
    if (state is EmailAddressModified) {
      return InputDecoration(
        labelText: 'username',
        errorText: state.email.invalid ? 'invalid email address' : null,
      );
    } else {
      return const InputDecoration(
        labelText: 'username',
        errorText: null,
      );
    }
  }
}
