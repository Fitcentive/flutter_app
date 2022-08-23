import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/auth/oidc_provider_info.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/create_account/create_account_page.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/reset_password/reset_password_page.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:formz/formz.dart';

class LoginForm extends StatefulWidget {
  @override
  State createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    final currentAuthState = context.read<AuthenticationBloc>().state;
    if (currentAuthState is AuthInitialState) {
      context.read<AuthenticationBloc>().add(const InitiateAuthenticationFlow(username: "", password: ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Authentication Failure')),
            );
          context
              .read<AuthenticationBloc>()
              .add(InitiateAuthenticationFlow(username: _usernameController.text, password: ""));
          // _usernameController.clear();
          _passwordController.clear();
        }
      },
      child: Align(
        alignment: const Alignment(0, -1 / 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _usernameInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _passwordInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _resetPasswordButton(),
            const Padding(padding: EdgeInsets.all(6)),
            _loginButton(),
            const Padding(padding: EdgeInsets.all(6)),
            _createAccountButton(),
            const Padding(padding: EdgeInsets.all(30)),
            _googleLoginButton(),
            WidgetUtils.spacer(5),
            _appleLoginButton(),
            WidgetUtils.spacer(5),
            _facebookLoginButton(),
          ],
        ),
      ),
    );
  }

  _googleLoginButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SignInButton(
        DeviceUtils.isDarkMode(context) ? Buttons.Google : Buttons.GoogleDark,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        onPressed: () {
          context
              .read<AuthenticationBloc>()
              .add(const SignInWithOidcEvent(provider: OidcProviderInfo.GOOGLE_AUTH_PROVIDER));
        },
      )
    );
  }

  _appleLoginButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SignInButton(
        DeviceUtils.isDarkMode(context) ? Buttons.Apple : Buttons.AppleDark,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        onPressed: () {
          context
              .read<AuthenticationBloc>()
              .add(const SignInWithOidcEvent(provider: OidcProviderInfo.APPLE_AUTH_PROVIDER));
        },
      )
    );
  }

  _facebookLoginButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SignInButton(
        DeviceUtils.isDarkMode(context) ? Buttons.FacebookNew : Buttons.Facebook,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        onPressed: () {
          context
              .read<AuthenticationBloc>()
              .add(const SignInWithOidcEvent(provider: OidcProviderInfo.FACEBOOK_AUTH_PROVIDER));
        },
      ),
    );
  }

  _usernameInput() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        return TextField(
            controller: _usernameController,
            key: const Key('loginForm_usernameInput_textField'),
            onChanged: (username) {
              context.read<AuthenticationBloc>().add(LoginUsernameChanged(username));
            },
            decoration: InputDecoration(
              labelText: 'username',
              errorText: (state is AuthCredentialsModified) && state.username.invalid ? 'invalid username' : null,
            ));
      },
    );
  }

  _passwordInput() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        return TextField(
          controller: _passwordController,
          key: const Key('loginForm_passwordInput_textField'),
          onChanged: (password) {
            context.read<AuthenticationBloc>().add(LoginPasswordChanged(password));
          },
          obscureText: _isObscure,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            labelText: 'password',
            errorText: (state is AuthCredentialsModified) && state.password.invalid ? 'invalid password' : null,
          ),
        );
      },
    );
  }

  _createAccountButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil<void>(context, CreateAccountPage.route(), (route) => true);
      },
      child: const Text(
        "New user? Create new account",
        style: TextStyle(color: ColorConstants.primary500Teal),
      ),
    );
  }

  _resetPasswordButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil<void>(context, ResetPasswordPage.route(), (route) => true);
      },
      child: const Text(
        "Forgot password?",
        style: TextStyle(color: ColorConstants.primary500Teal),
      ),
    );
  }

  _loginButton() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        final currentState = state;
        if (currentState is AuthLoadingState) {
          return const CircularProgressIndicator();
        } else {
          return ElevatedButton(
              key: const Key('loginForm_continue_raisedButton'),
              child: const Text('Login'),
              style: ButtonStyle(backgroundColor: _getButtonBackgroundColour(state)),
              onPressed: () {
                if (state is AuthCredentialsModified && state.status.isValid) {
                  return context
                      .read<AuthenticationBloc>()
                      .add(SignInWithEmailEvent(email: state.username.value, password: state.password.value));
                }
              });
        }
      },
    );
  }

  _getButtonBackgroundColour(AuthenticationState state) {
    if (state is AuthCredentialsModified && state.status.isValid) {
      return MaterialStateProperty.all<Color>(Colors.teal);
    } else {
      return MaterialStateProperty.all<Color>(Colors.grey);
    }
  }
}
