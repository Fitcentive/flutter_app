import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/bloc/select_from_diary_entries_bloc.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/bloc/select_from_diary_entries_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_diary_entries/bloc/select_from_diary_entries_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

typedef UpdateSelectedCardioDiaryEntryIdCallback = void Function(CardioDiaryEntry cardioInfo, bool isSelected);
typedef UpdateSelectedStrengthDiaryEntryIdCallback = void Function(StrengthDiaryEntry cardioInfo, bool isSelected);
typedef UpdateSelectedFoodDiaryEntryIdCallback = void Function(FoodDiaryEntry cardioInfo, bool isSelected);

GlobalKey<SelectFromDiaryEntriesViewState> selectFromFriendsViewStateGlobalKey = GlobalKey();

class SelectFromDiaryEntriesView extends StatefulWidget {

  final PublicUserProfile currentUserProfile;

  final List<String> previouslySelectedCardioDiaryEntryIds;
  final List<String> previouslySelectedStrengthDiaryEntryIds;
  final List<String> previouslySelectedFoodDiaryEntryIds;

  final UpdateSelectedCardioDiaryEntryIdCallback updateSelectedCardioDiaryEntryIdCallback;
  final UpdateSelectedStrengthDiaryEntryIdCallback updateSelectedStrengthDiaryEntryIdCallback;
  final UpdateSelectedFoodDiaryEntryIdCallback updateSelectedFoodDiaryEntryIdCallback;

  const SelectFromDiaryEntriesView({
      super.key,
      required this.currentUserProfile,
      required this.previouslySelectedCardioDiaryEntryIds,
      required this.previouslySelectedStrengthDiaryEntryIds,
      required this.previouslySelectedFoodDiaryEntryIds,
      required this.updateSelectedCardioDiaryEntryIdCallback,
      required this.updateSelectedStrengthDiaryEntryIdCallback,
      required this.updateSelectedFoodDiaryEntryIdCallback
  });

