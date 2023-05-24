import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/utils/datetime_utils.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_task.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_time.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/config/global_config.dart' as config;

typedef TimePlannerSelectedTileCallback = void Function(List<List<bool>> selectedTimeblocks);

/// Inspired by https://pub.dev/packages/time_planner
///
/// Time planner widget
class DiscreteAvailabilitiesView extends StatefulWidget {
  /// Time start from this, it will start from 0
  final int startHour;

  /// Time end at this hour, max value is 23
  final int endHour;

  /// Create days from here, each day is a TimePlannerTitle.
  ///
  /// you should create at least one day
  final List<TimePlannerTitle> headers;

  /// List of widgets on time planner
  final List<TimePlannerTask>? tasks;

  /// Style of time planner
  final TimePlannerStyle? style;

  /// When widget loaded scroll to current time with an animation. Default is true
  final bool? currentTimeAnimation;

  final String? currentUserAcceptingAvailabilityFor;

  final Map<String, List<MeetupAvailabilityUpsert>> meetupAvailabilities;
  final DateTime availabilityInitialDay;

  final TimePlannerSelectedTileCallback availabilityChangedCallback;

  /// Time planner widget
  const DiscreteAvailabilitiesView({
    Key? key,
    required this.startHour,
    required this.endHour,
    required this.headers,
    required this.availabilityChangedCallback,
    required this.availabilityInitialDay,
    required this.meetupAvailabilities,
    this.currentUserAcceptingAvailabilityFor,
    this.tasks,
    this.style,
    this.currentTimeAnimation,
  }) : super(key: key);

  static List<List<int>> defaultAvailabilityMatrix(int totalDays, int totalHours) =>
    List.generate(totalDays, (_) => List.filled(totalHours * 2, 0));

  @override
  DiscreteAvailabilitiesViewState createState() => DiscreteAvailabilitiesViewState();
}

class DiscreteAvailabilitiesViewState extends State<DiscreteAvailabilitiesView> {
  ScrollController mainHorizontalController = ScrollController();
  ScrollController mainVerticalController = ScrollController();
  ScrollController dayHorizontalController = ScrollController();
  ScrollController timeVerticalController = ScrollController();
  TimePlannerStyle style = TimePlannerStyle();
  List<TimePlannerTask> tasks = [];
  bool? isAnimated = true;

  List<List<int>> cellStateMatrix = [[]];

  bool hasInitialCellMatrixBeenSetUpToAcceptAvailabilities = false;

  /// check input value rules
  void _checkInputValue() {
    if (widget.startHour > widget.endHour) {
      throw FlutterError("Start hour should be lower than end hour");
    } else if (widget.startHour < 0) {
      throw FlutterError("Start hour should be larger than 0");
    } else if (widget.endHour > 23) {
      throw FlutterError("Start hour should be lower than 23");
    } else if (widget.headers.isEmpty) {
      throw FlutterError("header can't be empty");
    }
  }

  /// create local style
  void _convertToLocalStyle() {
    style.backgroundColor = widget.style?.backgroundColor;
    style.cellHeight = widget.style?.cellHeight ?? 80;
    style.cellWidth = widget.style?.cellWidth ?? 90;
    style.horizontalTaskPadding = widget.style?.horizontalTaskPadding ?? 0;
    style.borderRadius = widget.style?.borderRadius ??
        const BorderRadius.all(Radius.circular(8.0));
    style.dividerColor = widget.style?.dividerColor;
    style.showScrollBar = widget.style?.showScrollBar ?? false;
  }

  /// store input data to static values
  void _initData() {
    _checkInputValue();
    _convertToLocalStyle();
    config.horizontalTaskPadding = style.horizontalTaskPadding;
    config.cellHeight = style.cellHeight;
    config.cellWidth = style.cellWidth;
    config.totalHours = (widget.endHour - widget.startHour + 1).toDouble();
    config.totalDays = widget.headers.length;
    config.startHour = widget.startHour;
    config.borderRadius = style.borderRadius;
    isAnimated = widget.currentTimeAnimation;
    tasks = widget.tasks ?? [];
  }

