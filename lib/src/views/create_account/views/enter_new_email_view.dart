import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterNewEmailView extends StatelessWidget {

  const EnterNewEmailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Enter the email address you wish to use",
                style: Theme.of(context).textTheme.headline6,
              ),
              const Padding(padding: EdgeInsets.all(12)),
              _emailInput(),
              const Padding(padding: EdgeInsets.all(12)),
            ],
          )),
    );
  }

  _emailInput() {
    return BlocBuilder<CreateAccountBloc, CreateAccountState>(
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
        labelText: 'Email',
        errorText: state.email.invalid ? 'invalid email address' : null,
      );
    } else {
      return const InputDecoration(
        labelText: 'Email',
        errorText: null,
      );
    }
  }
}