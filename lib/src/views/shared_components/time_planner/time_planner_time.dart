import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/config/global_config.dart' as config;

/// Show the hour for each row of time planner
class TimePlannerTime extends StatelessWidget {
  /// Text it will be show as hour
  final String? time;

  /// Show the hour for each row of time planner
  const TimePlannerTime({
    Key? key,
    this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.cellHeight!.toDouble() / 2,
      width: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
        // child: Center(child: Text(time!)),
        child: Center(child: AutoSizeText(time!, maxFontSize: 12, minFontSize: 8,)),
      ),
    );
  }
}
