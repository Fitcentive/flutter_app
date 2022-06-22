import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterNewPasswordView extends StatefulWidget {

  const EnterNewPasswordView({Key? key}) : super(key: key);

  @override
  State createState() {
    return EnterNewPasswordViewState();
  }
}

class EnterNewPasswordViewState extends State<EnterNewPasswordView> {
  bool _isObscurePasswordField = true;
  bool _isObscurePasswordConfirmationField = true;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter a new password",
              style: appTheme.textTheme.headline6,
            ),
            const Padding(padding: EdgeInsets.all(12)),
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
              final currentState = context.read<CreateAccountBloc>().state;
              if (currentState is VerifiedEmailAddress) {
                context.read<CreateAccountBloc>().add(PasswordChanged(currentState.email, password, ""));
              } else if (currentState is PasswordModified) {
                context
                    .read<CreateAccountBloc>()
                    .add(PasswordChanged(currentState.email, password, currentState.passwordConfirmation.value));
              }
            },
            obscureText: _isObscurePasswordField,
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
              final currentState = context.read<CreateAccountBloc>().state;
              if (currentState is VerifiedEmailAddress) {
                context.read<CreateAccountBloc>().add(PasswordChanged(currentState.email, "", password));
              } else if (currentState is PasswordModified) {
                context
                    .read<CreateAccountBloc>()
                    .add(PasswordChanged(currentState.email, currentState.password.value, password));
              }
            },
            obscureText: _isObscurePasswordConfirmationField,
            decoration: _getPasswordWidgetDecoration("passwordConfirmation"));
      },
    );
  }

  InputDecoration? _getPasswordWidgetDecoration(String key) {
    final currentState = context.read<CreateAccountBloc>().state;
    if (currentState is PasswordModified) {
      return InputDecoration(
        suffixIcon: IconButton(
          icon: _getSuffixIcon(key),
          onPressed: () {
            setState(() {
              if (key == "password") {
                _isObscurePasswordField = !_isObscurePasswordField;
              }
              else {
                _isObscurePasswordConfirmationField = !_isObscurePasswordConfirmationField;
              }
            });
          },
        ),
        labelText: 'password',
        errorText: _getErrorText(key, currentState),
      );
    } else if (currentState is VerifiedEmailAddress) {
      return const InputDecoration(labelText: 'password');
    }
    return null;
  }

  _getErrorText(String key, PasswordModified state) {
    if (key == "password") {
      return state.password.invalid ? 'invalid password' : null;
    }
    else {
      if (state.doPasswordMatch()) {
        return state.passwordConfirmation.invalid ? 'invalid password' : null;
      }
      else {
        return 'passwords do not match!';
      }
    }
  }

  _getSuffixIcon(String key) {
    if (key == "password") {
      return Icon(_isObscurePasswordField ? Icons.visibility : Icons.visibility_off);
    }
    else {
      return Icon(_isObscurePasswordConfirmationField ? Icons.visibility : Icons.visibility_off);
    }
  }
}