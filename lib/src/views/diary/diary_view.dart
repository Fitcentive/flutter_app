import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_bloc.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_app/src/views/exercise_search/exercise_search_view.dart';
import 'package:flutter_app/src/views/food_search/food_search_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DiaryView extends StatefulWidget {
  static const String routeName = "exercise/search";

  final PublicUserProfile currentUserProfile;

  const DiaryView({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<DiaryBloc>(
          create: (context) => DiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: DiaryView(currentUserProfile: currentUserProfile),
  );


  @override
  State createState() {
    return DiaryViewState();
  }
}

class DiaryViewState extends State<DiaryView> {
  static const int MAX_PAGES = 500;
  static const int INITIAL_PAGE = MAX_PAGES ~/ 2;

  static const int defaultCaloriesTargetPerDay = 2240;

  static const listItemIndexToTitleMap = {
    0: "Breakfast",
    1: "Lunch",
    2: "Dinner",
    3: "Snacks",
    4: "Exercise",
  };

  late DiaryBloc _diaryBloc;

  bool _isFloatingButtonVisible = true;

  DateTime initialSelectedDate = DateTime.now();
  DateTime currentSelectedDate = DateTime.now();

  int currentSelectedPage = MAX_PAGES ~/ 2;
  final PageController _pageController = PageController(initialPage: MAX_PAGES ~/ 2);
  final _scrollController = ScrollController();

  List<Either<FoodGetResult, FoodGetResultSingleServing>> allDetailedFoodEntries = [];
  List<FoodDiaryEntry> allFoodEntriesRaw = [];

  List<FoodDiaryEntry> breakfastEntries = [];
  List<FoodDiaryEntry> lunchEntries = [];
  List<FoodDiaryEntry> dinnerEntries = [];
  List<FoodDiaryEntry> snackEntries = [];

  List<CardioDiaryEntry> cardioEntries = [];
  List<StrengthDiaryEntry> strengthEntries = [];

  @override
  void initState() {
    super.initState();

    _diaryBloc = BlocProvider.of<DiaryBloc>(context);
    _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _animatedButton(),
      body: BlocListener<DiaryBloc, DiaryState>(
        listener: (context, state) {
          if (state is DiaryDataFetched) {
            setState(() {
              // set state here
              allDetailedFoodEntries = state.foodDiaryEntries;
              allFoodEntriesRaw = state.foodDiaryEntriesRaw;

              breakfastEntries = state.foodDiaryEntriesRaw.where((element) => element.mealEntry == "Breakfast").toList();
              lunchEntries = state.foodDiaryEntriesRaw.where((element) => element.mealEntry == "Lunch").toList();
              dinnerEntries = state.foodDiaryEntriesRaw.where((element) => element.mealEntry == "Dinner").toList();
              snackEntries = state.foodDiaryEntriesRaw.where((element) => element.mealEntry == "Snack").toList();

              strengthEntries = state.strengthDiaryEntries;
              cardioEntries = state.cardioDiaryEntries;
            });
          }
        },
        child: BlocBuilder<DiaryBloc, DiaryState>(
          builder: (context, state) {
            if (state is DiaryDataFetched) {
              return _mainBody(state);
            }
            else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  void _onScroll() {
    if(_scrollController.hasClients) {
      // Handle floating action button visibility
      if(_scrollController.position.userScrollDirection == ScrollDirection.reverse){
        if(_isFloatingButtonVisible == true) {
          setState((){
            _isFloatingButtonVisible = false;
          });
        }
      } else {
        if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
          if (_isFloatingButtonVisible == false) {
            setState(() {
              _isFloatingButtonVisible = true;
            });
          }
        }
      }

    }
  }

  _animatedButton() {
    return AnimatedOpacity(
      opacity: _isFloatingButtonVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _isFloatingButtonVisible,
        child: ExpandableFab(
          distance: 120,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          child: const Icon(
              Icons.add,
            color: Colors.white,
          ),
          closeButtonStyle: const ExpandableFabCloseButtonStyle(
            child: Icon(Icons.close, color: Colors.white,),
            backgroundColor: Colors.teal
          ),
          children: [
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToExerciseDiaryButton",
              tooltip: 'Add to exercise diary!',
              backgroundColor: Colors.teal,
              child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white
                ),
              onPressed: () {
                _goToExerciseSearchView();
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToBreakfastDiaryButton",
              tooltip: 'Add breakfast foods!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.breakfast_dining,
                  color: Colors.white
              ),
              onPressed: () {
                _goToFoodSearchView("Breakfast");
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToLunchDiaryButton",
              tooltip: 'Add lunch foods!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.set_meal_outlined,
                  color: Colors.white
              ),
              onPressed: () {
                _goToFoodSearchView("Lunch");
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToDinnerDiaryButton",
              tooltip: 'Add dinner foods!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.dinner_dining,
                  color: Colors.white
              ),
              onPressed: () {
                _goToFoodSearchView("Dinner");
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToSnackDiaryButton",
              tooltip: 'Add snacks!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.emoji_food_beverage,
                  color: Colors.white
              ),
              onPressed: () {
                _goToFoodSearchView("Snacks");
              },
            )
          ],
        )
      ),
    );
  }

  _goToExerciseSearchView() {
    Navigator
        .push(context, ExerciseSearchView.route(widget.currentUserProfile, currentSelectedDate))
        .then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
  }

  _goToFoodSearchView(String mealOfDay) {
    Navigator
        .push(context, FoodSearchView.route(widget.currentUserProfile, mealOfDay, currentSelectedDate))
        .then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
  }

  _caloriesHeader(DiaryDataFetched state) {
    final foodCalories = allDetailedFoodEntries.isEmpty ? 0 : allDetailedFoodEntries.map((e) {
      if (e.isLeft) {
        final rawEntry = allFoodEntriesRaw.firstWhere((element) => element.foodId.toString() == e.left.food.food_id);
        return double.parse((e.left.food.servings.serving.firstWhere((element) => element.serving_id == rawEntry.servingId.toString()).calories ?? "0")) * rawEntry.numberOfServings;
      }
      else {
        final rawEntry = allFoodEntriesRaw.firstWhere((element) => element.foodId.toString() == e.right.food.food_id);
        return double.parse(e.right.food.servings.serving.calories ?? "0") * rawEntry.numberOfServings;
      }
    }).reduce((value, element) => value + element);
    final cardioCalories = cardioEntries.isEmpty ? 0 : cardioEntries.map((e) => e.caloriesBurned).reduce((value, element) => value + element);
    final strengthCalories = strengthEntries.isEmpty ? 0 : strengthEntries.map((e) => e.caloriesBurned).reduce((value, element) => value + element);
    final remainingCalories = defaultCaloriesTargetPerDay - foodCalories + cardioCalories + strengthCalories;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$defaultCaloriesTargetPerDay",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color
                ),
              ),
              WidgetUtils.spacer(2),
              const Text("Goal", style: TextStyle(fontSize: 12),)
            ],
          )
        ),
        const Expanded(
            flex: 1,
            child: Text("-")
        ),
        Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$foodCalories",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                  ),
                ),
                WidgetUtils.spacer(2),
                const Text("Food", style: TextStyle(fontSize: 12),)
              ],
            )
        ),
        const Expanded(
            flex: 1,
            child: Text("+")
        ),
        Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${cardioCalories + strengthCalories}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal
                  ),
                ),
                WidgetUtils.spacer(2),
                const Text("Exercise", style: TextStyle(fontSize: 12),)
              ],
            )
        ),
        const Expanded(
            flex: 1,
            child: Text("=")
        ),
        Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$remainingCalories",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: remainingCalories == 0 ? Theme.of(context).textTheme.headlineMedium?.color : (remainingCalories > 0 ? Colors.teal : Colors.red)
                  ),
                ),
                WidgetUtils.spacer(2),
                const Text("Remaining", style: TextStyle(fontSize: 12),)
              ],
            )
        ),
      ],
    );
  }

  _dateHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 2,
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.teal,
            ),
            onPressed: () {
              _pageController.animateToPage(currentSelectedPage - 1, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
            },
          ),
        ),
        Expanded(
            flex: 6,
            child: Center(
              child: Text(
                DateFormat('yyyy-MM-dd').format(currentSelectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
            )
        ),
        Expanded(
          flex: 2,
          child: IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.teal,
            ),
            onPressed: () {
              _pageController.animateToPage(currentSelectedPage + 1, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
            },
          ),
        ),
      ],
    );
  }

  Widget _mainBody(DiaryDataFetched state) {
    return Scrollbar(
      controller: _scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dateHeader(),
          WidgetUtils.spacer(2.5),
          _caloriesHeader(state),
          WidgetUtils.spacer(5),
          Expanded(
            child: _diaryPageViews(state),
          ),
        ],
      ),
    );
  }

  _diaryPageViews(DiaryDataFetched state) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (pageNumber) {
        currentSelectedPage = pageNumber;
        final daysToAdd = pageNumber - INITIAL_PAGE;
        setState(() {
          if (daysToAdd < 0) {
            currentSelectedDate = initialSelectedDate.subtract(Duration(days: daysToAdd.abs()));
          }
          else {
            currentSelectedDate = initialSelectedDate.add(Duration(days: daysToAdd));

          }
        });
        _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
      },
      itemBuilder: (BuildContext context, int index) {
        return RefreshIndicator(
          onRefresh: () async {
            _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
          },
          child: ListView.builder(
            shrinkWrap: true,
            controller: _scrollController,
            itemCount: listItemIndexToTitleMap.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2.5),
                padding: const EdgeInsets.all(2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 125,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Heading
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(5),
                          child: Text(
                              listItemIndexToTitleMap[index]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                            ),
                          ),
                        ),
                        WidgetUtils.spacer(1.5),
                        _renderDiaryEntries(listItemIndexToTitleMap[index]!, state),
                        WidgetUtils.spacer(5),
                        // Add food/Add exercise button
                        InkWell(
                          onTap: () {
                            if (index == 4) {
                              _goToExerciseSearchView();
                            }
                            else {
                              _goToFoodSearchView(listItemIndexToTitleMap[index]!);
                            }
                          },
                          child: Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(1.0),
                            child: Text(
                              index != 4 ? "ADD FOOD" : "ADD EXERCISE",
                              style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 15
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  _renderDiaryEntries(String heading, DiaryDataFetched state) {
    if (heading == listItemIndexToTitleMap[4]!) {
      return _renderExerciseDiaryEntries(cardioEntries, strengthEntries);
    }
    else {
      if (heading == listItemIndexToTitleMap[0]!) {
        return _renderFoodDiaryEntries(listItemIndexToTitleMap[0]!, breakfastEntries, state);
      }
      else if (heading == listItemIndexToTitleMap[1]!) {
        return _renderFoodDiaryEntries(listItemIndexToTitleMap[1]!, lunchEntries, state);
      }
      else if (heading == listItemIndexToTitleMap[2]!) {
        return _renderFoodDiaryEntries(listItemIndexToTitleMap[2]!, dinnerEntries, state);
      }
      else {
        return _renderFoodDiaryEntries(listItemIndexToTitleMap[3]!, snackEntries, state);
      }
    }
  }

  _renderFoodDiaryEntries(String heading, List<FoodDiaryEntry> foodEntriesForHeadingRaw, DiaryDataFetched state) {
    if (foodEntriesForHeadingRaw.isNotEmpty) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: foodEntriesForHeadingRaw.length,
          itemBuilder: (context, index) {
            final foodEntryForHeadingRaw = foodEntriesForHeadingRaw[index];
            final detailedFoodEntry = state.foodDiaryEntries.firstWhere((element) {
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

            return Dismissible(
              background: Container(
                color: Colors.teal,
              ),
              key: Key(foodEntryForHeadingRaw.id),
              onDismissed: (direction) {
                _diaryBloc.add(
                    RemoveFoodDiaryEntryFromDiary(
                      userId: widget.currentUserProfile.userId,
                      foodDiaryEntryId: foodEntryForHeadingRaw.id
                    )
                );
                // Now we also have to remove it from the state variable
                setState(() {
                  if (heading == "Breakfast") {
                    breakfastEntries.removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  }
                  else if (heading == "Lunch") {
                    lunchEntries.removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  }
                  else if (heading == "Dinner") {
                    dinnerEntries.removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  }
                  else {
                    snackEntries.removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  }

                  final allFoodEntriesRawIndexToRemove = allFoodEntriesRaw.indexWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  allFoodEntriesRaw.removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                  allDetailedFoodEntries.removeAt(allFoodEntriesRawIndexToRemove);
                });

                SnackbarUtils.showSnackBar(context, "Successfully removed $heading entry!");
              },
              child: InkWell(
                onTap: () {
                  // Food tapped
                },
                child: Card(
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
                              "${double.parse(caloriesRaw ?? "0") * foodEntryForHeadingRaw.numberOfServings} calories",
                              style: const TextStyle(
                                  color: Colors.teal
                              ),
                            )
                        )
                      ],
                    ),
                  ),
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

  _renderCardioDiaryEntries(List<CardioDiaryEntry> cardioEntries) {
    return cardioEntries.isNotEmpty ? ListView.builder(
        shrinkWrap: true,
        itemCount: cardioEntries.length,
        itemBuilder: (context, index) {
          final currentCardioEntry = cardioEntries[index];
          return Dismissible(
            background: Container(
              color: Colors.teal,
            ),
            key: Key(currentCardioEntry.id),
            onDismissed: (direction) {
              _diaryBloc.add(
                  RemoveCardioDiaryEntryFromDiary(
                      userId: widget.currentUserProfile.userId,
                      cardioDiaryEntryId: currentCardioEntry.id
                  )
              );

              // Now we also have to remove it from the state variable
              setState(() {
                cardioEntries.removeWhere((element) => element.id == currentCardioEntry.id);
              });

              SnackbarUtils.showSnackBar(context, "Successfully removed cardio entry!");
            },
            child: InkWell(
              onTap: () {
                // Exercise tapped
              },
              child: Card(
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
              ),
            ),
          );
        }
    ) : const Center(
      child: Text("No items here..."),
    );
  }

  _renderStrengthDiaryEntries(List<StrengthDiaryEntry> strengthEntries) {
    return strengthEntries.isNotEmpty ? ListView.builder(
        shrinkWrap: true,
        itemCount: strengthEntries.length,
        itemBuilder: (context, index) {
          final currentStrengthEntry = strengthEntries[index];
          return Dismissible(
            background: Container(
              color: Colors.teal,
            ),
            key: Key(currentStrengthEntry.id),
            onDismissed: (direction) {
              _diaryBloc.add(
                  RemoveStrengthDiaryEntryFromDiary(
                      userId: widget.currentUserProfile.userId,
                      strengthDiaryEntryId: currentStrengthEntry.id
                  )
              );
              // Now we also have to remove it from the state variable
              setState(() {
                strengthEntries.removeWhere((element) => element.id == currentStrengthEntry.id);
              });

              SnackbarUtils.showSnackBar(context, "Successfully removed workout entry!");
            },
            child: InkWell(
              onTap: () {
                // Exercise tapped
              },
              child: Card(
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
              ),
            ),
          );
        }
    ) : const Center(
      child: Text("No items here..."),
    );
  }

  _renderExerciseDiaryEntries(List<CardioDiaryEntry> cardioEntries, List<StrengthDiaryEntry> strengthEntries) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.teal)
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(5),
            child: const Text(
              "Cardio",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              ),
            ),
          ),
          WidgetUtils.spacer(1),
          _renderCardioDiaryEntries(cardioEntries),
          WidgetUtils.spacer(5),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(5),
            child: const Text(
              "Strength",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              ),
            ),
          ),
          WidgetUtils.spacer(1),
          _renderStrengthDiaryEntries(strengthEntries),
        ],
      ),
    );
  }

}