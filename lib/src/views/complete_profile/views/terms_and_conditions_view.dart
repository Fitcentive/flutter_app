import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_bloc.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_event.dart';
import 'package:flutter_app/src/views/complete_profile/bloc/complete_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class CompleteProfileTermsAndConditionsView extends StatelessWidget {
  const CompleteProfileTermsAndConditionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Align(
          alignment: const Alignment(0, -1 / 3),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: BlocBuilder<CompleteProfileBloc, CompleteProfileState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Please review and accept the terms and conditions",
                          style: Theme.of(context).textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                        const Padding(padding: EdgeInsets.all(20)),
                        _createCheckBox("I have read and accept to the terms and conditions", "termsAndConditions", context),
                        _createCheckBox("I have read and accept the privacy policy", "privacyPolicy", context),
                        _createCheckBox("I would like to subscribe to marketing emails", "marketingEmails", context),
                      ],
                    );
                  })),
        ),
      ),
    );
  }

  _createCheckBox(String title, String key, BuildContext context) {
    return CheckboxListTile(
      title: _getTitleText(title, key, context),
      value: _getCheckboxValue(key, context),
      onChanged: (newValue) {
        _onCheckBoxChanged(key, newValue ?? false, context);
      },
    );
  }

  _getTitleText(String title, String key, BuildContext context) {
    if (key == "termsAndConditions") {
      final parts = title.split("terms and conditions");
      return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: parts.first,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              TextSpan(
                text: "terms and conditions",
                style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.teal),
                recognizer: TapGestureRecognizer()..onTap = () {
                  launchUrl(Uri.parse(ConstantUtils.TERMS_AND_CONDITIONS_URL));
                }
              ),
            ]
          )
      );
    }
    else if (key == "privacyPolicy") {
      final parts = title.split("privacy policy");
      return RichText(
          text: TextSpan(
              children: [
                TextSpan(
                  text: parts.first,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                TextSpan(
                    text: "privacy policy",
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.teal),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      launchUrl(Uri.parse(ConstantUtils.PRIVACY_POLICY_URL));
                    }
                ),
              ]
          )
      );
    }
    else {
      return Text(
        title,
        style: Theme.of(context).textTheme.subtitle1,
      );
    }
  }

  _onCheckBoxChanged(String text, bool checkBoxState, BuildContext context) {
    final currentState = context.read<CompleteProfileBloc>().state;
    if (currentState is CompleteProfileTermsAndConditionsModified) {
      if (text == "termsAndConditions") {
        context.read<CompleteProfileBloc>().add(CompleteProfileTermsAndConditionsChanged(
            user: currentState.user,
            termsAndConditions: checkBoxState,
            marketingEmails: currentState.marketingEmails,
            privacyPolicy: currentState.privacyPolicy
        ));
      }
      else if (text == "privacyPolicy") {
        context.read<CompleteProfileBloc>().add(CompleteProfileTermsAndConditionsChanged(
            user: currentState.user,
            termsAndConditions: currentState.termsAndConditions,
            marketingEmails: currentState.marketingEmails,
            privacyPolicy: checkBoxState
        ));
      }
      else {
        context.read<CompleteProfileBloc>().add(CompleteProfileTermsAndConditionsChanged(
            user: currentState.user,
            termsAndConditions: currentState.termsAndConditions,
            marketingEmails: checkBoxState,
            privacyPolicy: currentState.privacyPolicy
        ));
      }
    }
  }

  _getCheckboxValue(String text, BuildContext context) {
    final currentState = context.read<CompleteProfileBloc>().state;
    if (currentState is CompleteProfileTermsAndConditionsModified) {
      return text == "termsAndConditions" ? currentState.termsAndConditions : (
          text == "privacyPolicy" ? currentState.privacyPolicy : currentState.marketingEmails
      );
    } else {
      return false;
    }
  }
}
