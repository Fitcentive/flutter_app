import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_bloc.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_app/src/views/exercise_search/exercise_search_view.dart';
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

  static const listItemIndexToTitleMap = {
    0: "Breakfast",
    1: "Lunch",
    2: "Dinner",
    3: "Snacks",
    4: "Exercise",
  };
  static const double _scrollThreshold = 200.0;

  late DiaryBloc _diaryBloc;

  bool _isFloatingButtonVisible = true;

  DateTime initialSelectedDate = DateTime.now();
  DateTime currentSelectedDate = DateTime.now();

  int currentPage = 0;
  final PageController _pageController = PageController(initialPage: MAX_PAGES ~/ 2);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _diaryBloc = BlocProvider.of<DiaryBloc>(context);
    _diaryBloc.add(FetchDiaryInfo(diaryDate: DateTime.now()));
    _scrollController.addListener(_onScroll);
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
                // _goToExerciseSearchView();
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
                // _goToExerciseSearchView();
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToDinnerDiaryButton",
              tooltip: 'Add breakfast foods!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.dinner_dining,
                  color: Colors.white
              ),
              onPressed: () {
                // _goToExerciseSearchView();
              },
            ),
            FloatingActionButton.small(
              heroTag: "DiaryViewAddToSnackDiaryButton",
              tooltip: 'Add breakfast foods!',
              backgroundColor: Colors.teal,
              child: const Icon(
                  Icons.emoji_food_beverage,
                  color: Colors.white
              ),
              onPressed: () {
                // _goToExerciseSearchView();
              },
            )
          ],
        )
      ),
    );
  }

  _goToExerciseSearchView() {
    Navigator.pushAndRemoveUntil(context, ExerciseSearchView.route(widget.currentUserProfile), (route) => true);
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

            },
          ),
        ),
        Expanded(
            flex: 6,
            child: Center(
              child: Text(
                DateFormat('yyyy-MM-dd').format(currentSelectedDate),
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
        final daysToAdd = pageNumber - INITIAL_PAGE;
        setState(() {
          if (daysToAdd < 0) {
            currentSelectedDate = initialSelectedDate.subtract(Duration(days: daysToAdd.abs()));
          }
          else {
            currentSelectedDate = initialSelectedDate.add(Duration(days: daysToAdd));

          }
        });
      },
      itemBuilder: (BuildContext context, int index) {
        return RefreshIndicator(
          onRefresh: () async {

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
                        const Center(
                          child: Text("No items here..."),
                        ),
                        WidgetUtils.spacer(1.5),
                        InkWell(
                          onTap: () {
                            if (index == 4) {
                              _goToExerciseSearchView();
                            }
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
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

}