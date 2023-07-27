import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/diary/user_steps_data.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:intl/intl.dart';

class DailySummaryCardView extends StatefulWidget {
  final List<StrengthDiaryEntry> strengthDiaryEntries;
  final List<CardioDiaryEntry> cardioDiaryEntries;
  final List<FoodDiaryEntry> foodDiaryEntriesRaw;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> foodDiaryEntries;
  final UserStepsData? userStepsData;

  final DateTime selectedDate;

  const DailySummaryCardView({
    super.key,
    required this.strengthDiaryEntries,
    required this.cardioDiaryEntries,
    required this.foodDiaryEntriesRaw,
    required this.foodDiaryEntries,
    required this.userStepsData,
    required this.selectedDate,
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
              WidgetUtils.spacer(2.5),
            ]),
          ),
        ),
      ),
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
    caloriesBurned = _getCaloriesBurned(widget.strengthDiaryEntries, widget.cardioDiaryEntries);
    caloriesConsumed = _getCaloriesConsumed(widget.foodDiaryEntriesRaw, widget.foodDiaryEntries);
    minutesOfActivity = _getMinutesOfActivity(widget.strengthDiaryEntries, widget.cardioDiaryEntries);

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
      case "Snacks":
        snacksCalories += calories;
        return;
    }
  }

  _getCaloriesConsumed(
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

  _getMinutesOfActivity(List<StrengthDiaryEntry> strengthDiaryEntries, List<CardioDiaryEntry> cardioDiaryEntries) {
    return cardioDiaryEntries
        .map((e) => e.durationInMinutes)
        .reduce((value, element) => value + element);
  }


  _getCaloriesBurned(List<StrengthDiaryEntry> strengthDiaryEntries, List<CardioDiaryEntry> cardioDiaryEntries) {
    return [...strengthDiaryEntries.map((e) => e.caloriesBurned), ...cardioDiaryEntries.map((e) => e.caloriesBurned)]
        .reduce((value, element) => value + element);
  }
}