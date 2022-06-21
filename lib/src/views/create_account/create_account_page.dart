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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create new account')),
      body: _pageViews(),
      floatingActionButton: _nextButton(),
    );
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
      _createAccountBloc.add(PasswordResetRequested(currentState.email, currentState.token, currentState.password.value,
          currentState.passwordConfirmation.value));
    }
    else {
      print("FLOATING ACTION BUTTON ELSE CASE");
      print(currentState);
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
                const Text("Page 4`"),
              ],
            );
          }),
    );
  }

  Widget _enterNewPasswordView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _passwordWidget(),
          const Padding(padding: EdgeInsets.all(12)),
          _passwordConfirmationWidget(),
          const Padding(padding: EdgeInsets.all(12)),
        ],
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
                _createAccountBloc
                    .add(PasswordChanged(currentState.email, currentState.password.value, password));
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
            : (currentState.passwordConfirmation.invalid ? 'invalid password' : null),
      );
    } else if (currentState is VerifiedEmailAddress) {
      return const InputDecoration(labelText: 'password');
    }
    return null;
  }

  Widget _enterVerificationTokenView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text("Enter the verification token you received via email"),
          BlocBuilder<CreateAccountBloc, CreateAccountState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return TextField(
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
                    errorText: null,
                  ));
            },
          ),
        ],
      ),
    );
  }

  Widget _enterNewEmailView() {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text("Enter the email address you wish to use"),
          _UsernameInput(),
        ],
      ),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
