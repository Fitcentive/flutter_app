import 'package:age_calculator/age_calculator.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_bloc.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_app/src/views/exercise_diary/exercise_diary_view.dart';
import 'package:flutter_app/src/views/exercise_search/exercise_search_view.dart';
import 'package:flutter_app/src/views/food_diary/food_diary_view.dart';
import 'package:flutter_app/src/views/food_search/food_search_view.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_state.dart';
import 'package:flutter_app/src/views/shared_components/daily_summary_card.dart';
import 'package:flutter_app/src/views/user_fitness_profile/user_fitness_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

GlobalKey<DiaryViewState> diaryViewStateGlobalKey = GlobalKey();

class DiaryView extends StatefulWidget {
  static const String routeName = "exercise/search";

  final DateTime? preSelectedDateTime;
  final PublicUserProfile currentUserProfile;
  final UserProfile rawUserProfile;

  const DiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.rawUserProfile,
    this.preSelectedDateTime
  }): super(key: key);

  static Widget withBloc(
      Key? key,
      PublicUserProfile currentUserProfile,
      UserProfile rawUserProfile,
      DateTime? preSelectedDateTime
  ) => MultiBlocProvider(
    providers: [
      BlocProvider<DiaryBloc>(
          create: (context) => DiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: DiaryView(
        key: key,
        currentUserProfile: currentUserProfile,
        rawUserProfile: rawUserProfile,
        preSelectedDateTime: preSelectedDateTime
    ),
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
    3: "Snack",
    4: "Exercise",
  };

  late DiaryBloc _diaryBloc;
  late MenuNavigationBloc _menuNavigationBloc;

  bool _isFloatingButtonVisible = true;

  DateTime initialSelectedDate = DateTime.now();
  DateTime currentSelectedDate = DateTime.now();

  bool isStrengthPanelExpanded = true;
  bool isStepsPanelExpanded = true;
  bool isCardioPanelExpanded = true;

  bool isBreakfastPanelExpanded = true;
  bool isLunchPanelExpanded = true;
  bool isDinnerPanelExpanded = true;
  bool isSnacksPanelExpanded = true;

  int currentSelectedPageBuilderPage = MAX_PAGES ~/ 2;
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

  late Stream<StepCount> _stepCountStream;
  int pedometerStepCount = 0;

  /// int currentSelectedPageBuilderPage = MAX_PAGES ~/ 2 sets page as mid for current date
  /// If currentSelectedDate is diff, we need to offset accordimngly
  setCurrentSelectedPageBuilderPageValue() {
    if (currentSelectedDate.dateYMD != initialSelectedDate.dateYMD) {
      final currentDateYmd = DateTime(currentSelectedDate.year, currentSelectedDate.month, currentSelectedDate.day);
      final initialDateYmd = DateTime(initialSelectedDate.year, initialSelectedDate.month, initialSelectedDate.day);
      currentSelectedPageBuilderPage = currentSelectedPageBuilderPage + currentDateYmd.difference(initialDateYmd).inDays;
    }
  }

  _setupPedometer() async {
    if (DeviceUtils.isMobileDevice()) {
      _stepCountStream = Pedometer.stepCountStream;
      if(await Permission.activityRecognition.request().isGranted) {
        _stepCountStream.listen(onStepCount).onError(onStepCountError);
      }
      else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.activityRecognition,
        ].request();
        if (statuses[Permission.activityRecognition] == PermissionStatus.denied) {
          if (await Permission.speech.isPermanentlyDenied) {
            openAppSettings();
          }
        }
        else {
          _setupPedometer();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    currentSelectedDate = widget.preSelectedDateTime ?? currentSelectedDate;
    setCurrentSelectedPageBuilderPageValue();

    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);
    _diaryBloc = BlocProvider.of<DiaryBloc>(context);
    _diaryBloc.add(const TrackViewDiaryHomeEvent());
    _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
    _scrollController.addListener(_onScroll);

    _setupPedometer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
  }

  void onStepCount(StepCount event) {
    setState(() {
      pedometerStepCount = event.steps;
    });
  }

  goToUserFitnessProfileView() {
    final currentState = _diaryBloc.state;
    if (currentState is DiaryDataFetched) {
      Navigator.push<FitnessUserProfile>(
          context,
          UserFitnessProfileView.route(widget.currentUserProfile, currentState.fitnessUserProfile)
      ).then((value) {
        if (value != null) { // This means user did not update profile accordingly, we pop back to previous screen before coming here
          _diaryBloc.add(UserFitnessProfileUpdated(fitnessUserProfile: value));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _animatedButton(),
      bottomNavigationBar: IntrinsicHeight(
        child: BottomAppBar(
          color: Colors.transparent,
          child: _showDailySummaryButton(),
          elevation: 0,
        ),
      ),
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

              if (state.cardioDiaryEntries.isEmpty) {
                isCardioPanelExpanded = false;
              } else {
                isCardioPanelExpanded = true;
              }

              if (state.strengthDiaryEntries.isEmpty) {
                isStrengthPanelExpanded = false;
              } else {
                isStrengthPanelExpanded = true;
              }
              if (!currentSelectedDaySameAsCurrentDay() && state.userStepsData == null) {
                isStepsPanelExpanded = false;
              } else {
                isStepsPanelExpanded = true;
              }

              if (breakfastEntries.isEmpty) {
                isBreakfastPanelExpanded = false;
              } else {
                isBreakfastPanelExpanded = true;
              }

              if (dinnerEntries.isEmpty) {
                isDinnerPanelExpanded = false;
              } else {
                isDinnerPanelExpanded = true;
              }

              if (lunchEntries.isEmpty) {
                isLunchPanelExpanded = false;
              } else {
                isLunchPanelExpanded = true;
              }

              if (snackEntries.isEmpty) {
                isSnacksPanelExpanded = false;
              } else {
                isSnacksPanelExpanded = true;
              }
            });

            // If no fitness profile is found, we want to force the user to update this
            if (state.fitnessUserProfile == null) {
              Navigator.push<FitnessUserProfile>(
                  context,
                  UserFitnessProfileView.route(widget.currentUserProfile, null)
              )
              .then((value) {
                if (value == null) { // This means user did not update profile accordingly, we pop back to previous screen before coming here
                  final currentMenuNavigationState = _menuNavigationBloc.state;
                  if (currentMenuNavigationState is MenuItemSelected) {
                    _menuNavigationBloc.add(
                        MenuItemChosen(
                          selectedMenuItem: currentMenuNavigationState.previouslySelectedMenuItem!, // We are guaranteed to have this based on flow
                          currentUserId: widget.currentUserProfile.userId,
                        )
                    );
                  }
                }
                else {
                  _diaryBloc.add(UserFitnessProfileUpdated(fitnessUserProfile: value));
                }
              });
            }
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
                _goToFoodSearchView("Snack");
              },
            )
          ],
        )
      ),
    );
  }

  _goToExerciseSearchView() {
    final currentState = _diaryBloc.state;
    if (currentState is DiaryDataFetched && currentState.fitnessUserProfile != null) {
      Navigator
          .push(context, ExerciseSearchView.route(widget.currentUserProfile, currentState.fitnessUserProfile!, currentSelectedDate))
          .then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
    }
  }

  _goToFoodSearchView(String mealOfDay) {
    Navigator
        .push(context, FoodSearchView.route(widget.currentUserProfile, mealOfDay, currentSelectedDate))
        .then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
  }

  _caloriesHeader(DiaryDataFetched state) {
    final allFoodIds = allFoodEntriesRaw.map((e) => e.foodId.toString());
    final foodCalories = allFoodEntriesRaw.isEmpty ? 0 : allFoodEntriesRaw.map((e) {
      final current = allDetailedFoodEntries.where((element) {
        if (element.isLeft) {
          return element.left.food.food_id == e.foodId.toString();
        }
        else {
          return element.right.food.food_id == e.foodId.toString();
        }
      }).first;

      if (current.isLeft) {
        if (allFoodIds.contains(current.left.food.food_id)) {
          final rawEntry = allFoodEntriesRaw.firstWhere((element) => element.foodId.toString() == current.left.food.food_id);
          return double.parse(
              (current.left.food.servings.serving
                  .firstWhere((element) => element.serving_id == rawEntry.servingId.toString()).calories ?? "0")
              )
              * rawEntry.numberOfServings;
        }
        else {
          return 0;
        }
      }
      else {
        if (allFoodIds.contains(current.right.food.food_id)) {
          final rawEntry = allFoodEntriesRaw.firstWhere((element) => element.foodId.toString() == current.right.food.food_id);
          return double.parse(current.right.food.servings.serving.calories ?? "0") * rawEntry.numberOfServings;
        }
        else {
          return 0;
        }
      }
    }).reduce((value, element) => value + element);
    final cardioCalories = cardioEntries.isEmpty ? 0 : cardioEntries.map((e) => e.caloriesBurned).reduce((value, element) => value + element);
    final strengthCalories = strengthEntries.isEmpty ? 0 : strengthEntries.map((e) => e.caloriesBurned).reduce((value, element) => value + element);
    final stepsCalories = state.userStepsData?.caloriesBurned ?? 0;

    final targetCalories = _generateCalorieGoal(state);
    final remainingCalories = targetCalories - foodCalories + cardioCalories + strengthCalories + stepsCalories;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    targetCalories.toStringAsFixed(0),
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
                      foodCalories.toStringAsFixed(0),
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
                      (cardioCalories + strengthCalories).toStringAsFixed(0),
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
                      remainingCalories.toStringAsFixed(0),
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
        ),
        WidgetUtils.spacer(2.5),
        Center(
          child: LinearPercentIndicator(
            lineHeight: 15.0,
            barRadius: const Radius.elliptical(5, 10),
            percent: (1 - (remainingCalories / targetCalories)),
            center: Text(
                "${((1 - (remainingCalories / targetCalories)) * 100).toStringAsFixed(1)}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12
              ),
            ),
            backgroundColor: Colors.grey.shade400,
            progressColor: Colors.teal,
          ),
        )
      ],
    );
  }

  double _generateCalorieGoal(DiaryDataFetched state) {
    if (state.fitnessUserProfile != null) {
      return ExerciseUtils.calculateCalorieGoalPerDayForUserToAttainGoal(
          state.fitnessUserProfile!,
          AgeCalculator.age(DateTime.parse(widget.rawUserProfile.dateOfBirth!)).years,
          widget.currentUserProfile.gender,
      );
    }
    else {
      return defaultCaloriesTargetPerDay.toDouble();
    }
  }

  _dateHeader() {
    return Column(
      children: WidgetUtils.skipNulls([
        Row(
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
                  _pageController.animateToPage(currentSelectedPageBuilderPage - 1, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
                },
              ),
            ),
            Expanded(
                flex: 6,
                child: InkWell(
                  onTap: () async {
                    // We show a datepicker here for easy jumping
                    final selectedDate = await showDatePicker(
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                            data: ThemeData(primarySwatch: Colors.teal),
                            child: child!
                        );
                      },
                      context: context,
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      initialDate: currentSelectedDate,
                      firstDate: DateTime(ConstantUtils.EARLIEST_YEAR),
                      lastDate: DateTime(ConstantUtils.LATEST_YEAR),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        currentSelectedPageBuilderPage = currentSelectedPageBuilderPage +
                            selectedDate.difference(currentSelectedDate.subtract(Duration(
                              hours: currentSelectedDate.hour,
                              minutes: currentSelectedDate.minute,
                              seconds: currentSelectedDate.second,
                              milliseconds: currentSelectedDate.millisecond,
                            ))).inDays;
                        currentSelectedDate = selectedDate;
                      });
                      _pageController.animateToPage(currentSelectedPageBuilderPage , duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
                    }
                  },
                  child: Center(
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(currentSelectedDate),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
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
                  _pageController.animateToPage(currentSelectedPageBuilderPage + 1, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
                },
              ),
            ),
          ],
        ),
        _showJumpToTodaysDateTextIfNeeded(),
      ]),
    );
  }

  bool currentSelectedDaySameAsCurrentDay() {
    if (currentSelectedDate.subtract(Duration(
      hours: currentSelectedDate.hour,
      minutes: currentSelectedDate.minute,
      seconds: currentSelectedDate.second,
      milliseconds: currentSelectedDate.millisecond,
    )).difference(initialSelectedDate.subtract(Duration(
      hours: initialSelectedDate.hour,
      minutes: initialSelectedDate.minute,
      seconds: initialSelectedDate.second,
      milliseconds: initialSelectedDate.millisecond,
    ))).inDays == 0) {
      return true;
    }
    return false;
  }

  _showJumpToTodaysDateTextIfNeeded() {
    if (!currentSelectedDaySameAsCurrentDay()) {
      return GestureDetector(
        onTap: () {
          setState(() {
            currentSelectedDate = initialSelectedDate;
          });
          _pageController.animateToPage(MAX_PAGES ~/ 2, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WidgetUtils.spacer(1.5),
            const Text(
              "Jump to today's date",
              style: TextStyle(
                color: Colors.teal
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      );
    }
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
          WidgetUtils.spacer(2.5),
          _renderStepInfo(state),
          WidgetUtils.spacer(5),
          Expanded(
            child: _diaryPageViews(state),
          ),
        ],
      ),
    );
  }

  _renderStepInfo(DiaryDataFetched state) {
    final double stepGoalPercentage;
    final String stepCountString;
    if (currentSelectedDaySameAsCurrentDay() && DeviceUtils.isMobileDevice()) {
      stepGoalPercentage = ((pedometerStepCount / (state.fitnessUserProfile?.stepGoalPerDay ?? ExerciseUtils.defaultStepGoal)) * 100);
      stepCountString = pedometerStepCount.toString();
    }
    else {
      stepGoalPercentage = (((state.userStepsData?.steps ?? 0) / (state.fitnessUserProfile?.stepGoalPerDay ?? ExerciseUtils.defaultStepGoal)) * 100);
      stepCountString = state.userStepsData?.steps.toString() ?? "0";
    }

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
                percent: stepGoalPercentage / 100,
                center: Text(
                  "${stepGoalPercentage.toStringAsFixed(1)}%",
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
                "$stepCountString steps",
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

  _diaryPageViews(DiaryDataFetched state) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (pageNumber) {
        currentSelectedPageBuilderPage = pageNumber;
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
        return ListView.builder(
          shrinkWrap: true,
          controller: _scrollController,
          itemCount: listItemIndexToTitleMap.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              padding: const EdgeInsets.all(5),
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
        );
      },
    );
  }

  _renderDiaryEntries(String heading, DiaryDataFetched state) {
    if (heading == listItemIndexToTitleMap[4]!) {
      return _renderExerciseDiaryEntries(state);
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
    return ExpansionPanelList(
        expansionCallback: (index, isExpanded) {
          setState(() {
            if (listItemIndexToTitleMap.values.contains(heading)) {
              if (heading == listItemIndexToTitleMap[0]!) {
                isBreakfastPanelExpanded = !isExpanded;
              }
              else if (heading == listItemIndexToTitleMap[1]!) {
                isLunchPanelExpanded = !isExpanded;
              }
              else if (heading == listItemIndexToTitleMap[2]!) {
                isDinnerPanelExpanded = !isExpanded;
              }
              else {
                isSnacksPanelExpanded = !isExpanded;
              }
            }
          });
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text(
                  heading,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.grey
                  ),
                ),
              );
            },
            body: foodEntriesForHeadingRaw.isNotEmpty ? ListView.builder(
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
                    background: WidgetUtils.viewUnderDismissibleListTile(),
                    direction: DismissDirection.endToStart,
                    key: Key(foodEntryForHeadingRaw.id),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        // Now we also have to remove it from the state variable
                        setState(() {
                          if (heading == "Breakfast") {
                            breakfastEntries = List.from(breakfastEntries)..removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          }
                          else if (heading == "Lunch") {
                            lunchEntries = List.from(lunchEntries)..removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          }
                          else if (heading == "Dinner") {
                            dinnerEntries = List.from(dinnerEntries)..removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          }
                          else {
                            snackEntries = List.from(snackEntries)..removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          }

                          // final allFoodEntriesRawIndexToRemove = allFoodEntriesRaw.indexWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          allFoodEntriesRaw = List.from(allFoodEntriesRaw)..removeWhere((element) => element.id == foodEntryForHeadingRaw.id);
                          // allDetailedFoodEntries = List.from(allDetailedFoodEntries)..removeAt(allFoodEntriesRawIndexToRemove);
                        });

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          SnackBar(
                              duration: const Duration(milliseconds: 1500),
                              content: Text("Successfully removed $heading entry!"),
                              action: SnackBarAction(
                                  label: "Undo",
                                  onPressed: () {
                                    setState(() {
                                      if (heading == "Breakfast") {
                                        breakfastEntries = List.from(breakfastEntries)..add(foodEntryForHeadingRaw);
                                      }
                                      else if (heading == "Lunch") {
                                        lunchEntries = List.from(lunchEntries)..add(foodEntryForHeadingRaw);
                                      }
                                      else if (heading == "Dinner") {
                                        dinnerEntries = List.from(dinnerEntries)..add(foodEntryForHeadingRaw);
                                      }
                                      else {
                                        snackEntries = List.from(snackEntries)..add(foodEntryForHeadingRaw);
                                      }

                                      allFoodEntriesRaw = List.from(allFoodEntriesRaw)..add(foodEntryForHeadingRaw);
                                    });
                                  })
                          ),
                        )
                            .closed
                            .then((value) {
                          if (value != SnackBarClosedReason.action) {
                            _diaryBloc.add(
                                RemoveFoodDiaryEntryFromDiary(
                                    userId: widget.currentUserProfile.userId,
                                    foodDiaryEntryId: foodEntryForHeadingRaw.id
                                )
                            );
                          }
                        });
                      }
                    },
                    child: InkWell(
                      onTap: () {
                        _goToDetailedFoodView(foodEntryForHeadingRaw.foodId, foodEntryForHeadingRaw.id, heading);
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
                                    "${(double.parse(caloriesRaw ?? "0") * foodEntryForHeadingRaw.numberOfServings).toStringAsFixed(0)} calories",
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
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text("No items here..."),
              ),
            ),
            isExpanded: _getIsExpandedVariable(heading),
          )
        ],
      );
  }

  _getIsExpandedVariable(String heading) {
    if (listItemIndexToTitleMap.values.contains(heading)) {
      if (heading == listItemIndexToTitleMap[0]!) {
        return isBreakfastPanelExpanded;
      }
      else if (heading == listItemIndexToTitleMap[1]!) {
        return isLunchPanelExpanded;
      }
      else if (heading == listItemIndexToTitleMap[2]!) {
        return isDinnerPanelExpanded;
      }
      else {
        return isSnacksPanelExpanded;
      }
    }
  }

  _renderCardioDiaryEntries(DiaryDataFetched state) {
    return cardioEntries.isNotEmpty ? ListView.builder(
        shrinkWrap: true,
        itemCount: cardioEntries.length,
        itemBuilder: (context, index) {
          final currentCardioEntry = cardioEntries[index];
          return Dismissible(
            background: WidgetUtils.viewUnderDismissibleListTile(),
            direction: DismissDirection.endToStart,
            key: Key(currentCardioEntry.id),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Now we also have to remove it from the state variable
                setState(() {
                  cardioEntries = List.from(cardioEntries)..removeWhere((element) => element.id == currentCardioEntry.id);
                });

                ScaffoldMessenger
                    .of(context)
                    .showSnackBar(
                  SnackBar(
                      duration: const Duration(milliseconds: 1500),
                      content: const Text("Successfully removed cardio entry!"),
                      action: SnackBarAction(
                          label: "Undo",
                          onPressed: () {
                            setState(() {
                              cardioEntries = List.from(cardioEntries)..add(currentCardioEntry);
                            });
                          }) // this is what you needed
                  ),
                )
                .closed
                .then((value) {
                  _diaryBloc.add(
                      RemoveCardioDiaryEntryFromDiary(
                          userId: widget.currentUserProfile.userId,
                          cardioDiaryEntryId: currentCardioEntry.id
                      )
                  );
                });
              }
            },
            child: InkWell(
              onTap: () {
                _goToDetailedExerciseView(state, currentCardioEntry.workoutId, currentCardioEntry.id, true);
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
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text("No items here..."),
      ),
    );
  }

  _renderStrengthDiaryEntries(DiaryDataFetched state) {
    return strengthEntries.isNotEmpty ? ListView.builder(
        shrinkWrap: true,
        itemCount: strengthEntries.length,
        itemBuilder: (context, index) {
          final currentStrengthEntry = strengthEntries[index];
          return Dismissible(
            background: WidgetUtils.viewUnderDismissibleListTile(),
            key: Key(currentStrengthEntry.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Now we also have to remove it from the state variable
                setState(() {
                  strengthEntries = List.from(strengthEntries)..removeWhere((element) => element.id == currentStrengthEntry.id);
                });

                ScaffoldMessenger
                    .of(context)
                    .showSnackBar(
                  SnackBar(
                      duration: const Duration(milliseconds: 1500),
                      content: const Text("Successfully removed workout entry!"),
                      action: SnackBarAction(
                          label: "Undo",
                          onPressed: () {
                            setState(() {
                              strengthEntries = List.from(strengthEntries)..add(currentStrengthEntry);
                            });
                          }) // this is what you needed
                  ),
                )
                .closed
                .then((value) {
                  _diaryBloc.add(
                      RemoveStrengthDiaryEntryFromDiary(
                          userId: widget.currentUserProfile.userId,
                          strengthDiaryEntryId: currentStrengthEntry.id
                      )
                  );
                });
              }
            },
            child: InkWell(
              onTap: () {
                _goToDetailedExerciseView(state, currentStrengthEntry.workoutId, currentStrengthEntry.id, false);
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
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text("No items here..."),
      ),
    );
  }

  _renderStepsData(DiaryDataFetched state) {
    final String stepsToShow;
    if (currentSelectedDaySameAsCurrentDay() && DeviceUtils.isMobileDevice()) {
      stepsToShow = pedometerStepCount.toString();
    }
    else {
      stepsToShow = (state.userStepsData?.steps ?? 0).toString();
    }
    return ExpansionPanelList(
      expansionCallback: (index, isExpanded) {
        setState(() {
          isStepsPanelExpanded = !isExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return const ListTile(
              title: Text(
                "Steps",
                style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.grey
                ),
              ),
            );
          },
          body: Card(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 12,
                      child: Container(
                          padding: const EdgeInsets.all(5),
                          child: Text("$stepsToShow steps")
                      )
                  ),
                  Expanded(
                      flex: 4,
                      child: Text(
                        "${(state.userStepsData?.caloriesBurned ?? 0).toInt()} calories",
                        style: const TextStyle(
                            color: Colors.teal
                        ),
                      )
                  )
                ],
              ),
            ),
          ),
          isExpanded: isStepsPanelExpanded,
        )
      ],
    );
  }

  _renderStrengthEntries(DiaryDataFetched state) {
    return ExpansionPanelList(
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
                style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.grey
                ),
              ),
            );
          },
          body: _renderStrengthDiaryEntries(state),
          isExpanded: isStrengthPanelExpanded,
        )
      ],
    );
  }

  _renderCardioEntries(DiaryDataFetched state) {
    return ExpansionPanelList(
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
                style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.grey
                ),
              ),
            );
          },
          body: _renderCardioDiaryEntries(state),
          isExpanded: isCardioPanelExpanded,
        )
      ],
    );
  }

  _renderExerciseDiaryEntries(DiaryDataFetched state) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.teal)
      ),
      child: Column(
        children: [
          _renderCardioEntries(state),
          WidgetUtils.spacer(5),
          _renderStrengthEntries(state),
          WidgetUtils.spacer(5),
          _renderStepsData(state),
        ],
      ),
    );
  }

  _goToDetailedExerciseView(DiaryDataFetched state, String workoutId, String diaryEntryId, bool isCardio) {
    Navigator.push(
        context,
        ExerciseDiaryView.route(
            widget.currentUserProfile,
            state.fitnessUserProfile!,
            workoutId,
            diaryEntryId,
            isCardio,
            currentSelectedDate
        )
      ).then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
  }

  _goToDetailedFoodView(int foodId, String diaryEntryId, String mealOfDay) {
    Navigator.push(
        context,
        FoodDiaryView.route(
            widget.currentUserProfile,
            foodId,
            diaryEntryId,
            currentSelectedDate,
            mealOfDay
        )
    ).then((value) => _diaryBloc.add(FetchDiaryInfo(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate)));
  }

  _showDailySummaryButton() {
    return BlocBuilder<DiaryBloc, DiaryState>(
        builder: (context, state) {
          return Visibility(
            visible: state is DiaryDataFetched,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(ColorUtils.BUTTON_AVAILABLE),
                ),
                onPressed: () async {
                  final state = _diaryBloc.state;
                  if (state is DiaryDataFetched) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
                              ),
                              child: DailySummaryCardView(
                                strengthDiaryEntries: state.strengthDiaryEntries,
                                cardioDiaryEntries: state.cardioDiaryEntries,
                                foodDiaryEntriesRaw: state.foodDiaryEntriesRaw,
                                foodDiaryEntries: state.foodDiaryEntries,
                                userStepsData: state.userStepsData,
                                selectedDate: currentSelectedDate,
                              ),
                            ),
                          );
                        }
                    );
                  }
                },
                child: const Text("View daily summary", style: TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ),
          );
        }
    );
  }
}