  void _convertAvailabilitiesToCellStateMatrix(
      DateTime availabilityInitialDay,
      Map<String, List<MeetupAvailabilityUpsert>> availabilities
  ) {
    cellStateMatrix = DiscreteAvailabilitiesView.defaultAvailabilityMatrix(config.totalDays, config.totalHours.toInt());

    final all = availabilities
        .entries
        .map((e) => e.value)
        .toList()
        .expand((i) => i)
        .toList();

    var currentDayIndex = 0;
    while(currentDayIndex < config.totalDays) {
      final availabilitiesForCurrentDay = all
          .where((element) =>
              element.availabilityStart.toLocal().isSameDate(availabilityInitialDay.add(Duration(days: currentDayIndex)))
          )
          .toList();

      final currentDayBase = availabilityInitialDay.add(Duration(days: currentDayIndex));

      // Construct map
      Map<int, DateTime> timeSegmentToDateTimeMap = {};
      final numberOfIntervals = config.totalHours.toInt() * 2;
      final intervalsList = List.generate(numberOfIntervals, (i) => i);
      var i = 0;
      var k = 0;
      while (i < intervalsList.length) {
        timeSegmentToDateTimeMap[i] =
            DateTime(currentDayBase.year, currentDayBase.month, currentDayBase.day, k + config.startHour, 0, 0);
        timeSegmentToDateTimeMap[i+1] =
            DateTime(currentDayBase.year, currentDayBase.month, currentDayBase.day, k + config.startHour, 30, 0);

        i += 2;
        k += 1;
      }

      var currentDiscreteTimeIntervalIndex = 0;
      while (currentDiscreteTimeIntervalIndex < config.totalHours.toInt() * 2) {

        // if availability overlaps current cell, increase count of it by 1
        final dateTimePertainingToCurrentTimeInterval =
          timeSegmentToDateTimeMap[currentDiscreteTimeIntervalIndex]!.add(const Duration(minutes: 5));
        var count = 0;

        availabilitiesForCurrentDay.forEach((a) {
          final aStart  = a.availabilityStart.toLocal();
          final aEnd  = a.availabilityEnd.toLocal();
          if (aStart.compareTo(dateTimePertainingToCurrentTimeInterval) < 0 && aEnd.compareTo(dateTimePertainingToCurrentTimeInterval) > 0) {
            count += 1;
          }

        });

        cellStateMatrix[currentDayIndex][currentDiscreteTimeIntervalIndex] = count;

        currentDiscreteTimeIntervalIndex++;
      }

      currentDayIndex++;
    }
  }

  @override
  void initState() {
    _initData();
    super.initState();

    Future.delayed(Duration.zero).then((_) {
      int hour = DateTime.now().hour;
      if (hour > widget.startHour) {
        double scrollOffset =
            (hour - widget.startHour) * config.cellHeight!.toDouble();

        // if (mainVerticalController.hasClients) {
        //   mainVerticalController.animateTo(
        //     scrollOffset,
        //     duration: const Duration(milliseconds: 800),
        //     curve: Curves.easeOutCirc,
        //   );
        // }

        // if (timeVerticalController.hasClients) {
        //   timeVerticalController.animateTo(
        //     scrollOffset,
        //     duration: const Duration(milliseconds: 800),
        //     curve: Curves.easeOutCirc,
        //   );
        // }
      }
    });
  }


  @override
  void dispose() {
    mainHorizontalController.dispose();
    mainVerticalController.dispose();
    dayHorizontalController.dispose();
    timeVerticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUserAcceptingAvailabilityFor == null) {
      // Just show all availabilities as expected
      _convertAvailabilitiesToCellStateMatrix(widget.availabilityInitialDay, widget.meetupAvailabilities);
      hasInitialCellMatrixBeenSetUpToAcceptAvailabilities = false;
    }
    else {
      // Just populate entries for current user accepting availabilities for
      if (!hasInitialCellMatrixBeenSetUpToAcceptAvailabilities) {
        _convertAvailabilitiesToCellStateMatrix(
            widget.availabilityInitialDay,
            Map.fromEntries(widget.meetupAvailabilities.entries.where((element) => element.key == widget.currentUserAcceptingAvailabilityFor!))
        );
        hasInitialCellMatrixBeenSetUpToAcceptAvailabilities = true;
      }

    }

