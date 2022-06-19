import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_event.dart';
import 'package:flutter_app/src/views/authentication/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';


class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    context.read<AuthenticationBloc>().add(InitiateAuthenticationFlow());

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        print("BlocListener for AUthneticationBloc in LoginFOrm widget");

        if (state is AuthLoginState && state.status.isSubmissionFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Authentication Failure')),
            );
        }
        else {
          print(state);
        }
      },
      child: Align(
        alignment: const Alignment(0, -1 / 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UsernameInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _PasswordInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _LoginButton(),
          ],
        ),
      ),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
          key: const Key('loginForm_usernameInput_textField'),
          onChanged: (username) => context.read<AuthenticationBloc>().add(LoginUsernameChanged(username)),
          decoration: (state is AuthLoginState) ? InputDecoration(
            labelText: 'username',
            errorText: state.username.invalid ? 'invalid username' : null,
          ) : null,
        );
      },
    );
  }
}

class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return TextField(
          key: const Key('loginForm_passwordInput_textField'),
          onChanged: (password) => context.read<AuthenticationBloc>().add(LoginPasswordChanged(password)),
          obscureText: true,
          decoration: (state is AuthLoginState) ? InputDecoration(
            labelText: 'password',
            errorText: state.password.invalid ? 'invalid password' : null,
          ) : null,
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final currentState = state;
        if (currentState is AuthLoginState) {
          return ElevatedButton(
            key: const Key('loginForm_continue_raisedButton'),
            child: const Text('Login'),
            onPressed: currentState.status.isValidated
                ? () {
                    context.read<AuthenticationBloc>().add(SignInWithEmailEvent(
                        email: currentState.username.value, password: currentState.password.value));
                  }
                : null,
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
