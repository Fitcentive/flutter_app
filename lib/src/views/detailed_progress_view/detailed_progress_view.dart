import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/awards_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/award_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_progress_view/bloc/detailed_progress_bloc.dart';
import 'package:flutter_app/src/views/detailed_progress_view/bloc/detailed_progress_event.dart';
import 'package:flutter_app/src/views/detailed_progress_view/bloc/detailed_progress_state.dart';
import 'package:flutter_app/src/views/user_fitness_profile/user_fitness_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';


class DetailedProgressView extends StatefulWidget {
  static const String routeName = "view-progress";

  final PublicUserProfile userProfile;
  final AwardCategory awardCategory;
  final FitnessUserProfile? fitnessUserProfile;

  static Route route(
      PublicUserProfile currentUserProfile,
      AwardCategory awardCategory,
      FitnessUserProfile? fitnessUserProfile,
  ) => MaterialPageRoute<void>(
      settings: const RouteSettings(
          name: routeName
      ),
      builder: (_) =>  DetailedProgressView.withBloc(currentUserProfile, awardCategory, fitnessUserProfile)
  );

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      AwardCategory awardCategory,
      FitnessUserProfile? fitnessUserProfile
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<DetailedProgressBloc>(
          create: (context) => DetailedProgressBloc(
            awardsRepository: RepositoryProvider.of<AwardsRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: DetailedProgressView(
        userProfile: currentUserProfile,
        awardCategory: awardCategory,
        fitnessUserProfile: fitnessUserProfile,
    ),
  );

  @override
  State<StatefulWidget> createState() {
    return DetailedProgressViewState();
  }

  const DetailedProgressView({
    super.key,
    required this.userProfile,
    required this.awardCategory,
    required this.fitnessUserProfile,
  });
}

class DetailedProgressViewState extends State<DetailedProgressView> {
  static const String routeName = "view-achievement";

  static Map<String, String> progressCategoryToDisplayNameMap = {
    StepData().name(): "Steps",
    DiaryEntryData().name(): "Diary",
    ActivityData().name(): "Activity",
    WeightData().name(): "Weight",
  };

  static const String oneWeekDisplayString = "1 week";
  static const String twoWeekDisplayString = "2 weeks";
  static const String oneMonthDisplayString = "1 month";
  static const String twoMonthsDisplayString = "2 months";
  static const String threeMonthsDisplayString = "3 months";
  static const String sixMonthsDisplayString = "6 months";
  static const String oneYearDisplayString = "1 year";

  late DetailedProgressBloc _detailedProgressBloc;

  final now = DateTime.now();
  // final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  late String filterStartDate;
  late String filterEndDate;

  FitnessUserProfile? currentFitnessUserProfile;

  Map<String, double> dateStringToMetricMap = {};

  List<String> relevantDateStringsForChosenFilter = [];
  List<FlSpot> dataPoints = [];

  String selectedFilterDisplayName = oneWeekDisplayString;
  List<String> allFilterDisplayNames = [
    oneWeekDisplayString,
    twoWeekDisplayString,
    oneMonthDisplayString,
    twoMonthsDisplayString,
    threeMonthsDisplayString,
    sixMonthsDisplayString,
    oneYearDisplayString,
  ];

