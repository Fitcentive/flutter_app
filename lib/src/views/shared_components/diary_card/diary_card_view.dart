import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:intl/intl.dart';

class DiaryCardView extends StatefulWidget {

  final VoidCallback onCardTapped;

  final PublicUserProfile currentUserProfile;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> foodDiaryEntries;
  final AllDiaryEntries allDiaryEntries;
  final DateTime? selectedDate;

  const DiaryCardView({
    super.key,
    required this.currentUserProfile,
    required this.foodDiaryEntries,
    required this.allDiaryEntries,
    required this.onCardTapped,
    required this.selectedDate
  });


  @override
  State createState() {
    return DiaryCardViewState();
  }
}

class DiaryCardViewState extends State<DiaryCardView> {

  bool isStrengthPanelExpanded = true;
  bool isCardioPanelExpanded = true;
  bool isFoodPanelExpanded = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onCardTapped();
      },
      child: Card(
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
              child: _renderDiaryEntries(),
            ),
          )
      ),
    );
  }

  _dateHeader() {
    if (widget.selectedDate != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
              flex: 6,
              child: Center(
                child: Text(
                  DateFormat('yyyy-MM-dd').format(widget.selectedDate!),
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
  }

  _renderDiaryEntries() {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetUtils.skipNulls([
              _dateHeader(),
              WidgetUtils.spacer(2.5),
              _renderExerciseDiaryEntries(),
              WidgetUtils.spacer(2.5),
              _renderFoodDiaryEntriesWithContainer(),
            ]),
          ),
        ),
      ),
    );
  }

  _renderExerciseDiaryEntries() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.teal)
        ),
        child: Column(
          children: [
            ExpansionPanelList(
              expansionCallback: (index, isExpanded) {
                setState(() {
                  isCardioPanelExpanded = !isExpanded;
                });
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text(
                        "Cardio",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey
                        ),
                      ),
                    );
                  },
                  body: _renderCardioDiaryEntries(),
                  isExpanded: isCardioPanelExpanded,
                )
              ],
            ),
            WidgetUtils.spacer(5),
            ExpansionPanelList(
              expansionCallback: (index, isExpanded) {
                setState(() {
                  isStrengthPanelExpanded = !isExpanded;
                });
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text(
                          "Strength",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey
                        ),
                      ),
                    );
                  },
                  body: _renderStrengthDiaryEntries(),
                  isExpanded: isStrengthPanelExpanded,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  _renderCardioDiaryEntries() {
      return widget.allDiaryEntries.cardioWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allDiaryEntries.cardioWorkouts.length,
          itemBuilder: (context, index) {
            final currentCardioEntry = widget.allDiaryEntries.cardioWorkouts[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(currentCardioEntry.name)
                        )
                    ),
                    Expanded(
                        flex: 1,
                        child: Text(
                          "${currentCardioEntry.durationInMinutes} minutes",
                        )
                    ),
                    Expanded(
                        flex: 1,
                        child: Text(
                          "${currentCardioEntry.caloriesBurned.toInt()} calories",
                          style: const TextStyle(
                              color: Colors.teal
                          ),
                        )
                    )
                  ],
                ),
              ),
            );
          }
      ) : const Center(
        child: Text("No items here..."),
      );

  }

  _renderStrengthDiaryEntries() {
      return widget.allDiaryEntries.strengthWorkouts.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allDiaryEntries.strengthWorkouts.length,
          itemBuilder: (context, index) {
            final currentStrengthEntry = widget.allDiaryEntries.strengthWorkouts[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Expanded(
                        flex: 6,
                        child: Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(currentStrengthEntry.name)
                        )
                    ),
                    Expanded(
                        flex: 3,
                        child: Text("${currentStrengthEntry.sets} sets")
                    ),
                    Expanded(
                        flex: 3,
                        child: Text("${currentStrengthEntry.reps} reps")
                    ),
                    Expanded(
                        flex: 4,
                        child: Text(
                          "${currentStrengthEntry.caloriesBurned.toInt()} calories",
                          style: const TextStyle(
                              color: Colors.teal
                          ),
                        )
                    )
                  ],
                ),
              ),
            );
          }
      ) : const Center(
        child: Text("No items here..."),
      );
    }

  _renderFoodDiaryEntriesWithContainer() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.teal)
        ),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ExpansionPanelList(
                expansionCallback: (index, isExpanded) {
                  setState(() {
                    isFoodPanelExpanded = !isExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text(
                          "Nutrition",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey
                          ),
                        ),
                      );
                    },
                    body: _renderFoodDiaryEntries(),
                    isExpanded: isFoodPanelExpanded,
                  )
                ],
              ),
            ]
        ),
      ),
    );
  }

  _renderFoodDiaryEntries() {
    if (widget.allDiaryEntries.foodEntries.isNotEmpty) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allDiaryEntries.foodEntries.length,
          itemBuilder: (context, index) {
            final foodEntryForHeadingRaw = widget.allDiaryEntries.foodEntries[index];
            final detailedFoodEntry = widget.foodDiaryEntries.firstWhere((element) {
              if (element.isLeft) {
                return element.left.food.food_id == foodEntryForHeadingRaw.foodId.toString();
              }
              else {
                return element.right.food.food_id == foodEntryForHeadingRaw.foodId.toString();
              }
            });
            final caloriesRaw = detailedFoodEntry.isLeft ?
            detailedFoodEntry.left.food.servings.serving.firstWhere((element) => element.serving_id == foodEntryForHeadingRaw.servingId.toString()).calories :
            detailedFoodEntry.right.food.servings.serving.calories;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Expanded(
                        flex: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                    detailedFoodEntry.isLeft ? detailedFoodEntry.left.food.food_name : detailedFoodEntry.right.food.food_name
                                )
                            ),
                            Container(
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                  "${foodEntryForHeadingRaw.numberOfServings.toStringAsFixed(2)} servings",
                                  style: const TextStyle(
                                      fontSize: 12
                                  ),
                                )
                            ),
                          ],
                        )
                    ),
                    Expanded(
                        flex: 4,
                        child: Text(
                          "${(double.parse(caloriesRaw ?? "0") * foodEntryForHeadingRaw.numberOfServings).toStringAsFixed(0)} calories",
                          style: const TextStyle(
                              color: Colors.teal
                          ),
                        )
                    )
                  ],
                ),
              ),
            );
          }
      );
    }
    else {
      return const Center(
        child: Text("No items here..."),
      );
    }
  }
}