import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:either_dart/either.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/diary/user_steps_data.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/legend_indicator.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DailySummaryCardView extends StatefulWidget {
  final List<StrengthDiaryEntry> strengthDiaryEntries;
  final List<CardioDiaryEntry> cardioDiaryEntries;
  final List<FoodDiaryEntry> foodDiaryEntriesRaw;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> foodDiaryEntries;
  final UserStepsData? userStepsData;

  final FitnessUserProfile fitnessUserProfile;
  final String? gender;
  final int age;

  final DateTime selectedDate;

  const DailySummaryCardView({
    super.key,
    required this.strengthDiaryEntries,
    required this.cardioDiaryEntries,
    required this.foodDiaryEntriesRaw,
    required this.foodDiaryEntries,
    required this.userStepsData,
    required this.selectedDate,
    required this.fitnessUserProfile,
    required this.gender,
    required this.age,
  });


  @override
  State<StatefulWidget> createState() {
    return DailySummaryCardViewState();
  }
}

class DailySummaryCardViewState extends State<DailySummaryCardView> {

  int totalStepsTaken = 0;
  int caloriesBurned = 0;
  int caloriesConsumed = 0;
  int minutesOfActivity = 0;

  double proteinsConsumed = 0;
  double carbsConsumed = 0;
  double fatsConsumed = 0;

  double breakfastCalories = 0;
  double lunchCalories = 0;
  double snacksCalories = 0;
  double dinnerCalories = 0;

  int macrosPieChartTouchedIndex = -1;
  int mealsPieChartTouchedIndex = -1;

