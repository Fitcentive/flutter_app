import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/ad_widget/ad_widget.dart';
import 'package:flutter_app/src/infrastructure/home_page_ad_widget/home_page_ad_widget.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gauges/gauges.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class WidgetUtils {
  static Widget spacer(double allPadding) => Padding(padding: EdgeInsets.all(allPadding));

  static List<T> skipNulls<T>(List<T?> items) {
    return items.whereType<T>().toList();
  }

  static Widget viewUnderDismissibleListTile() {
    return Container(
      color: Colors.redAccent,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: const [
          Expanded(
            flex: 5,
              child: Center(
                  child: Text(
                    "Remove",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold
                    ),
                  )
              )
          ),
          Expanded(
              flex: 1,
              child: Icon(Icons.remove_circle, color: Colors.white,)
          ),
        ],
      ),
    );
    return Container(
      color: Colors.teal,
      child: const Text(
        "Swipe left to delete",
        style: TextStyle(
          color: Colors.white
        ),
      ),
    );
  }

  static Widget? generatePostImageIfExists(String? postImageUrl, bool isMockDataMode) {
    if (isMockDataMode) {
      if (postImageUrl != null) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            image: ImageUtils.getImageWithoutPublicGatewayBase(postImageUrl),
          ),
        );
      }
      return null;
    }
    else {
      if (postImageUrl != null) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            image: ImageUtils.getImage(postImageUrl, 500, 500),
          ),
        );
      }
      return null;
    }
  }

  static render180DegreeGauge(double score) {
    // Convert to 20-80 scale from 0-100 scale
    // y = mx + b where m = 3/5
    final scaledScore = ((3.0 / 5.0) * score) + 20;
    return SizedBox(
        height: 22,
        width: 70,
        child: RadialGauge(
          axes: [
            RadialGaugeAxis(
              color: Colors.transparent,
              maxValue: 100,
              minValue: 0,
              pointers: [
                RadialNeedlePointer(
                    minValue: 0,
                    maxValue: 100,
                    value: scaledScore,
                    thicknessStart: 6,
                    thicknessEnd: 0,
                    length: 0.6,
                    knobRadiusAbsolute: 3,
                    color: Colors.teal,
                    knobColor: Colors.teal
                )
              ],
              segments: const [
                RadialGaugeSegment(
                  minValue: 0,
                  maxValue: 20,
                  minAngle: -90,
                  maxAngle: -54,
                  color: Colors.redAccent,
                ),
                RadialGaugeSegment(
                  minValue: 21,
                  maxValue: 40,
                  minAngle: -54,
                  maxAngle: -18,
                  color: Colors.orangeAccent,
                ),
                RadialGaugeSegment(
                  minValue: 41,
                  maxValue: 60,
                  minAngle: -18,
                  maxAngle: 18,
                  color: Colors.yellowAccent,
                ),
                RadialGaugeSegment(
                  minValue: 61,
                  maxValue: 80,
                  minAngle: 18,
                  maxAngle: 54,
                  color: Colors.lightGreen,
                ),
                RadialGaugeSegment(
                  minValue: 81,
                  maxValue: 100,
                  minAngle: 54,
                  maxAngle: 90,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        )
    );
  }

  static Widget? showAdIfNeeded(BuildContext context, double maxHeight) {
    final CustomAdWidget customAdWidget = CustomAdWidget();
    if (DeviceUtils.isMobileDevice()) {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is AuthSuccessUserUpdateState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
      else if (authState is AuthSuccessState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
    }
    else {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is AuthSuccessUserUpdateState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
      else if (authState is AuthSuccessState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
    }
    return null;
  }

  static Widget? showHomePageAdIfNeeded(BuildContext context, double maxHeight) {
    final CustomHomePageAdWidget customAdWidget = CustomHomePageAdWidget();
    if (DeviceUtils.isMobileDevice()) {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is AuthSuccessUserUpdateState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
      else if (authState is AuthSuccessState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
    }
    else {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is AuthSuccessUserUpdateState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
      else if (authState is AuthSuccessState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return customAdWidget.render(context, maxHeight);
        }
      }
    }
    return null;
  }

  static bool isPremiumEnabledForUser(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    if (authState is AuthSuccessUserUpdateState) {
      return authState.authenticatedUser.user.isPremiumEnabled;
    }
    else if (authState is AuthSuccessState) {
      return authState.authenticatedUser.user.isPremiumEnabled;
    }
    return false;
  }

  static Widget? wrapAdWidgetWithUpgradeToMobileTextIfNeeded(Widget? adWidget, double maxHeight) {
    if (kIsWeb) {
      return IntrinsicHeight(
        child: Column(
          children: WidgetUtils.skipNulls([
            WidgetUtils.showUpgradeToMobileAppMessageIfNeeded(),
            adWidget,
          ]),
        ),
      );
    }
    else {
      return adWidget;
    }
  }

  static Widget? showUpgradeToMobileAppMessageIfNeeded() {
    if (kIsWeb) {
      return Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    children: [
                      TextSpan(
                        text: "For a better experience, ",
                        style: const TextStyle(
                            color: Colors.teal
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          // todo - link to benefits of better experience
                          launchUrl(Uri.parse(ConstantUtils.TERMS_AND_CONDITIONS_URL));
                        }
                      ),
                      const TextSpan(
                        text: "we recommend using the app for ",
                        style: TextStyle(
                            color: Colors.red
                        ),
                      ),
                      TextSpan(
                          text: "iOS",
                          style: const TextStyle(
                              color: Colors.teal
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            // todo - link to app store
                            launchUrl(Uri.parse(ConstantUtils.TERMS_AND_CONDITIONS_URL));
                          }
                      ),
                      const TextSpan(
                        text: " or ",
                        style: TextStyle(
                            color: Colors.red
                        ),
                      ),
                      TextSpan(
                          text: "Android",
                          style: const TextStyle(
                              color: Colors.teal
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            // todo - link to play store
                            launchUrl(Uri.parse(ConstantUtils.TERMS_AND_CONDITIONS_URL));
                          }
                      ),
                    ]
                )
            ),
          ),
        ],
      );
    }
    return null;
  }

  static void showUpgradeToPremiumDialog(
      BuildContext context,
      VoidCallback upgradeToPremiumCallback,
      {
      VoidCallback? cancelCallback,
      bool isCurrentlyInAccountDetailsScreen = false
  }) {
    _dialogContent() {
      return Column(
        children: [
          WidgetUtils.spacer(5),
          const Text(
            "Upgrade to Fitcentive+",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          const Text(
            "For just \$2.99 a month, you get...",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(5),
          const SizedBox(
              height: 200,
              child: Markdown(data: ConstantUtils.premiumFeatures)
          ),
          WidgetUtils.spacer(10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () async {
                    if (cancelCallback != null) {
                      cancelCallback();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
              const Expanded(
                  flex: 1,
                  child: Visibility(
                    visible: false,
                    child: Text(""),
                  )
              ),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    upgradeToPremiumCallback();
                  },
                  child: const Text(
                      "Upgrade",
                      style: TextStyle(fontSize: 15, color: Colors.white)
                  ),
                ),
              ),

            ],
          )
        ],
      );
    }

    _dialogContentCard() {
      return IntrinsicHeight(
        child: Card(
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: _dialogContent(),
              ),
            )
        ),
      );
    }

    showDialog(context: context, builder: (context) {
      return PointerInterceptor(
        child: Dialog(
          child: _dialogContentCard(),
        ),
      );
    });

  }
}