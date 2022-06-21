import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    context.read<AuthenticationBloc>().add(const InitiateAuthenticationFlow(username: "", password: ""));
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
            _loginButton(),
            const Padding(padding: EdgeInsets.all(6)),
            _createAccountButton(),
          ],
        ),
      ),
    );
  }

  _usernameInput() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous != current,
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
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
          controller: _passwordController,
          key: const Key('loginForm_passwordInput_textField'),
          onChanged: (password) {
            context.read<AuthenticationBloc>().add(LoginPasswordChanged(password));
          },
          obscureText: true,
          decoration: InputDecoration(
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
        Navigator.pushNamed(context, '/create-account');
      },
      child: const Text(
        "New user? Create new account",
        style: TextStyle(color: Color.fromRGBO(48, 134, 192, 1.0)),
      ),
    );
  }

  _loginButton() {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous != current,
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
      return MaterialStateProperty.all<Color>(Colors.blue);
    } else {
      return MaterialStateProperty.all<Color>(Colors.grey);
    }
  }
}