  @override
  void initState() {
    super.initState();

    currentFitnessUserProfile = widget.fitnessUserProfile;
    filterStartDate = DateFormat("yyyy-MM-dd").format(now.subtract(const Duration(days: 6)));
    filterEndDate = DateFormat("yyyy-MM-dd").format(DateTime.now());

    _detailedProgressBloc = BlocProvider.of<DetailedProgressBloc>(context);
    // Fetch this week by default
    _detailedProgressBloc.add(FetchDataForMetricCategory(
        userId: widget.userProfile.userId,
        category: widget.awardCategory,
        from: filterStartDate,
        to: filterEndDate,
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
              color: Colors.teal,
            ),
            onPressed: () {
              _goToUserFitnessProfileView();
            },
          )
        ],
        title: Text(
          "${progressCategoryToDisplayNameMap[widget.awardCategory.name()]!} progress",
          style: const TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      body: BlocListener<DetailedProgressBloc, DetailedProgressState>(
        listener: (context, state) {
          if (state is StepProgressMetricsLoaded) {
            for (var element in state.userStepMetrics) {
              dateStringToMetricMap[element.metricDate] = element.stepsTaken.toDouble();
            }
          }

          else if (state is DiaryEntriesProgressMetricsLoaded) {
            for (var element in state.userDiaryEntryMetrics) {
              dateStringToMetricMap[element.metricDate] = element.entryCount.toDouble();
            }
          }

          else if (state is ActivityProgressMetricsLoaded) {
            for (var element in state.userActivityMetrics) {
              dateStringToMetricMap[element.metricDate] = element.activityMinutes.toDouble();
            }
          }

          else if (state is WeightProgressMetricsLoaded) {
            for (var element in state.userWeightMetrics) {
              dateStringToMetricMap[element.metricDate] = element.weightInLbs;
            }
          }

        },
        child: BlocBuilder<DetailedProgressBloc, DetailedProgressState>(
          builder: (context, state) {
            if (state is StepProgressMetricsLoaded ||
                state is ActivityProgressMetricsLoaded ||
                state is DiaryEntriesProgressMetricsLoaded ||
                state is WeightProgressMetricsLoaded
            ) {
              return _renderBody();
            }
            else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              );
            }
          },
        ),
      )
    );
  }

  _calculateDataPoints() {
    relevantDateStringsForChosenFilter = _getRelevantDateStringsForChosenFilter();
    final userCurrentWeight = currentFitnessUserProfile?.weightInLbs ?? 0;
    if (widget.awardCategory.name() == WeightData().name()) {
      final size = relevantDateStringsForChosenFilter.length;
      List<FlSpot> rawPoints = [];
      dataPoints = relevantDateStringsForChosenFilter
          .toList()
          .asMap()
          .map((index, dateString) {
        final opt = dateStringToMetricMap[dateString];
        if (opt == null) {
          // We want to assume the value of the entry before this, if it exists
          // If this is the first entry, then we want that to assume the next available one, or current
          // DP optimization for better performance needed
          if (index == 0) {
            // We have to look forward if we are at the beginning
            double? nextNonNullUserWeight;
            var i = index + 1;
            while (i < size) {
              if (dateStringToMetricMap[relevantDateStringsForChosenFilter[i]] != null) {
                nextNonNullUserWeight = dateStringToMetricMap[relevantDateStringsForChosenFilter[i]]!;
                break;
              }
              else {
                i += 1;
              }
            }
            if (nextNonNullUserWeight == null) {
              rawPoints.add(FlSpot(index.toDouble(), userCurrentWeight));
              return MapEntry(index, FlSpot(index.toDouble(), userCurrentWeight));
            }
            else {
              rawPoints.add(FlSpot(index.toDouble(), nextNonNullUserWeight));
              return MapEntry(index, FlSpot(index.toDouble(), nextNonNullUserWeight));
            }
          }
          else {
            // We look backward otherwise
            rawPoints.add(FlSpot(index.toDouble(), rawPoints[index - 1].y));
            return MapEntry(index, FlSpot(index.toDouble(), rawPoints[index - 1].y));
          }
        }
        else {
          rawPoints.add(FlSpot(index.toDouble(), opt));
          return MapEntry(index, FlSpot(index.toDouble(), opt));
        }
      })
          .values
          .toList();

    }
    else {
      dataPoints = relevantDateStringsForChosenFilter
          .asMap()
          .map((index, e) {
        if (widget.awardCategory.name() == StepData().name()) {
          return MapEntry(index, FlSpot(index.toDouble(), (dateStringToMetricMap[e] ?? 0) / 100));
        }
        else {
          return MapEntry(index, FlSpot(index.toDouble(), (dateStringToMetricMap[e] ?? 0)));
        }
      })
          .values
          .toList();
    }
  }

  _renderBody() {
    _calculateDataPoints();
    return Center(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _renderHeader(),
              WidgetUtils.spacer(5),
              _renderInteractiveChart(),
              WidgetUtils.spacer(15),
            ],
          ),
        ),
      ),
    );
  }

  _renderInteractiveChart() {

    LineChartBarData lineChartBarData1_1 = LineChartBarData(
      isCurved: true,
      color: Colors.teal,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: Colors.teal.shade50),
      spots: dataPoints,
    );

    // Only used as trendline to benchmark step goals against
    LineChartBarData lineChartBarData1_2 = LineChartBarData(
      isCurved: true,
      color: Colors.redAccent,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        color: Colors.pink.withOpacity(0),
      ),
      spots: dataPoints
          .asMap()
          .map((key, value) => MapEntry(key, FlSpot(key.toDouble(), ((currentFitnessUserProfile?.stepGoalPerDay ?? ExerciseUtils.defaultStepGoal) / 100).toDouble())))
          .values
          .toList(),
    );

    // Only used as trendline to benchmark user weight goal against
    LineChartBarData lineChartBarData1_3 = LineChartBarData(
      isCurved: true,
      color: Colors.redAccent,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        color: Colors.pink.withOpacity(0),
      ),
      spots: dataPoints
          .asMap()
          .map((key, value) => MapEntry(
              key,
              FlSpot(key.toDouble(), currentFitnessUserProfile?.goalWeightInLbs ?? 0)))
          .values
          .toList(),
    );

    // Only used as trendline to benchmark user activity minutes against
    LineChartBarData lineChartBarData1_4 = LineChartBarData(
      isCurved: true,
      color: Colors.orange,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        color: Colors.pink.withOpacity(0),
      ),
      spots: dataPoints
          .asMap()
          .map((key, value) => MapEntry(
          key,
          FlSpot(key.toDouble(), ExerciseUtils.minimumRecommendedMinutesOfActivityPerDay)))
          .values
          .toList(),
    );

    List<LineChartBarData> lineBarsData1 = WidgetUtils.skipNulls([
      lineChartBarData1_1,
      widget.awardCategory.name() == StepData().name() ?  lineChartBarData1_2 : null,
      widget.awardCategory.name() == WeightData().name() ?  lineChartBarData1_3 : null,
      widget.awardCategory.name() == ActivityData().name() ?  lineChartBarData1_4 : null,
    ]);

    return Column(
      children: [
       Row(
         children: [
           Expanded(
             flex: 1,
             child: Center(
               child: Text(
                 "$filterStartDate - $filterEndDate",
                 textAlign: TextAlign.center,
                 style: const TextStyle(
                   color: Colors.teal,
                   fontWeight: FontWeight.bold
                 ),
               ),
             ),
           ),
           Expanded(
             flex: 1,
             child: Center(
               child: DropdownButton<String>(
                   isExpanded: true,
                   value: selectedFilterDisplayName,
                   items: allFilterDisplayNames.map((e) => DropdownMenuItem<String>(
                     value: e,
                     child: Text(e),
                   )).toList(),
                   onChanged: (newValue) {
                     setState(() {
                       selectedFilterDisplayName = newValue ?? selectedFilterDisplayName;
                       _determineNewFilterStartDate();
                     });
                     // Fetch new info from bloc
                     _detailedProgressBloc.add(FetchDataForMetricCategory(
                       userId: widget.userProfile.userId,
                       category: widget.awardCategory,
                       from: filterStartDate,
                       to: filterEndDate,
                     ));
                   }
               ),
             ),
           ),
         ],
       ),
        WidgetUtils.spacer(5),
        ConstrainedBox(
          constraints: const BoxConstraints(
              maxHeight: 400
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 20.0, 0),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: widget.awardCategory.name() != StepData().name(),
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                  ),
                ),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 1,
                      getTitlesWidget: bottomTitleWidgets,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      _getLeftAxisTitle(),
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    sideTitles: SideTitles(
                      getTitlesWidget: leftTitleWidgets,
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom:
                    BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 4),
                    left: const BorderSide(color: Colors.transparent),
                    right: const BorderSide(color: Colors.transparent),
                    top: const BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: lineBarsData1,
                minX: 0,
                maxX: _getXvalueMaxBasedOnSelectedFilter().toDouble(),
                maxY: _getYvalueMaxBasedOnCategory().toDouble(),
                minY: 0,
              ),
              swapAnimationDuration: const Duration(milliseconds: 150), // Optional
              swapAnimationCurve: Curves.linear, // Optional
            ),
          ),
        )
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    Widget text;

    switch (selectedFilterDisplayName) {
      case oneWeekDisplayString: // We display each day individally
        text = Text(
          DateFormat("MM/dd").format(DateTime.parse(filterStartDate).add(Duration(days: value.toInt()))),
          style: style,
        );
        break;

      case twoWeekDisplayString: // We display each day individally
        text = Text(
          DateFormat("MM/dd").format(DateTime.parse(filterStartDate).add(Duration(days: value.toInt()))),
          style: style,
        );
        break;

      case oneMonthDisplayString: // We display start of each week
        final start = DateTime.parse(filterEndDate);
        final monthStart = DateTime(start.year, start.month - 1, start.day);

        if (value % 7 == 0) {
          text = Text(
            DateFormat("MM/dd").format(monthStart.add(Duration(days: value.toInt()))),
            style: style,
          );
        }
        else {
          text = Container();
        }

        break;

      case twoMonthsDisplayString: // We display start of every 2nd week
        final start = DateTime.parse(filterEndDate);
        final monthStart = DateTime(start.year, start.month - 2, start.day);

        if (value % 14 == 0) {
          text = Text(
            DateFormat("MM/dd").format(monthStart.add(Duration(days: value.toInt() ))),
            style: style,
          );
        }
        else {
          text = Container();
        }

        break;

      case threeMonthsDisplayString:
        final start = DateTime.parse(filterEndDate);
        final monthStart = DateTime(start.year, start.month - 3, start.day);
        if (value % 14 == 0) {
          text = Text(
            DateFormat("MM/dd").format(monthStart.add(Duration(days: value.toInt() ))),
            style: style,
          );
        }
        else {
          text = Container();
        }

        break;

      case sixMonthsDisplayString:
        final start = DateTime.parse(filterEndDate);
        final monthStart = DateTime(start.year, start.month - 6, start.day);

        if (value % 30 == 0) {
          text = Text(
            DateFormat("MM/dd").format(monthStart.add(Duration(days: value.toInt() ))),
            style: style,
          );
        }
        else {
          text = Container();
        }

        break;

      case oneYearDisplayString:
        final start = DateTime.parse(filterEndDate);
        final monthStart = DateTime(start.year, start.month - 12, start.day);

        if (value % 30 == 0) {
          text = Text(
            DateFormat("MMM").format(monthStart.add(Duration(days: value.toInt() ))),
            style: style,
          );
        }
        else {
          text = Container();
        }

        break;

      default:
        text = const Text(
          "Bad state",
          style: style,
        );
        break;

    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      angle: radians(-15).toDouble(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
        child: text,
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    String text = 'Bad';

    if (widget.awardCategory.name() == StepData().name()) {
      switch (value.toInt()) {
        case 25:
          text = '2.5K';
          break;
        case 50:
          text = '5K';
          break;
        case 75:
          text = '7.5K';
          break;
        case 100:
          text = '10K';
          break;
        case 125:
          text = '12.5K';
          break;
        case 150:
          text = '15K';
          break;
        case 175:
          text = '17.5K';
          break;
        case 200:
          text = '20K';
          break;
        case 225:
          text = '22.5K';
          break;
        case 250:
          text = '25K';
          break;
        default:
          return Container();
      }
    }

    else if (widget.awardCategory.name() == DiaryEntryData().name()) {
      switch (value.toInt()) {
        case 5:
          text = '5';
          break;
        case 10:
          text = '10';
          break;
        case 15:
          text = '15';
          break;
        case 20:
          text = '20';
          break;
        case 25:
          text = '25';
          break;
        case 30:
          text = '30';
          break;
        case 35:
          text = '35';
          break;
        case 40:
          text = '40';
          break;
        case 45:
          text = '45';
          break;
        case 50:
          text = '50';
          break;
        default:
          return Container();
      }
    }

    else if (widget.awardCategory.name() == ActivityData().name()) {
      switch (value.toInt()) {
        case 20:
          text = '20';
          break;
        case 40:
          text = '40';
          break;
        case 60:
          text = '60';
          break;
        case 80:
          text = '80';
          break;
        case 100:
          text = '100';
          break;
        case 120:
          text = '120';
          break;
        case 140:
          text = '140';
          break;
        case 160:
          text = '160';
          break;
        case 180:
          text = '180';
          break;
        case 200:
          text = '200';
          break;
        default:
          return Container();
      }
    }

    else if (widget.awardCategory.name() == WeightData().name()) {
      switch (value.toInt()) {
        case 25:
          text = '25';
          break;
        case 50:
          text = '50';
          break;
        case 75:
          text = '75';
          break;
        case 100:
          text = '100';
          break;
        case 125:
          text = '125';
          break;
        case 150:
          text = '150';
          break;
        case 175:
          text = '175';
          break;
        case 200:
          text = '200';
          break;
        case 225:
          text = '225';
          break;
        case 250:
          text = '250';
          break;
        case 275:
          text = '275';
          break;
        case 300:
          text = '300';
          break;
        default:
          return Container();
      }
    }



    return Text(text, style: style, textAlign: TextAlign.center);
  }

  _getLeftAxisTitle() {
    switch (widget.awardCategory.name()) {
      case "StepData":
        return "Steps";
      case "DiaryEntryData":
        return "Entries";
      case "ActivityData":
        return "Minutes";
      case "WeightData":
        return "Weight in lbs";
      default:
        return "Steps";
    }
  }

  int _getYvalueMaxBasedOnCategory() {
    switch (widget.awardCategory.name()) {
      case "StepData":
        return 250;
      case "DiaryEntryData":
        return 50;
      case "ActivityData":
        return 200;
      case "WeightData":
        return 300;
      default:
        return 250;
    }
  }

  int _getXvalueMaxBasedOnSelectedFilter() {
    switch (selectedFilterDisplayName) {
      case oneWeekDisplayString:
        return 6;

      case twoWeekDisplayString:
        return 13;

      case oneMonthDisplayString:
        return 29;

      case twoMonthsDisplayString:
        return 59;

      case threeMonthsDisplayString:
        return 89;

      case sixMonthsDisplayString:
        return 179;

      case oneYearDisplayString:
        return 364;

      default:
        return 6;
    }
  }

  _determineNewFilterStartDate() {
    switch (selectedFilterDisplayName) {
      case oneWeekDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(now.subtract(const Duration(days: 6)));
        break;

      case twoWeekDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(now.subtract(const Duration(days: 13)));
        break;

      case oneMonthDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month - 1, now.day));
        break;

      case twoMonthsDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month - 2, now.day));
        break;

      case threeMonthsDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month - 3, now.day));
        break;

      case sixMonthsDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month - 6, now.day));
        break;

      case oneYearDisplayString:
        filterStartDate = DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month - 12, now.day));
        break;

      default:
        filterStartDate = DateFormat("yyyy-MM-dd").format(now.subtract(const Duration(days: 6)));
        break;
    }
  }


  /// Gets the relevant date strings pertaining to fetched progress data for selected filter
  /// Returns in ascending order
  List<String> _getRelevantDateStringsForChosenFilter() {
    final int maxDays;
    switch (selectedFilterDisplayName) {
      case oneWeekDisplayString:
        maxDays = 7;
        break;

      case twoWeekDisplayString:
        maxDays = 14;
        break;

      case oneMonthDisplayString:
        maxDays = 30;
        break;

      case twoMonthsDisplayString:
        maxDays = 60;
        break;

      case threeMonthsDisplayString:
        maxDays = 90;
        break;

      case sixMonthsDisplayString:
        maxDays = 180;
        break;

      case oneYearDisplayString:
        maxDays = 365;
        break;

      default:
        maxDays = 7;
        break;
    }

    return List.generate(maxDays, (index) {
      final daysToGoBack = maxDays - index - 1;
      return DateFormat("yyyy-MM-dd").format(DateTime.parse(filterEndDate).subtract(Duration(days: daysToGoBack)));
    });
  }

  _renderHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 62.5,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                  image: AssetImage(AwardUtils.awardCategoryToIconAssetPathMap[widget.awardCategory.name()]!)
              ),
            ),
          ),
        ),
        WidgetUtils.spacer(10),
        _renderBestStats(),
      ],
    );
  }

  _renderBestStats() {
    if (widget.awardCategory.name() == WeightData().name()) {
      final entriesForCurrentPeriod = dateStringToMetricMap
          .entries
          .where((element) => relevantDateStringsForChosenFilter.contains(element.key));


      MapEntry<String, double>? maxDay;
      if (entriesForCurrentPeriod.isNotEmpty) {
        maxDay = entriesForCurrentPeriod.reduce((value, element) => value.value > element.value ? value : element);
      }
      else {
        if (dateStringToMetricMap.entries.isNotEmpty) {
          maxDay = dateStringToMetricMap.entries.first;
        }
      }

      final total   = dateStringToMetricMap.entries.isEmpty ? 0 : dateStringToMetricMap.entries.map((e) => e.value).reduce((a, b) => a + b);
      final average = total / dataPoints.length;

      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  maxDay != null ? "Max (${DateFormat("MMM dd").format(DateTime.parse(maxDay.key))})"
                    : "Max (${DateFormat("MMM dd").format(DateTime.now())})",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  maxDay?.value.toStringAsFixed(0) ?? "0",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Current",
                  style: TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  currentFitnessUserProfile?.weightInLbs.toStringAsFixed(1) ?? "0",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Goal",
                  style: TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  currentFitnessUserProfile?.goalWeightInLbs?.toStringAsFixed(1) ?? "0",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    else {
      final entriesForCurrentPeriod = dateStringToMetricMap
          .entries
          .where((element) => relevantDateStringsForChosenFilter.contains(element.key));


      MapEntry<String, double>? bestDay;
      if (entriesForCurrentPeriod.isNotEmpty) {
        bestDay = entriesForCurrentPeriod.reduce((value, element) => value.value > element.value ? value : element);
      }
      else {
        if (dateStringToMetricMap.entries.isNotEmpty) {
          bestDay = dateStringToMetricMap.entries.first;
        }
      }

      final total   = dateStringToMetricMap.entries.isEmpty ? 0 : dateStringToMetricMap.entries.map((e) => e.value).reduce((a, b) => a + b);
      final average = total / dataPoints.length;

      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                    bestDay != null ? "Best (${DateFormat("MMM dd").format(DateTime.parse(bestDay!.key))})"
                        : "Best (${DateFormat("MMM dd").format(DateTime.now())})",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  bestDay?.value.toStringAsFixed(0) ?? "0",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Average",
                  style: TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  average.toStringAsFixed(0),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  total.toStringAsFixed(0),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  _goToUserFitnessProfileView() {
    Navigator.push<FitnessUserProfile>(
        context,
        UserFitnessProfileView.route(widget.userProfile, currentFitnessUserProfile)
    ).then((value) {
      if (value != null) {
        setState(() {
          currentFitnessUserProfile = value;
        });
      }
    });
  }

}