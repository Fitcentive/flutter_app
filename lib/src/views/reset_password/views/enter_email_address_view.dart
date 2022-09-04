import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_bloc.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_event.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterEmailAddressView extends StatelessWidget {

  const EnterEmailAddressView({Key? key}) : super(key: key);

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
                "Enter the email address associated with your account",
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.all(12)),
              _emailInput(),
              const Padding(padding: EdgeInsets.all(12)),
            ],
          )),
    );
  }

  _emailInput() {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return TextField(
            key: const Key('resetPasswordForm_usernameInput_textField'),
            onChanged: (email) => context.read<ResetPasswordBloc>().add(EmailAddressChanged(email)),
            decoration: _getDecoration(state));
      },
    );
  }

  InputDecoration _getDecoration(ResetPasswordState state) {
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