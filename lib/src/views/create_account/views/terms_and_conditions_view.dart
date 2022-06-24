import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_bloc.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_event.dart';
import 'package:flutter_app/src/views/create_account/bloc/create_account_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
          padding: EdgeInsets.all(12),
          child: BlocBuilder<CreateAccountBloc, CreateAccountState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Almost there... Just one more thing",
                      style: appTheme.textTheme.headline6,
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    _createCheckBox("I have read and accept to the terms and conditions", "termsAndConditions", context),
                    // const Padding(paddingx: EdgeInsets.all(12)),
                    _createCheckBox("I would like to subscribe to marketing emails", "marketingEmails", context),
                  ],
                );
              })),
    );
  }

  _createCheckBox(String title, String key, BuildContext context) {
    return CheckboxListTile(
      title: Text(
        title,
        style: appTheme.textTheme.subtitle1,
      ),
      value: _getCheckboxValue(key, context),
      onChanged: (newValue) {
        _onCheckBoxChanged(key, newValue ?? false, context);
      },
    );
  }

  _onCheckBoxChanged(String text, bool checkBoxState, BuildContext context) {
    final currentState = context.read<CreateAccountBloc>().state;
    if (currentState is TermsAndConditionsModified) {
      if (text == "termsAndConditions") {
        context.read<CreateAccountBloc>().add(TermsAndConditionsChanged(
            email: currentState.email,
            password: currentState.password,
            verificationToken: currentState.verificationToken,
            termsAndConditions: checkBoxState,
            marketingEmails: currentState.marketingEmails));
      } else {
        context.read<CreateAccountBloc>().add(TermsAndConditionsChanged(
            email: currentState.email,
            password: currentState.password,
            verificationToken: currentState.verificationToken,
            termsAndConditions: currentState.termsAndConditions,
            marketingEmails: checkBoxState));
      }
    } else if (currentState is PasswordConfirmed) {
      if (text == "termsAndConditions") {
        context.read<CreateAccountBloc>().add(TermsAndConditionsChanged(
            email: currentState.email,
            password: currentState.password,
            verificationToken: currentState.verificationToken,
            termsAndConditions: checkBoxState,
            marketingEmails: false));
      } else {
        context.read<CreateAccountBloc>().add(TermsAndConditionsChanged(
            email: currentState.email,
            password: currentState.password,
            verificationToken: currentState.verificationToken,
            termsAndConditions: false,
            marketingEmails: checkBoxState));
      }
    }
  }

  _getCheckboxValue(String text, BuildContext context) {
    final currentState = context.read<CreateAccountBloc>().state;
    if (currentState is TermsAndConditionsModified) {
      return text == "termsAndConditions" ? currentState.termsAndConditions : currentState.marketingEmails;
    } else {
      return false;
    }
  }
}
