import 'package:flutter/material.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_bloc.dart';
import 'package:flutter_app/src/views/login/bloc/authentication_state.dart';
import 'package:flutter_app/src/views/shared_components/ads/custom_ad_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gauges/gauges.dart';

class WidgetUtils {
  static Widget spacer(double allPadding) => Padding(padding: EdgeInsets.all(allPadding));

  static List<T> skipNulls<T>(List<T?> items) {
    return items.whereType<T>().toList();
  }

  static Widget? generatePostImageIfExists(String? postImageUrl) {
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
    if (DeviceUtils.isMobileDevice()) {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is AuthSuccessUserUpdateState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return CustomAdWidget(maxHeight: maxHeight);
        }
      }
      else if (authState is AuthSuccessState) {
        if (authState.authenticatedUser.user.isPremiumEnabled) {
          return null;
        }
        else {
          return CustomAdWidget(maxHeight: maxHeight);
        }
      }
    }
    else {
      // todo - handle web implementation of ads using AdSense
      return null;
    }
    return null;
  }
}