  @override
  void initState() {
    super.initState();

    _setupData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1
            )
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: _renderDailySummary(),
          ),
        )
    );
  }

  _renderDailySummary() {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              _dateHeader(),
              WidgetUtils.spacer(5),
              _showCalories(),
              WidgetUtils.spacer(10),
              _showCalorieGoalForDay(),
              WidgetUtils.spacer(5),
              _showMinutesOfActivity(),
              WidgetUtils.spacer(5),
              _showStepsTaken(),
              WidgetUtils.spacer(10),
              _showMacrosBreakDown(),
              WidgetUtils.spacer(10),
              _showMealsBreakdown(),
            ]),
          ),
        ),
      ),
    );
  }

  _showMealsBreakdown() {
    _showMealsPieChartSections() {
      return List.generate(4, (i) { // 3 because breakfast, lunch, dinner, snacks
        final isTouched = i == mealsPieChartTouchedIndex;
        final fontSize = isTouched ? 20.0 : 14.0;
        final radius = isTouched ? 110.0 : 100.0;
        const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

        switch (i) {
          case 0: // Breakfast
            final percentValue = ((breakfastCalories / (breakfastCalories + lunchCalories + dinnerCalories + snacksCalories)) * 100);
            return PieChartSectionData(
              color: Colors.teal,
              value: percentValue,
              title: "${percentValue.toStringAsFixed(1)}%",
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff),
                shadows: shadows,
              ),
            );
          case 1: // Lunch
            final percentValue = ((lunchCalories / (breakfastCalories + lunchCalories + dinnerCalories + snacksCalories)) * 100);
            return PieChartSectionData(
              color: Colors.blueAccent,
              value: percentValue,
              title: "${percentValue.toStringAsFixed(1)}%",
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff),
                shadows: shadows,
              ),
            );
          case 2: // Dinner
            final percentValue = ((dinnerCalories / (breakfastCalories + lunchCalories + dinnerCalories + snacksCalories)) * 100);
            return PieChartSectionData(
              color: Colors.redAccent,
              value: percentValue,
              title: "${percentValue.toStringAsFixed(1)}%",
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff),
                shadows: shadows,
              ),
            );
          case 3: // Snacks
            final percentValue = ((snacksCalories / (breakfastCalories + lunchCalories + dinnerCalories + snacksCalories)) * 100);
            return PieChartSectionData(
              color: Colors.purpleAccent,
              value: percentValue,
              title: "${percentValue.toStringAsFixed(1)}%",
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff),
                shadows: shadows,
              ),
            );
          default:
            throw Exception('Bad state');
        }
      });
    }

    _renderLegend() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          LegendIndicator(
            color: Colors.teal,
            text: 'Breakfast',
            isSquare: true,
          ),
          SizedBox(
            height: 4,
          ),
          LegendIndicator(
            color: Colors.blueAccent,
            text: 'Lunch',
            isSquare: true,
          ),
          SizedBox(
            height: 4,
          ),
          LegendIndicator(
            color: Colors.purpleAccent,
            text: 'Snacks',
            isSquare: true,
          ),
          SizedBox(
            height: 4,
          ),
          LegendIndicator(
            color: Colors.redAccent,
            text: 'Dinner',
            isSquare: true,
          ),
        ],
      );
    }


    if (breakfastCalories + lunchCalories + dinnerCalories + snacksCalories > 0) {
      return Column(
        children: [
          const Text(
            "Meal breakdown",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 16
            ),
          ),
          WidgetUtils.spacer(10),
          SizedBox(
            height: 200,
            width: min(ConstantUtils.WEB_APP_MAX_WIDTH, ScreenUtils.getScreenWidth(context)),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              mealsPieChartTouchedIndex = -1;
                              return;
                            }
                            mealsPieChartTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 0,
                      sections: _showMealsPieChartSections(),
                    ),
                  ),
                ),
                Expanded(
                    flex: 3,
                    child: _renderLegend()
                )
              ],
            ),
          ),
        ],
      );

    }
    else {
      return const Center(
        child: Text(
          "No meal breakdown available",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 14
          ),
        ),
      );
    }
  }


  _showMacrosBreakDown() {
    _showMacrosPieChartSections() {
          return List.generate(3, (i) { // 3 because proteins, carbs and fats
          final isTouched = i == macrosPieChartTouchedIndex;
          final fontSize = isTouched ? 20.0 : 14.0;
          final radius = isTouched ? 110.0 : 100.0;
          const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

          switch (i) {
            case 0: // Proteins
            final percentValue = ((proteinsConsumed / (proteinsConsumed + fatsConsumed + carbsConsumed)) * 100);
              return PieChartSectionData(
                color: Colors.teal,
                value: percentValue,
                title: "${percentValue.toStringAsFixed(1)}%",
                radius: radius,
                titleStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff),
                  shadows: shadows,
                ),
              );
            case 1:
              final percentValue = ((carbsConsumed / (proteinsConsumed + fatsConsumed + carbsConsumed)) * 100);
              return PieChartSectionData(
                color: Colors.blueAccent,
                value: percentValue,
                title: "${percentValue.toStringAsFixed(1)}%",
                radius: radius,
                titleStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff),
                  shadows: shadows,
                ),
              );
            case 2:
              final percentValue = ((fatsConsumed / (proteinsConsumed + fatsConsumed + carbsConsumed)) * 100);
              return PieChartSectionData(
                color: Colors.redAccent,
                value: percentValue,
                title: "${percentValue.toStringAsFixed(1)}%",
                radius: radius,
                titleStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff),
                  shadows: shadows,
                ),
              );
            default:
              throw Exception('Bad state');
          }
        });
      }

    _renderLegend() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          LegendIndicator(
            color: Colors.teal,
            text: 'Proteins',
            isSquare: true,
          ),
          SizedBox(
            height: 4,
          ),
          LegendIndicator(
            color: Colors.blueAccent,
            text: 'Carbohydrates',
            isSquare: true,
          ),
          SizedBox(
            height: 4,
          ),
          LegendIndicator(
            color: Colors.redAccent,
            text: 'Fats',
            isSquare: true,
          ),
        ],
      );
    }


    if (proteinsConsumed + fatsConsumed + carbsConsumed > 0) {
      return Column(
        children: [
          const Text(
            "Macros breakdown",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 16
            ),
          ),
          WidgetUtils.spacer(10),
          SizedBox(
            height: 200,
            width: min(ConstantUtils.WEB_APP_MAX_WIDTH, ScreenUtils.getScreenWidth(context)),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              macrosPieChartTouchedIndex = -1;
                              return;
                            }
                            macrosPieChartTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 0,
                      sections: _showMacrosPieChartSections(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _renderLegend()
                )
              ],
            ),
          ),
        ],
      );

    }
    else {
     return const Center(
       child: Text(
         "No macros data available",
         textAlign: TextAlign.center,
         style: TextStyle(
           color: Colors.teal,
           fontWeight: FontWeight.bold,
           fontSize: 14
         ),
       ),
     );
    }

  }

  _showCalorieGoalForDay() {
    final goalCalories = ExerciseUtils.calculateCalorieGoalPerDayForUserToAttainGoal(widget.fitnessUserProfile, widget.age, widget.gender);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            flex: 2,
            child: CircleAvatar(
              radius: 25,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: AssetImage("assets/icons/goal_icon.png")
                  ),
                ),
              ),
            )
        ),
        Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                "${goalCalories.toStringAsFixed(0)} calories is your daily goal",
                style: const TextStyle(
                  color: Colors.teal,
                ),
              ),
            )
        )
      ],
    );
  }

  _showMinutesOfActivity() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            flex: 2,
            child: CircleAvatar(
              radius: 25,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: AssetImage("assets/icons/activity_icon.png")
                  ),
                ),
              ),
            )
        ),
        Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                "$minutesOfActivity active minutes",
                style: const TextStyle(
                  color: Colors.teal,
                ),
              ),
            )
        )
      ],
    );
  }

  _showStepsTaken() {
    final stepGoalPercentage = ((widget.userStepsData?.steps ?? 0) / (widget.fitnessUserProfile.stepGoalPerDay ?? ExerciseUtils.defaultStepGoal));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            flex: 2,
            child: CircleAvatar(
              radius: 25,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: AssetImage("assets/icons/boot_icon.png")
                  ),
                ),
              ),
            )
        ),
        Expanded(
            flex: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearPercentIndicator(
                  lineHeight: 15.0,
                  barRadius: const Radius.elliptical(5, 10),
                  percent: min(stepGoalPercentage, 1),
                  center: Text(
                    "${(stepGoalPercentage * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12
                    ),
                  ),
                  backgroundColor: Colors.grey.shade400,
                  progressColor: Colors.teal,
                ),
                WidgetUtils.spacer(2.5),
                Text(
                  "${widget.userStepsData?.steps ?? "0"} steps",
                  style: const TextStyle(
                    color: Colors.teal,
                  ),
                )
              ],
            )
        )
      ],
    );
  }

  _showCalories() {
    _showCaloriesConsumed() {
      return Expanded(
          flex: 3,
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red,
                radius: 35,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: AutoSizeText(
                          maxLines: 1,
                          minFontSize: 10,
                          "$caloriesConsumed",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              WidgetUtils.spacer(5),
              const Text(
                "Intake",
                textAlign: TextAlign.center,
              )
            ],
          )
      );
    }
    
    _showCaloriesBurned() {
      return Expanded(
          flex: 3,
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal,
                radius: 35,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: AutoSizeText(
                          maxLines: 1,
                          minFontSize: 10,
                          "$caloriesBurned",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              WidgetUtils.spacer(5),
              const Text(
                "Outake",
                textAlign: TextAlign.center,
              )
            ],
          )
      );
    }

    _showNetCalories() {
      final goalCalories = ExerciseUtils.calculateCalorieGoalPerDayForUserToAttainGoal(widget.fitnessUserProfile, widget.age, widget.gender);
      final netCalories = -goalCalories - caloriesBurned + caloriesConsumed;
      return Expanded(
          flex: 3,
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 35,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: AutoSizeText(
                          maxLines: 1,
                          minFontSize: 10,
                          netCalories.toStringAsFixed(0),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: netCalories > 0 ? Colors.redAccent : (netCalories < 0 ? Colors.teal : Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              WidgetUtils.spacer(5),
              Text(
                netCalories > 0 ? "Net gain" : (netCalories < 0 ? "Net loss" : "Net"),
                textAlign: TextAlign.center,
              )
            ],
          )
      );
    }
    
    return Row(
      children: [
        _showCaloriesConsumed(),
        _showCaloriesBurned(),
        _showNetCalories(),
      ],
    );
  }

  _dateHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
            flex: 6,
            child: Center(
              child: Text(
                DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
            )
        ),
      ],
    );
  }

  _setupData() {
    totalStepsTaken = widget.userStepsData?.steps ?? totalStepsTaken;
    caloriesBurned = _getCaloriesBurned().toInt();
    caloriesConsumed = _getCaloriesConsumed(widget.foodDiaryEntriesRaw, widget.foodDiaryEntries).toInt();
    minutesOfActivity = _getMinutesOfActivity(widget.cardioDiaryEntries);

  }

  _incrementCaloriesForMealEntry(String mealEntry, double calories) {
    switch (mealEntry) {
      case "Breakfast":
        breakfastCalories += calories;
        return;
      case "Lunch":
        lunchCalories += calories;
        return;
      case "Dinner":
        dinnerCalories += calories;
        return;
      case "Snack":
        snacksCalories += calories;
        return;
    }
  }

  num _getCaloriesConsumed(
      List<FoodDiaryEntry> foodDiaryEntriesRaw,
      List<Either<FoodGetResult, FoodGetResultSingleServing>> foodDiaryEntries
  ) {
    final allFoodIds = foodDiaryEntriesRaw.map((e) => e.foodId.toString());
    return foodDiaryEntriesRaw.isEmpty ? 0 : foodDiaryEntriesRaw.map((e) {
      final currentEither = foodDiaryEntries.where((element) {
        if (element.isLeft) {
          return element.left.food.food_id == e.foodId.toString();
        }
        else {
          return element.right.food.food_id == e.foodId.toString();
        }
      }).first;

      if (currentEither.isLeft) {
        if (allFoodIds.contains(currentEither.left.food.food_id)) {
          final rawEntry = foodDiaryEntriesRaw.firstWhere((element) => element.foodId.toString() == currentEither.left.food.food_id);
          final detailedEntryForCurrentServing = currentEither.left.food.servings.serving
              .firstWhere((element) => element.serving_id == rawEntry.servingId.toString());

          final calories = double.parse((detailedEntryForCurrentServing.calories ?? "0")) * rawEntry.numberOfServings;
          final proteins = double.parse((detailedEntryForCurrentServing.protein ?? "0")) * rawEntry.numberOfServings;
          final fats = double.parse((detailedEntryForCurrentServing.fat ?? "0")) * rawEntry.numberOfServings;
          final carbs = double.parse((detailedEntryForCurrentServing.carbohydrate ?? "0")) * rawEntry.numberOfServings;

          proteinsConsumed += proteins;
          fatsConsumed += fats;
          carbsConsumed += carbs;
          _incrementCaloriesForMealEntry(rawEntry.mealEntry, calories);

          return calories;
        }
        else {
          return 0;
        }
      }
      else {
        if (allFoodIds.contains(currentEither.right.food.food_id)) {
          final rawEntry = foodDiaryEntriesRaw.firstWhere((element) => element.foodId.toString() == currentEither.right.food.food_id);

          final calories = double.parse(currentEither.right.food.servings.serving.calories ?? "0") * rawEntry.numberOfServings;
          final proteins = double.parse(currentEither.right.food.servings.serving.protein ?? "0") * rawEntry.numberOfServings;
          final fats = double.parse(currentEither.right.food.servings.serving.fat ?? "0") * rawEntry.numberOfServings;
          final carbs = double.parse(currentEither.right.food.servings.serving.carbohydrate ?? "0") * rawEntry.numberOfServings;

          proteinsConsumed += proteins;
          fatsConsumed += fats;
          carbsConsumed += carbs;
          _incrementCaloriesForMealEntry(rawEntry.mealEntry, calories);

          return calories;
        }
        else {
          return 0;
        }
      }
    }).reduce((value, element) => value + element);
  }

  int _getMinutesOfActivity(List<CardioDiaryEntry> cardioDiaryEntries) {
    if (cardioDiaryEntries.isNotEmpty) {
      return cardioDiaryEntries
          .map((e) => e.durationInMinutes)
          .reduce((value, element) => value + element);
    }
    else {
      return 0;
    }
  }


  double _getCaloriesBurned() {
    return [
      ...widget.strengthDiaryEntries.map((e) => e.caloriesBurned),
      ...widget.cardioDiaryEntries.map((e) => e.caloriesBurned),
      widget.userStepsData?.caloriesBurned ?? 0,
    ].reduce((value, element) => value + element);
  }
}