  static Widget withBloc({
    Key? key,
    required PublicUserProfile currentUserProfile,
    required UpdateSelectedCardioDiaryEntryIdCallback updateSelectedCardioDiaryEntryIdCallback,
    required UpdateSelectedStrengthDiaryEntryIdCallback updateSelectedStrengthDiaryEntryIdCallback,
    required UpdateSelectedFoodDiaryEntryIdCallback updateSelectedFoodDiaryEntryIdCallback,
    required List<String> previouslySelectedCardioDiaryEntryIds,
    required List<String> previouslySelectedStrengthDiaryEntryIds,
    required List<String> previouslySelectedFoodDiaryEntryIds,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SelectFromDiaryEntriesBloc>(
            create: (context) => SelectFromDiaryEntriesBloc(
              diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SelectFromDiaryEntriesView(
        key: key,
          currentUserProfile: currentUserProfile,
          previouslySelectedCardioDiaryEntryIds: previouslySelectedCardioDiaryEntryIds,
          previouslySelectedStrengthDiaryEntryIds: previouslySelectedStrengthDiaryEntryIds,
          previouslySelectedFoodDiaryEntryIds: previouslySelectedFoodDiaryEntryIds,
          updateSelectedCardioDiaryEntryIdCallback: updateSelectedCardioDiaryEntryIdCallback,
          updateSelectedStrengthDiaryEntryIdCallback: updateSelectedStrengthDiaryEntryIdCallback,
          updateSelectedFoodDiaryEntryIdCallback: updateSelectedFoodDiaryEntryIdCallback,
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    return SelectFromDiaryEntriesViewState();
  }
}

class SelectFromDiaryEntriesViewState extends State<SelectFromDiaryEntriesView>  with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin  {
  static const int MAX_PAGES = 500;
  static const int MAX_TABS = 3;

  late final TabController _tabController;
  late SelectFromDiaryEntriesBloc _selectFromDiaryEntriesBloc;

  final _scrollController = ScrollController();
  final PageController _pageController = PageController(initialPage: MAX_PAGES ~/ 2);
  static const int INITIAL_PAGE = MAX_PAGES ~/ 2;
  int currentSelectedPage = MAX_PAGES ~/ 2;

  Map<String, bool> cardioDiaryEntryIdToBoolCheckedMap = {};
  Map<String, bool> strengthDiaryEntryIdToBoolCheckedMap = {};
  Map<String, bool> foodDiaryEntryIdToBoolCheckedMap = {};

  DateTime initialSelectedDate = DateTime.now();
  DateTime currentSelectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _selectFromDiaryEntriesBloc = BlocProvider.of<SelectFromDiaryEntriesBloc>(context);
    _selectFromDiaryEntriesBloc.add(
        SelectFromDiaryEntriesFetchInfoEvent(
            userId: widget.currentUserProfile.userId,
            diaryDate: currentSelectedDate
        )
    );
    _tabController = TabController(vsync: this, length: MAX_TABS);

    widget.previouslySelectedCardioDiaryEntryIds.forEach((element) {
        cardioDiaryEntryIdToBoolCheckedMap[element] = true;
    });
    widget.previouslySelectedStrengthDiaryEntryIds.forEach((element) {
      strengthDiaryEntryIdToBoolCheckedMap[element] = true;
    });
    widget.previouslySelectedFoodDiaryEntryIds.forEach((element) {
      foodDiaryEntryIdToBoolCheckedMap[element] = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scrollbar(
      controller: _scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dateHeader(),
          WidgetUtils.spacer(2.5),
          Expanded(
            child: _diaryPageViews(),
          ),
        ],
      ),
    );
  }

  _diaryPageViews() {
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
        _selectFromDiaryEntriesBloc.add(SelectFromDiaryEntriesFetchInfoEvent(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
      },
      itemBuilder: (BuildContext context, int index) {
        return RefreshIndicator(
          onRefresh: () async {
            _selectFromDiaryEntriesBloc.add(SelectFromDiaryEntriesFetchInfoEvent(userId: widget.currentUserProfile.userId, diaryDate: currentSelectedDate));
          },
          child: _renderTabs(),
        );
      },
    );
  }

  _renderTabs() {
    return DefaultTabController(
      length: MAX_TABS,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.run_circle_outlined, color: Colors.teal,),
                child: Text(
                  "Cardio",
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12
                  ),
                ),
              ),
              Tab(
                icon: Icon(Icons.fitness_center, color: Colors.teal),
                child: Text(
                  "Strength",
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12
                  ),
                ),
              ),
              Tab(
                icon: Icon(Icons.bar_chart, color: Colors.teal),
                child: Text(
                  "Nutrition",
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12
                  ),
                ),
              ),
            ],
          ),
        ),
        body: BlocListener<SelectFromDiaryEntriesBloc, SelectFromDiaryEntriesState>(
          listener: (context, state) {
            if (state is SelectFromDiaryEntriesDiaryDataFetched) {

            }
          },
          child: BlocBuilder<SelectFromDiaryEntriesBloc, SelectFromDiaryEntriesState>(
            builder: (context, state) {
              if (state is SelectFromDiaryEntriesDiaryDataFetched) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    renderCardioDiaryEntries(state),
                    renderStrengthDiaryEntries(state),
                    renderNutritionDiaryEntries(state),
                  ],
                );
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
        ),
      ),
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

  _checkBoxCardio(
      CardioDiaryEntry entry,
      ) {
    return Transform.scale(
      scale: 1.25,
      child: Checkbox(
        checkColor: Colors.white,
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          final c = Theme.of(context).primaryColor;
          if (states.contains(MaterialState.disabled)) {
            return c.withOpacity(.32);
          }
          return c;
        }),
        value: cardioDiaryEntryIdToBoolCheckedMap[entry.id] ?? false,
        shape: const CircleBorder(),
        onChanged: (bool? value) {
          setState(() {
            cardioDiaryEntryIdToBoolCheckedMap[entry.id] = value!;
          });

          // Need to update parent bloc state here
          if (value!) {
            widget.updateSelectedCardioDiaryEntryIdCallback(entry, true);
          }
          else if (!value) {
            widget.updateSelectedCardioDiaryEntryIdCallback(entry, false);
          }
        },
      ),
    );
  }

  _checkBoxStrength(
      StrengthDiaryEntry entry,
      ) {
    return Transform.scale(
      scale: 1.25,
      child: Checkbox(
        checkColor: Colors.white,
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          final c = Theme.of(context).primaryColor;
          if (states.contains(MaterialState.disabled)) {
            return c.withOpacity(.32);
          }
          return c;
        }),
        value: strengthDiaryEntryIdToBoolCheckedMap[entry.id] ?? false,
        shape: const CircleBorder(),
        onChanged: (bool? value) {
          setState(() {
            strengthDiaryEntryIdToBoolCheckedMap[entry.id] = value!;
          });

          // Need to update parent bloc state here
          if (value!) {
            widget.updateSelectedStrengthDiaryEntryIdCallback(entry, true);
          }
          else if (!value) {
            widget.updateSelectedStrengthDiaryEntryIdCallback(entry, false);
          }
        },
      ),
    );
  }

  _checkBoxFood(
      FoodDiaryEntry entry,
      ) {
    return Transform.scale(
      scale: 1.25,
      child: Checkbox(
        checkColor: Colors.white,
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          final c = Theme.of(context).primaryColor;
          if (states.contains(MaterialState.disabled)) {
            return c.withOpacity(.32);
          }
          return c;
        }),
        value: foodDiaryEntryIdToBoolCheckedMap[entry.id] ?? false,
        shape: const CircleBorder(),
        onChanged: (bool? value) {
          setState(() {
            foodDiaryEntryIdToBoolCheckedMap[entry.id] = value!;
          });

          // Need to update parent bloc state here
          if (value!) {
            widget.updateSelectedFoodDiaryEntryIdCallback(entry, true);
          }
          else if (!value) {
            widget.updateSelectedFoodDiaryEntryIdCallback(entry, false);
          }
        },
      ),
    );
  }

  renderCardioDiaryEntries(SelectFromDiaryEntriesDiaryDataFetched state) {
    return Scrollbar(
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: state.cardioDiaryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          final currentCardioEntry = state.cardioDiaryEntries[index];
          return Row(
            children: [
              Expanded(
                  flex: 2,
                  child: _checkBoxCardio(currentCardioEntry),
              ),
              Expanded(
                  flex: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                      currentCardioEntry.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                      )
                                  )
                              )
                          ),
                          Expanded(
                              flex: 1,
                              child: Text(
                                "${currentCardioEntry.durationInMinutes} minutes",
                                  style: const TextStyle(
                                    fontSize: 10,
                                  )
                              )
                          ),
                          Expanded(
                              flex: 1,
                              child: Text(
                                "${currentCardioEntry.caloriesBurned.toInt()} calories",
                                style: const TextStyle(
                                    color: Colors.teal,
                                  fontSize: 10
                                ),
                              )
                          )
                        ],
                      ),
                    ),
                  ),
              )
            ],
          );
        },
      ),
    );
  }

  renderStrengthDiaryEntries(SelectFromDiaryEntriesDiaryDataFetched state) {
    return Scrollbar(
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: state.cardioDiaryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          final currentStrengthEntry = state.strengthDiaryEntries[index];

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _checkBoxStrength(currentStrengthEntry),
              ),
              Expanded(
                flex: 8,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 6,
                            child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                    currentStrengthEntry.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    )
                                )
                            )
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(
                                "${currentStrengthEntry.sets} sets",
                                style: const TextStyle(
                                  fontSize: 10,
                                )
                            )
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(
                                "${currentStrengthEntry.reps} reps",
                                style: const TextStyle(
                                  fontSize: 10,
                                )
                            )
                        ),
                        Expanded(
                            flex: 4,
                            child: Text(
                              "${currentStrengthEntry.caloriesBurned.toInt()} calories",
                              style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10,
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  renderNutritionDiaryEntries(SelectFromDiaryEntriesDiaryDataFetched state) {
    return Scrollbar(
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: state.cardioDiaryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          final detailedFoodEntry = state.foodDiaryEntries[index];
          final detailedFoodEntryRaw = state.foodDiaryEntriesRaw[index];
          final caloriesRaw = detailedFoodEntry.isLeft ?
            detailedFoodEntry.left.food.servings.serving.firstWhere((element) => element.serving_id == detailedFoodEntryRaw.servingId.toString()).calories :
            detailedFoodEntry.right.food.servings.serving.calories;

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _checkBoxFood(detailedFoodEntryRaw),
              ),
              Expanded(
                flex: 8,
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
                                        detailedFoodEntry.isLeft ? detailedFoodEntry.left.food.food_name : detailedFoodEntry.right.food.food_name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        )
                                    )
                                ),
                                Container(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      "${detailedFoodEntryRaw.numberOfServings.toStringAsFixed(2)} servings",
                                      style: const TextStyle(
                                          fontSize: 10
                                      ),
                                    )
                                ),
                              ],
                            )
                        ),
                        Expanded(
                            flex: 4,
                            child: Text(
                              "${(double.parse(caloriesRaw ?? "0") * detailedFoodEntryRaw.numberOfServings).toStringAsFixed(0)} calories",
                              style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

}