    mainHorizontalController.addListener(() {
      dayHorizontalController.jumpTo(mainHorizontalController.offset);
    });
    mainVerticalController.addListener(() {
      timeVerticalController.jumpTo(mainVerticalController.offset);
    });
    return GestureDetector(
      child: Container(
        color: style.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SingleChildScrollView(
              controller: dayHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 60,
                  ),
                  ...widget.headers,
                ],
              ),
            ),
            Container(
              height: 5,
              color: Colors.teal,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: timeVerticalController,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: _getSideTimes(),
                        ),
                        Container(
                          height: (config.totalHours * config.cellHeight!) + (config.cellHeight! / 2),
                          width: 5,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: buildMainBody(),
                  ),
                ],
              ),
            ),
            Container(
              height: 5,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getSideTimes() {
    List<Widget> r = [];
    for (int i = widget.startHour; i <= widget.endHour; i++) {
      if (i <= 11) {
        r.add(Center(child: TimePlannerTime(time: '$i:00 AM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
        r.add(Center(child: TimePlannerTime(time: '$i:30 AM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
      }
      else if (i == 12) {
        r.add(Center(child: TimePlannerTime(time: '$i:00 PM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
        r.add(Center(child: TimePlannerTime(time: '$i:30 PM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
      }
      else {
        r.add(Center(child: TimePlannerTime(time: '${i % 12}:00 PM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
        r.add(Center(child: TimePlannerTime(time: '${i % 12}:30 PM')));
        r.add(const Divider(height: 1, color: Colors.teal,));
      }

    }
    return r;
  }

  _generateLengthWise(int colIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: (config.totalHours * config.cellHeight!) + (config.cellHeight! / 2),
              width: (config.cellWidth!).toDouble(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _getLengthWiseChildren(colIndex),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 1,
                  height: (config.totalHours * config.cellHeight!) + (config.cellHeight! / 2),
                  color: Colors.teal,
                )
              ],
            )
          ],
        )
      ],
    );
  }

  _getLengthWiseChildren(int colIndex) {
    List<Widget> children = [];
    for (var i = 0; i < config.totalHours * 2; i++) {
      children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Individual per square block,
              // maybe do it ALL together instead to enable select and drag
              GestureDetector(
                onTap: () {
                  if (widget.currentUserAcceptingAvailabilityFor != null) {
                    setState(() {
                      if (cellStateMatrix[colIndex][i] == 1) {
                        cellStateMatrix[colIndex][i] = 0;
                      }
                      else {
                        cellStateMatrix[colIndex][i] = 1;
                      }
                    });

                    widget.availabilityChangedCallback(
                        cellStateMatrix
                            .map((e) => e.map((e) => e == 0 ? false : true).toList())
                            .toList()
                    );
                  }
                },
                // Block of time
                child: SizedBox(
                  height: (config.cellHeight!).toDouble() / 2,
                  child: _renderTimeUnitCell(colIndex, i),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.teal,
              ),
            ],
          )
      );
    }
    return children;
  }

  _renderTimeUnitCell(int colIndex, int i) {
    final calculatedOpacity = (cellStateMatrix[colIndex][i] / widget.meetupAvailabilities.entries.length);
    return Container(
      color: cellStateMatrix[colIndex][i] == 0 ? Colors.white : (
          widget.currentUserAcceptingAvailabilityFor != null ?
          Colors.tealAccent.shade700 :
          Colors.tealAccent.shade700.withOpacity(calculatedOpacity)
      ),
    );
  }

  Widget buildMainBody() {
    if (style.showScrollBar!) {
      return Scrollbar(
        controller: mainVerticalController,
        child: SingleChildScrollView(
          controller: mainVerticalController,
          child: Scrollbar(
            controller: mainHorizontalController,
            child: SingleChildScrollView(
              controller: mainHorizontalController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(config.totalDays, (index) => _generateLengthWise(index))
              ),
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      controller: mainVerticalController,
      child: SingleChildScrollView(
        controller: mainHorizontalController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: (config.totalHours * config.cellHeight!) + 80,
                  width: (config.totalDays * config.cellWidth!).toDouble(),
                  child: Stack(
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (var i = 0; i < config.totalHours; i++)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  height: (config.cellHeight! - 1).toDouble(),
                                ),
                                const Divider(
                                  height: 1,
                                ),
                              ],
                            )
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (var i = 0; i < config.totalDays; i++)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  width: (config.cellWidth! - 1).toDouble(),
                                ),
                                Container(
                                  width: 1,
                                  height:
                                      (config.totalHours * config.cellHeight!) +
                                          config.cellHeight!,
                                  color: Colors.teal,
                                )
                              ],
                            )
                        ],
                      ),
                      for (int i = 0; i < tasks.length; i++) tasks[i],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
