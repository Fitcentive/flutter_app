import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_bloc.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_event.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_mini_card_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/select_from_meetups_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class ExerciseDiaryView extends StatefulWidget {

  static const String routeName = "diary/view-exercise";

  final PublicUserProfile currentUserProfile;
  final FitnessUserProfile currentFitnessUserProfile;
  final String workoutId;
  final String diaryEntryId;
  final bool isCurrentExerciseDefinitionCardio;
  final DateTime selectedDayInQuestion;

  const ExerciseDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.currentFitnessUserProfile,
    required this.workoutId,
    required this.diaryEntryId,
    required this.isCurrentExerciseDefinitionCardio,
    required this.selectedDayInQuestion
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      String workoutId,
      String diaryEntryId,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => ExerciseDiaryView.withBloc(
            currentUserProfile,
            currentFitnessUserProfile,
            workoutId,
            diaryEntryId,
            isCurrentExerciseDefinitionCardio,
            selectedDayInQuestion
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      String workoutId,
      String diaryEntryId,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<ExerciseDiaryBloc>(
          create: (context) => ExerciseDiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: ExerciseDiaryView(
      currentUserProfile: currentUserProfile,
      currentFitnessUserProfile: currentFitnessUserProfile,
      workoutId: workoutId,
      isCurrentExerciseDefinitionCardio: isCurrentExerciseDefinitionCardio,
      selectedDayInQuestion: selectedDayInQuestion,
      diaryEntryId: diaryEntryId,
    ),
  );



  @override
  State<StatefulWidget> createState() {
    return ExerciseDiaryViewState();
  }

}

class ExerciseDiaryViewState extends State<ExerciseDiaryView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 3;

  late ExerciseDiaryBloc _exerciseDiaryBloc;
  late final TabController _tabController;

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  final TextEditingController _mintuesPerformedTextController = TextEditingController();
  final TextEditingController _setsTextController = TextEditingController();
  final TextEditingController _repsTextController = TextEditingController();
  final TextEditingController _caloriesBurnedTextController = TextEditingController();

  DateTime selectedWorkoutDateTime = DateTime.now();
  String cardioMinutesPerformed = "";
  String setsPerformed = "";
  String repsPerformed = "";

  Meetup? associatedMeetup;
  List<MeetupParticipant>? associatedMeetupParticipants;
  List<MeetupDecision>? associatedMeetupDecisions;
  Map<String, PublicUserProfile>? associatedUserIdProfileMap;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: MAX_TABS);

    _exerciseDiaryBloc = BlocProvider.of<ExerciseDiaryBloc>(context);
    _exerciseDiaryBloc.add(FetchExerciseDiaryEntryInfo(
        userId: widget.currentUserProfile.userId,
        workoutId: widget.workoutId,
        diaryEntryId: widget.diaryEntryId,
        isCardio: widget.isCurrentExerciseDefinitionCardio,
    ));

    selectedWorkoutDateTime = widget.selectedDayInQuestion;
  }

  @override
  void dispose() {
    _mintuesPerformedTextController.dispose();
    _setsTextController.dispose();
    _repsTextController.dispose();
    _caloriesBurnedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      body: BlocListener<ExerciseDiaryBloc, ExerciseDiaryState>(
        listener: (context, state) {
          if (state is ExerciseEntryUpdatedAndReadyToPop) {
            SnackbarUtils.showSnackBarMedium(context, "Diary entry updated successfully!");
            Navigator.pop(context);
          }
          else if (state is ExerciseDiaryDataLoaded) {
            setState(() {
              if (state.diaryEntry.isLeft) {
                selectedWorkoutDateTime = state.diaryEntry.left.cardioDate.toLocal();
                cardioMinutesPerformed = state.diaryEntry.left.durationInMinutes.toString();
                _mintuesPerformedTextController.text = cardioMinutesPerformed;
                _caloriesBurnedTextController.text =
                    ExerciseUtils.calculateCaloriesBurnedForCardioActivity(
                        widget.currentFitnessUserProfile,
                        state.exerciseDefinition.name,
                        state.diaryEntry.left.durationInMinutes
                    ).toStringAsFixed(0);

              }
              else {
                selectedWorkoutDateTime = state.diaryEntry.right.exerciseDate.toLocal();
                setsPerformed = state.diaryEntry.right.sets.toString();
                repsPerformed = state.diaryEntry.right.reps.toString();

                _setsTextController.text = setsPerformed;
                _repsTextController.text = repsPerformed;
                _caloriesBurnedTextController.text =
                    ExerciseUtils.calculateCaloriesBurnedForNonCardioActivity(
                        widget.currentFitnessUserProfile,
                        state.exerciseDefinition.name,
                        state.diaryEntry.right.sets,
                        state.diaryEntry.right.reps
                    ).toStringAsFixed(0);
              }
            });

            // Setstate pertaining to meetup info
            if (state.associatedMeetup != null) {
              setState(() {
                associatedMeetup = state.associatedMeetup!.meetup;
                associatedMeetupParticipants = state.associatedMeetup!.participants;
                associatedMeetupDecisions = state.associatedMeetup!.decisions;
                associatedUserIdProfileMap = state.associatedUserIdProfileMap;
              });
            }
          }
        },
        child: BlocBuilder<ExerciseDiaryBloc, ExerciseDiaryState>(
          builder: (context, state) {
            if (state is ExerciseDiaryDataLoaded) {
              return _mainBody(state);
            }
            else {
              if (DeviceUtils.isAppRunningOnMobileBrowser()) {
                return WidgetUtils.progressIndicator();
              }
              else {
                return _skeletonLoadingScreen();
              }
            }
          },
        ),
      ),
    );
  }

  _skeletonLoadingScreen() {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: const Text("Edit Exercise Entry", style: TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, color: Colors.teal,), text: "Entry"),
                Tab(icon: Icon(Icons.info, color: Colors.teal,), text: "Info"),
                Tab(icon: Icon(Icons.fitness_center, color: Colors.teal,), text: "Muscles"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _skeletonTab(),
              _skeletonTab(),
              _skeletonTab(),
            ],
          ),
        )
    );
  }

  _skeletonTab() {
    return SkeletonLoader(
      builder : Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: ScreenUtils.getScreenHeight(context) * 0.75,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: WidgetUtils.skipNulls(
                          [
                            Row(
                              children: [
                                // Name, date and time
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      const Text("Unnamed meetup", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ) ,),
                                      WidgetUtils.spacer(5),
                                      const Text("Time unset", style: TextStyle(fontSize: 16),),
                                      WidgetUtils.spacer(5),
                                      const Text("Date unset", style: TextStyle(fontSize: 16),),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: WidgetUtils.skipNulls([
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 7.5,
                                              height: 7.5,
                                              decoration: const BoxDecoration(
                                                color: Colors.teal,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            WidgetUtils.spacer(5),
                                            Text("Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                          ],
                                        ),
                                        WidgetUtils.spacer(5),
                                      ]) ,
                                    )
                                )
                              ],
                            ),
                            WidgetUtils.spacer(10),
                            const Row(
                              children: [
                                // This part is supposed to be locations view
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height: 200,
                                  ),
                                ),
                                // This part is supposed to be participant list
                                Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 200,
                                    )
                                )
                              ],
                            ),
                            WidgetUtils.spacer(10),
                          ]
                      ),
                    ),
                  ),
                )
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainBody(ExerciseDiaryDataLoaded state) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: const Text("Edit Exercise Entry", style: TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, color: Colors.teal,), text: "Entry"),
                Tab(icon: Icon(Icons.info, color: Colors.teal,), text: "Info"),
                Tab(icon: Icon(Icons.fitness_center, color: Colors.teal,), text: "Muscles"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showDiaryEntryToEdit(state),
              _showExerciseInfo(state),
              _showExerciseMuscles(state),
            ],
          ),
        )
    );
  }

  _showSaveChangesButton(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          if (widget.isCurrentExerciseDefinitionCardio) {
            if (_mintuesPerformedTextController.value.text.isNotEmpty) {
              final durationInMins = int.parse(_mintuesPerformedTextController.value.text);
              SnackbarUtils.showSnackBarMedium(context, "Hold on... saving changes...");
              _exerciseDiaryBloc.add(
                  CardioExerciseDiaryEntryUpdated(
                    userId: widget.currentUserProfile.userId,
                    cardioDiaryEntryId: state.diaryEntry.left.id,
                    entry: CardioDiaryEntryUpdate(
                        cardioDate: selectedWorkoutDateTime,
                        durationInMinutes: durationInMins,
                        caloriesBurned: double.parse(_caloriesBurnedTextController.value.text),
                        meetupId: associatedMeetup?.id,
                    )
                  )
              );
            }
            else {
              SnackbarUtils.showSnackBar(context, "Please add minutes performed!");
            }
          }
          else {
            if (_setsTextController.value.text.isNotEmpty && _repsTextController.value.text.isNotEmpty) {
              final sets = int.parse(_setsTextController.value.text);
              final reps = int.parse(_repsTextController.value.text);
              _exerciseDiaryBloc.add(
                  StrengthExerciseDiaryEntryUpdated(
                      userId: widget.currentUserProfile.userId,
                      strengthDiaryEntryId: state.diaryEntry.right.id,
                      entry: StrengthDiaryEntryUpdate(
                        exerciseDate: selectedWorkoutDateTime,
                        sets: sets,
                        reps: reps,
                        weightsInLbs: state.diaryEntry.right.weightsInLbs,
                        caloriesBurned: double.parse(_caloriesBurnedTextController.value.text),
                        meetupId: associatedMeetup?.id,
                      )
                  )
              );
            }
            else {
              if (_setsTextController.value.text.isEmpty) {
                SnackbarUtils.showSnackBar(context, "Please add sets performed!");
              }
              else {
                SnackbarUtils.showSnackBar(context, "Please add reps performed!");
              }
            }
          }
        },
        child: const Text("Save changes", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  _showDiaryEntryToEdit(ExerciseDiaryDataLoaded state) {
    if (widget.isCurrentExerciseDefinitionCardio) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _showExerciseTitle(state),
            WidgetUtils.spacer(2.5),
            _displayExerciseImageIfAny(state),
            _generateDotsIfNeeded(state),
            WidgetUtils.spacer(2.5),
            _renderWorkoutDate(state),
            WidgetUtils.spacer(2.5),
            _renderWorkoutTime(state),
            WidgetUtils.spacer(2.5),
            _renderMinutesPerformed(state),
            WidgetUtils.spacer(2.5),
            _renderCaloriesBurned(),
            WidgetUtils.spacer(2.5),
            _renderAssociatedMeetupView(),
            WidgetUtils.spacer(5),
            _showSaveChangesButton(state),
          ]),
        ),
      );
    }
    else {
      // Needs weight per set
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _showExerciseTitle(state),
            WidgetUtils.spacer(5),
            _displayExerciseImageIfAny(state),
            _generateDotsIfNeeded(state),
            WidgetUtils.spacer(2.5),
            _renderWorkoutDate(state),
            WidgetUtils.spacer(2.5),
            _renderWorkoutTime(state),
            WidgetUtils.spacer(2.5),
            _renderSets(state),
            WidgetUtils.spacer(2.5),
            _renderReps(state),
            WidgetUtils.spacer(2.5),
            _renderCaloriesBurned(),
            WidgetUtils.spacer(2.5),
            _renderAssociatedMeetupView(),
            WidgetUtils.spacer(5),
            _showSaveChangesButton(state),
          ]),
        ),
      );
    }
  }

  _selectedMeetupIdAddedCallback(SelectedMeetupInfo info) {
    setState(() {
      associatedMeetup = info.associatedMeetup;
      associatedMeetupDecisions = info.associatedMeetupDecisions;
      associatedMeetupParticipants = info.associatedMeetupParticipants;
      associatedUserIdProfileMap = info.userIdProfileMap;
    });
  }

  _selectedMeetupIdRemovedCallback(SelectedMeetupInfo info) {
    setState(() {
      associatedMeetup = null;
      associatedMeetupDecisions = null;
      associatedMeetupParticipants = null;
      associatedUserIdProfileMap = null;
    });
  }

  _generateSelectFromMeetupsList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Meetup', style: TextStyle(color: Colors.teal),),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: SelectFromMeetupsList.withBloc(
        currentUserProfile: widget.currentUserProfile,
        selectedMeetupIdAddedCallback: _selectedMeetupIdAddedCallback,
        selectedMeetupIdRemovedCallback: _selectedMeetupIdRemovedCallback,
        previouslySelectedMeetupId: associatedMeetup?.id,
      ),
    );
  }


  _renderAssociatedMeetupView() {
    if (associatedMeetup != null && associatedMeetupParticipants != null
        && associatedMeetupDecisions != null && associatedUserIdProfileMap != null) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Expanded(
                flex: 5,
                child: Text(
                  "Associated meetup",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
            ),
            Expanded(
                flex: 8,
                child: Stack(
                  children: [
                    MeetupMiniCardView(
                      currentUserProfile: widget.currentUserProfile,
                      meetup: associatedMeetup!,
                      participants: associatedMeetupParticipants!,
                      decisions: associatedMeetupDecisions!,
                      userIdProfileMap: associatedUserIdProfileMap!,
                      onCardTapped: () {
                        showDialog(context: context, builder: (context) {
                          return Dialog(
                            child: _generateSelectFromMeetupsList(),
                          );
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            associatedMeetup = null;
                            associatedMeetupDecisions = null;
                            associatedMeetupParticipants = null;
                            associatedUserIdProfileMap = null;
                          });
                        },
                        child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.remove,
                              size: 10,
                              color: Colors.white,
                            )
                        ),
                      ),
                    ),
                  ],
                )
            ),
          ],
        ),
      );
    }
    else {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Expanded(
                flex: 5,
                child: Text(
                  "Associated meetup",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
            ),
            Expanded(
                flex: 8,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
                  ),
                  onPressed: () async {
                    showDialog(context: context, builder: (context) {
                      return Dialog(
                        child: _generateSelectFromMeetupsList(),
                      );
                    });
                  },
                  child: const Text(
                      "No meetup associated",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white
                      )
                  ),
                )
            ),
          ],
        ),
      );
    }

  }

  _showExerciseTitle(ExerciseDiaryDataLoaded state) {
    return Text(
      state.exerciseDefinition.name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.teal,
        fontSize: 20,
      ),
    );
  }

  _displayExerciseImageIfAny(ExerciseDiaryDataLoaded state) {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(state),
        options: CarouselOptions(
          height: 200,
          // aspectRatio: 3.0,
          viewportFraction: 0.825,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
          onPageChanged: (page, reason) {
            setState(() {
              _current = page;
            });
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _renderReps(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Reps per set",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: TextFormField(
                controller: _repsTextController,
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    final sets = _setsTextController.value.text.isEmpty ? 1 : int.parse(_setsTextController.value.text);
                    final reps = int.parse(text);
                    final burnedCalories =  ExerciseUtils.calculateCaloriesBurnedForNonCardioActivity(
                        widget.currentFitnessUserProfile,
                        state.exerciseDefinition.name,
                        sets,
                        reps
                    );
                    _caloriesBurnedTextController.text =
                        ExerciseUtils.calculateCaloriesBurnedForNonCardioActivity(
                            widget.currentFitnessUserProfile,
                            state.exerciseDefinition.name,
                            sets,
                            reps
                        ).toStringAsFixed(0);
                  }
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 3",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  _renderSets(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Sets",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: TextFormField(
                controller: _setsTextController,
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    final sets = int.parse(text);
                    final reps = _repsTextController.value.text.isEmpty ? 1 : int.parse(_repsTextController.value.text);
                    _caloriesBurnedTextController.text =
                        ExerciseUtils.calculateCaloriesBurnedForNonCardioActivity(
                            widget.currentFitnessUserProfile,
                            state.exerciseDefinition.name,
                            sets,
                            reps
                        ).toStringAsFixed(0);
                  }
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 3",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  _renderCaloriesBurned() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Calories burned",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: TextFormField(
                enabled: false,
                controller: _caloriesBurnedTextController,
                decoration: const InputDecoration(
                  hintText: "Auto calculated",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  _renderMinutesPerformed(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Minutes performed",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: TextFormField(
                controller: _mintuesPerformedTextController,
                onChanged: (text) {
                  final minutes = int.parse(text);
                  _caloriesBurnedTextController.text =
                      ExerciseUtils.calculateCaloriesBurnedForCardioActivity(
                        widget.currentFitnessUserProfile,
                        state.exerciseDefinition.name,
                        minutes,
                      ).toStringAsFixed(0);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 30",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  _renderWorkoutDate(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Date performed",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: _datePickerButton()
          ),
        ],
      ),
    );
  }

  _renderWorkoutTime(ExerciseDiaryDataLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(
              flex: 5,
              child: Text(
                "Start time",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
          ),
          Expanded(
              flex: 8,
              child: _timePickerButton()
          ),
        ],
      ),
    );
  }

  Widget _timePickerButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        final selectedTime = await showTimePicker(
          initialTime: TimeOfDay.fromDateTime(DateTime.now()),
          builder: (BuildContext context, Widget? child) {
            return Theme(
                data: ThemeData(primarySwatch: Colors.teal),
                child: child!
            );
          },
          context: context,
        );

        // Interact with bloc here
        if(selectedTime != null) {
          // Setstate and update here properly
          setState(() {
            selectedWorkoutDateTime = DateTime(
              selectedWorkoutDateTime.year,
              selectedWorkoutDateTime.month,
              selectedWorkoutDateTime.day,
              selectedTime.hour,
              selectedTime.minute,
            );
          });
        }

      },
      child: Text(
          DateFormat("hh:mm a").format(selectedWorkoutDateTime),
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

  Widget _datePickerButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
      ),
      onPressed: () async {
        final selectedDate = await showDatePicker(
          builder: (BuildContext context, Widget? child) {
            return Theme(
                data: ThemeData(primarySwatch: Colors.teal),
                child: child!
            );
          },
          context: context,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: selectedWorkoutDateTime,
          firstDate: DateTime(ConstantUtils.EARLIEST_YEAR),
          lastDate: DateTime(ConstantUtils.LATEST_YEAR),
        );

        // Interact
        if(selectedDate != null) {
          setState(() {
            selectedWorkoutDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedWorkoutDateTime.hour,
              selectedWorkoutDateTime.minute,
            );
          });
        }
      },
      child: Text(
          DateFormat('yyyy-MM-dd').format(selectedWorkoutDateTime),
          style: const TextStyle(
              fontSize: 16,
              color: Colors.white
          )),
    );
  }

  _generateCarouselOrStaticImage(ExerciseDiaryDataLoaded state) {
    if (state.exerciseDefinition.images.isNotEmpty) {
      return state.exerciseDefinition.images.map((e) =>
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.65,
              child: Image.network(e.image, fit: BoxFit.contain)
          )
      ).toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }

  _displayCarousel(ExerciseDiaryDataLoaded state) {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(state),
        options: CarouselOptions(
          height: 200,
          // aspectRatio: 3.0,
          viewportFraction: 0.825,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
          onPageChanged: (page, reason) {
            setState(() {
              _current = page;
            });
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _generateDotsIfNeeded(ExerciseDiaryDataLoaded state) {
    if (state.exerciseDefinition.images.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: state.exerciseDefinition.images.asMap().entries.map((entry) {
          return Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                    .withOpacity(_current == entry.key ? 0.9 : 0.4)),
          );
        }).toList(),
      );
    }
    return null;
  }

  _showExerciseInfo(ExerciseDiaryDataLoaded state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          WidgetUtils.spacer(5),
          _showExerciseTitle(state),
          WidgetUtils.spacer(5),
          _displayCarousel(state),
          _generateDotsIfNeeded(state),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Category",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(state.exerciseDefinition.category.name)
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Equipment",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(state.exerciseDefinition.equipment.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(state.exerciseDefinition.description)
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  _showExerciseMuscles(ExerciseDiaryDataLoaded state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          WidgetUtils.spacer(5),
          _showExerciseTitle(state),
          WidgetUtils.spacer(5),
          _displayCarousel(state),
          _generateDotsIfNeeded(state),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Primary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(state.exerciseDefinition.muscles.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          CarouselSlider(
            // carouselController: _carouselController,
              items: _generateMusclesCarousel(state),
              options: CarouselOptions(
                height: 100,
                // aspectRatio: 3.0,
                viewportFraction: 0.825,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (page, reason) {
                  setState(() {
                    // _current = page;
                  });
                },
                scrollDirection: Axis.horizontal,
              )
          ),
          // Secondary muscles
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Secondary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(state.exerciseDefinition.muscles_secondary.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          CarouselSlider(
            // carouselController: _carouselController,
              items: _generateSecondaryMusclesCarousel(state),
              options: CarouselOptions(
                height: 100,
                // aspectRatio: 3.0,
                viewportFraction: 0.825,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (page, reason) {
                  setState(() {
                    // _current = page;
                  });
                },
                scrollDirection: Axis.horizontal,
              )
          ),
        ]),
      ),
    );
  }

  _generateMusclesCarousel(ExerciseDiaryDataLoaded state) {
    if (state.exerciseDefinition.muscles.isNotEmpty) {
      return state.exerciseDefinition.muscles.map((e) =>
      [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: SvgPicture.network(
              "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
              fit: BoxFit.scaleDown,
              placeholderBuilder: (BuildContext context) => Container(
                  padding: const EdgeInsets.all(30.0),
                  child: const CircularProgressIndicator(color: Colors.yellow,)),
            )
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: SvgPicture.network(
              "${ConstantUtils.WGER_API_HOST}${e.image_url_secondary}",
              fit: BoxFit.scaleDown,
              placeholderBuilder: (BuildContext context) => Container(
                  child: const CircularProgressIndicator(color: Colors.teal,)),
            )
        )
      ]
      )
          .expand((element) => element)
          .toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }

  _generateSecondaryMusclesCarousel(ExerciseDiaryDataLoaded state) {
    if (state.exerciseDefinition.muscles_secondary.isNotEmpty) {
      return state.exerciseDefinition.muscles_secondary.map((e) {
        return [
          SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.65,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 200, minWidth: 200),
                child: SvgPicture.network(
                  "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
                  fit: BoxFit.scaleDown,
                  placeholderBuilder: (BuildContext context) => Container(
                      padding: const EdgeInsets.all(30.0),
                      child: const CircularProgressIndicator(color: Colors.yellow,)),
                ),
              )
          ),
          SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.65,
              child: SvgPicture.network(
                "${ConstantUtils.WGER_API_HOST}${e.image_url_secondary}",
                fit: BoxFit.scaleDown,
                placeholderBuilder: (BuildContext context) => Container(
                    padding: const EdgeInsets.all(30.0),
                    child: const CircularProgressIndicator(color: Colors.yellow,)),
              )
          )
        ];
      })
          .expand((element) => element)
          .toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }
}