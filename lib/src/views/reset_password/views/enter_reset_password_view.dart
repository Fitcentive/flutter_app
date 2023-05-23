import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_bloc.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_event.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class EnterResetPasswordView extends StatefulWidget {

  const EnterResetPasswordView({Key? key}) : super(key: key);

  @override
  State createState() {
    return EnterResetPasswordViewState();
  }
}

class EnterResetPasswordViewState extends State<EnterResetPasswordView> {
  bool _isObscurePasswordField = true;
  bool _isObscurePasswordConfirmationField = true;

  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter a new password",
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.all(12)),
              _passwordWidget(),
              const Padding(padding: EdgeInsets.all(12)),
              _passwordConfirmationWidget(),
              const Padding(padding: EdgeInsets.all(12)),
              const SizedBox(
                  height: 200,
                  child: Markdown(data: ConstantUtils.passwordRules)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordWidget() {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return TextField(
            focusNode: focusNode,
            key: const Key('resetPasswordForm_passwordInput_textField'),
            onChanged: (password) {
              final currentState = context.read<ResetPasswordBloc>().state;
              if (currentState is PasswordModified) {
                context
                    .read<ResetPasswordBloc>()
                    .add(PasswordChanged(currentState.email, password, currentState.passwordConfirmation.value));
              }
            },
            obscureText: _isObscurePasswordField,
            decoration: _getPasswordWidgetDecoration("password"));
      },
    );
  }

  Widget _passwordConfirmationWidget() {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return TextField(
            key: const Key('resetPasswordForm_passwordInputConfirmation_textField'),
            onChanged: (password) {
              final currentState = context.read<ResetPasswordBloc>().state;
              if (currentState is PasswordModified) {
                context
                    .read<ResetPasswordBloc>()
                    .add(PasswordChanged(currentState.email, currentState.password.value, password));
              }
            },
            obscureText: _isObscurePasswordConfirmationField,
            decoration: _getPasswordWidgetDecoration("passwordConfirmation"));
      },
    );
  }

  InputDecoration? _getPasswordWidgetDecoration(String key) {
    final currentState = context.read<ResetPasswordBloc>().state;
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