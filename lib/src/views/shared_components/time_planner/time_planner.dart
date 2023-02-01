import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_style.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_task.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_time.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/time_planner_title.dart';
import 'package:flutter_app/src/views/shared_components/time_planner/config/global_config.dart' as config;

typedef TimePlannerSelectedTileCallback = void Function(List<List<bool>> selectedTimeblocks);

/// Inspired by https://pub.dev/packages/time_planner
///
/// Time planner widget
class TimePlanner extends StatefulWidget {
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

  final TimePlannerSelectedTileCallback availabilityChangedCallback;

  /// Time planner widget
  const TimePlanner({
    Key? key,
    required this.startHour,
    required this.endHour,
    required this.headers,
    required this.availabilityChangedCallback,
    this.tasks,
    this.style,
    this.currentTimeAnimation,
  }) : super(key: key);

  @override
  TimePlannerState createState() => TimePlannerState();
}

class TimePlannerState extends State<TimePlanner> {
  ScrollController mainHorizontalController = ScrollController();
  ScrollController mainVerticalController = ScrollController();
  ScrollController dayHorizontalController = ScrollController();
  ScrollController timeVerticalController = ScrollController();
  TimePlannerStyle style = TimePlannerStyle();
  List<TimePlannerTask> tasks = [];
  bool? isAnimated = true;

  List<List<Color>> cellStateColors = [[]];

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
    config.totalHours = (widget.endHour - widget.startHour).toDouble();
    config.totalDays = widget.headers.length;
    config.startHour = widget.startHour;
    config.borderRadius = style.borderRadius;
    isAnimated = widget.currentTimeAnimation;
    tasks = widget.tasks ?? [];
    cellStateColors = List.generate(config.totalDays, (_) => List.filled(config.totalHours.toInt() * 2, Colors.white));
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

        if (mainVerticalController.hasClients) {
          mainVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
        }

        if (timeVerticalController.hasClients) {
          timeVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
        }
      }
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              height: 1,
              color: style.dividerColor ?? Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
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
                            height: (config.totalHours * config.cellHeight! / 2) + 50,
                            width: 1,
                            color: style.dividerColor ??
                                Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: buildMainBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getSideTimes() {
    List<Widget> r = [];
    for (int i = widget.startHour; i <= widget.endHour; i++) {
      r.add(Center(child: TimePlannerTime(time: '$i:00')));
      r.add(Center(child: TimePlannerTime(time: '$i:30')));
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
              height: (config.totalHours * config.cellHeight!) + 80,
              width: (config.cellWidth!).toDouble(),
              // todo - set up an overall drag listener here?
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < config.totalHours * 2; i++)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Individual per square block,
                        // maybe do it ALL together instead to enable select and drag
                        GestureDetector(
                          onTap: () {
                            // todo - need to update parent bloc, but how?
                            // maybe just
                            setState(() {
                              if (cellStateColors[colIndex][i] == Colors.green) {
                                cellStateColors[colIndex][i] = Colors.white;
                              }
                              else {
                                cellStateColors[colIndex][i] = Colors.green;
                              }
                            });

                            widget.availabilityChangedCallback(
                                cellStateColors
                                    .map((e) => e.map((e) => e == Colors.white ? false : true).toList())
                                    .toList()
                            );
                          },
                          // Block of time
                          child: SizedBox(
                            height: (config.cellHeight! + 1).toDouble() / 2,
                            child: Container(
                              color: cellStateColors[colIndex][i],
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                        ),
                      ],
                    )
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 1,
                  height: (config.totalHours * config.cellHeight!) + config.cellHeight!,
                  color: Colors.black12,
                )
              ],
            )
          ],
        )
      ],
    );
  }

  Widget buildMainBody() {
    if (style.showScrollBar!) {
      return Scrollbar(
        controller: mainVerticalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: mainVerticalController,
          child: Scrollbar(
            controller: mainHorizontalController,
            isAlwaysShown: true,
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
                                  color: Colors.black12,
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
