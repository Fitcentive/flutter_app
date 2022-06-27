import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_bloc.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_event.dart';
import 'package:flutter_app/src/views/reset_password/bloc/reset_password_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterResetVerificationTokenView extends StatelessWidget {

  const EnterResetVerificationTokenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Enter the verification token you received via email",
              style: appTheme.textTheme.headline6,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
              builder: (context, state) {
                return TextField(
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    key: const Key('createAccountForm_usernameInput_textField'),
                    onChanged: (token) {
                      final currentState = context.read<ResetPasswordBloc>().state;
                      if (currentState is VerificationTokenModified) {
                        context.read<ResetPasswordBloc>().add(EmailVerificationTokenChanged(currentState.email, token));
                      } else if (currentState is InvalidEmailVerificationToken) {
                        context.read<ResetPasswordBloc>().add(EmailVerificationTokenChanged(currentState.email, token));
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Verification Token',
                      alignLabelWithHint: true,
                      errorText: null,
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}