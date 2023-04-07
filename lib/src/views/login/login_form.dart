import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/auth/oidc_provider_info.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
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
import 'package:url_launcher/url_launcher.dart';

class LoginForm extends StatefulWidget {
  @override
  State createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    final currentAuthState = context.read<AuthenticationBloc>().state;
    if (currentAuthState is AuthInitialState) {
      context.read<AuthenticationBloc>().add(const InitiateAuthenticationFlow(email: "", password: ""));
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
              .add(InitiateAuthenticationFlow(email: _emailController.text, password: ""));
          // _usernameController.clear();
          _passwordController.clear();
        }
        if (state is AuthConflictState) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('User with email already exists! Login with password!')),
            );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          _emailInput(),
          const Padding(padding: EdgeInsets.all(12)),
          _passwordInput(),
          const Padding(padding: EdgeInsets.all(12)),
          _resetPasswordButton(),
          const Padding(padding: EdgeInsets.all(6)),
          _loginButton(),
          const Padding(padding: EdgeInsets.all(6)),
          _createAccountButton(),
          WidgetUtils.spacer(20),
          _googleLoginButton(),
          WidgetUtils.spacer(5),
          _appleLoginButton(),
          WidgetUtils.spacer(5),
          _facebookLoginButton(),
          WidgetUtils.spacer(25),
          _termsOfService(),
          WidgetUtils.spacer(5),
          _privacyPolicy(),
        ]),
      ),
    );
  }

  _termsOfService() {
    return RichText(
        text: TextSpan(
            children: [
              TextSpan(
                  text: "Terms and Conditions",
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.teal),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse(ConstantUtils.TERMS_AND_CONDITIONS_URL));
                  }
              ),
            ]
        )
    );
  }

  _privacyPolicy() {
    return RichText(
        text: TextSpan(
            children: [
              TextSpan(
                  text: "Privacy Policy",
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.teal),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse(ConstantUtils.PRIVACY_POLICY_URL));
                  }
              ),
            ]
        )
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

  // Only return facebook login button for Mobile as web doesn't work
  _facebookLoginButton() {
    if (!kIsWeb) {
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
  }

  _emailInput() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        return TextField(
            controller: _emailController,
            key: const Key('loginForm_usernameInput_textField'),
            onChanged: (username) {
              context.read<AuthenticationBloc>().add(LoginEmailChanged(username));
            },
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: (state is AuthCredentialsModified) && state.email.invalid ? 'Invalid email' : null,
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
            labelText: 'Password',
            errorText: (state is AuthCredentialsModified) && state.password.invalid ? 'Invalid password' : null,
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
                      .add(SignInWithEmailEvent(email: state.email.value, password: state.password.value));
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
