import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompleteProfileTermsAndConditionsView extends StatelessWidget {
  const CompleteProfileTermsAndConditionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -1 / 3),
      child: Padding(
          padding: EdgeInsets.all(12),
          child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Please review and accept the terms and conditions",
                      style: appTheme.textTheme.headline6,
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    _createCheckBox(
                        "I have read and accept to the terms and conditions", "termsAndConditions", context),
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
    final currentState = context.read<CompleteProfileBloc>().state;
    if (currentState is CompleteProfileTermsAndConditionsModified) {
      if (text == "termsAndConditions") {
        context.read<CompleteProfileBloc>().add(CompleteProfileTermsAndConditionsChanged(
            user: currentState.user, termsAndConditions: checkBoxState, marketingEmails: currentState.marketingEmails));
      } else {
        context.read<CompleteProfileBloc>().add(CompleteProfileTermsAndConditionsChanged(
            user: currentState.user,
            termsAndConditions: currentState.termsAndConditions,
            marketingEmails: checkBoxState));
      }
    }
  }

  _getCheckboxValue(String text, BuildContext context) {
    final currentState = context.read<CompleteProfileBloc>().state;
    if (currentState is CompleteProfileTermsAndConditionsModified) {
      return text == "termsAndConditions" ? currentState.termsAndConditions : currentState.marketingEmails;
    } else {
      return false;
    }
  }
}
