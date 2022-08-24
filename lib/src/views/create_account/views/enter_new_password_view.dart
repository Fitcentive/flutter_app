import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/models/login/password.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class EnterNewPasswordView extends StatefulWidget {

  const EnterNewPasswordView({Key? key}) : super(key: key);

  @override
  State createState() {
    return EnterNewPasswordViewState();
  }
}

class EnterNewPasswordViewState extends State<EnterNewPasswordView> {
  static const String passwordRules = """
  ### Password rules
  - At least one uppercase character
  - At least one lowercase character
  - At least one digit
  - At least one special character
  - At least 8 characters in length
  """;
  
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
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter a new password",
                style: Theme.of(context).textTheme.headline6,
              ),
              const Padding(padding: EdgeInsets.all(12)),
              _passwordWidget(),
              const Padding(padding: EdgeInsets.all(12)),
              _passwordConfirmationWidget(),
              const Padding(padding: EdgeInsets.all(12)),
              const SizedBox(
                height: 200,
                child: Markdown(data: passwordRules)
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _passwordWidget() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
      builder: (context, state) {
        return TextField(
            focusNode: focusNode,
            key: const Key('createAccountForm_passwordInput_textField'),
            onChanged: (password) {
              final currentState = context.read<CreateAccountBloc>().state;
              if (currentState is PasswordModified) {
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
      builder: (context, state) {
        return TextField(
            key: const Key('createAccountForm_passwordInputConfirmation_textField'),
            onChanged: (password) {
              final currentState = context.read<CreateAccountBloc>().state;
              if (currentState is PasswordModified) {
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
    }
    return null;
  }

  _getErrorText(String key, PasswordModified state) {
    if (key == "password") {
      return state.password.invalid ?
        (state.password.error == PasswordValidationError.tooWeak ? 'Password too weak' : 'Invalid password') : null;
    }
    else {
      if (state.doPasswordMatch()) {
        return state.passwordConfirmation.invalid ?
          (state.passwordConfirmation.error == PasswordValidationError.tooWeak ? 'Password too weak' : 'Invalid password') : null;
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