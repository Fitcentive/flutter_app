import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/exercise_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_bloc.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_event.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/bloc/add_exercise_to_diary_state.dart';
import 'package:flutter_app/src/views/shared_components/meetup_mini_card_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/select_from_meetups_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AddExerciseToDiaryView extends StatefulWidget {

  static const String routeName = "exercise/search/add-to-diary";

  final PublicUserProfile currentUserProfile;
  final FitnessUserProfile currentFitnessUserProfile;
  final ExerciseDefinition exerciseDefinition;
  final bool isCurrentExerciseDefinitionCardio;
  final DateTime selectedDayInQuestion;

  const AddExerciseToDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.currentFitnessUserProfile,
    required this.exerciseDefinition,
    required this.isCurrentExerciseDefinitionCardio,
    required this.selectedDayInQuestion,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => AddExerciseToDiaryView.withBloc(
            currentUserProfile,
            currentFitnessUserProfile,
            exerciseDefinition,
            isCurrentExerciseDefinitionCardio,
            selectedDayInQuestion
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion,
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<AddExerciseToDiaryBloc>(
          create: (context) => AddExerciseToDiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: AddExerciseToDiaryView(
      currentUserProfile: currentUserProfile,
      currentFitnessUserProfile: currentFitnessUserProfile,
      exerciseDefinition: exerciseDefinition,
      isCurrentExerciseDefinitionCardio: isCurrentExerciseDefinitionCardio,
      selectedDayInQuestion: selectedDayInQuestion
    ),
  );


  @override
  State createState() {
    return AddExerciseToDiaryViewState();
  }
}

class AddExerciseToDiaryViewState extends State<AddExerciseToDiaryView> {
  static const int MAX_TABS = 2;

  late AddExerciseToDiaryBloc _addExerciseToDiaryBloc;

  DateTime selectedWorkoutDateTime = DateTime.now();

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  final TextEditingController _mintuesPerformedTextController = TextEditingController();
  final TextEditingController _setsTextController = TextEditingController();
  final TextEditingController _repsTextController = TextEditingController();
  final TextEditingController _caloriesBurnedTextController = TextEditingController();

  Meetup? associatedMeetup;
  List<MeetupParticipant>? associatedMeetupParticipants;
  List<MeetupDecision>? associatedMeetupDecisions;
  Map<String, PublicUserProfile>? associatedUserIdProfileMap;

  @override
  void initState() {
    super.initState();

    _addExerciseToDiaryBloc = BlocProvider.of<AddExerciseToDiaryBloc>(context);
    selectedWorkoutDateTime = widget.selectedDayInQuestion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomBarWithOptAd(),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        toolbarHeight: 75,
        title: Text(widget.exerciseDefinition.name, style: const TextStyle(color: Colors.teal)),
      ),
      body: BlocListener<AddExerciseToDiaryBloc, AddExerciseToDiaryState>(
        listener: (context, state) {
          if (state is ExerciseDiaryEntryAdded) {
            Navigator.pop(context);
          }
        },
        child: _displayMainBody(),
      ),
    );
  }

  @override
  void dispose() {
    _mintuesPerformedTextController.dispose();
    _setsTextController.dispose();
    _repsTextController.dispose();
    _caloriesBurnedTextController.dispose();
    super.dispose();
  }

  _bottomBarWithOptAd() {
    final maxHeight = AdUtils.defaultBannerAdHeightForDetailedFoodAndExerciseView(context) * 2;
    final Widget? adWidget = WidgetUtils.showHomePageAdIfNeeded(context, maxHeight);
    if (adWidget == null) {
      return _bottomBarInternal();
    }
    else {
      return IntrinsicHeight(
        child: Column(
          children: [
            _bottomBarInternal(),
            adWidget,
          ],
        ),
      );
    }
  }

  _bottomBarInternal() {
    return IntrinsicHeight(
      child: Column(
        children: WidgetUtils.skipNulls([
          WidgetUtils.showUpgradeToMobileAppMessageIfNeeded(),
          BottomAppBar(
            color: Colors.transparent,
            child: _showAddToDiaryButton(),
            elevation: 0,
          ),
        ]),
      ),
    );
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

  _displayMainBody() {
    if (widget.isCurrentExerciseDefinitionCardio) {
      return Scrollbar(
        child: GestureDetector(
          onTap: () {
            KeyboardUtils.hideKeyboard(context);
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: WidgetUtils.skipNulls([
                WidgetUtils.spacer(2.5),
                _displayExerciseImageIfAny(),
                _generateDotsIfNeeded(),
                WidgetUtils.spacer(2.5),
                _renderWorkoutDate(),
                WidgetUtils.spacer(2.5),
                _renderWorkoutTime(),
                WidgetUtils.spacer(2.5),
                _renderMinutesPerformed(),
                WidgetUtils.spacer(2.5),
                _renderCaloriesBurned(),
                WidgetUtils.spacer(2.5),
                _renderAssociatedMeetupView(),
              ]),
            ),
          ),
        ),
      );
    }
    else {
      // Needs weight per set
      return Scrollbar(
        child: GestureDetector(
          onTap: () {
            KeyboardUtils.hideKeyboard(context);
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: WidgetUtils.skipNulls([
                WidgetUtils.spacer(2.5),
                _displayExerciseImageIfAny(),
                _generateDotsIfNeeded(),
                WidgetUtils.spacer(2.5),
                _renderWorkoutDate(),
                WidgetUtils.spacer(2.5),
                _renderWorkoutTime(),
                WidgetUtils.spacer(2.5),
                _renderSets(),
                WidgetUtils.spacer(2.5),
                _renderReps(),
                WidgetUtils.spacer(2.5),
                _renderCaloriesBurned(),
                WidgetUtils.spacer(2.5),
                _renderAssociatedMeetupView(),
              ]),
            ),
          ),
        ),
      );
    }
  }

  _renderReps() {
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
                        widget.exerciseDefinition.name,
                        sets,
                        reps
                    );
                    _caloriesBurnedTextController.text =
                        ExerciseUtils.calculateCaloriesBurnedForNonCardioActivity(
                            widget.currentFitnessUserProfile,
                            widget.exerciseDefinition.name,
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

  _renderSets() {
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
                            widget.exerciseDefinition.name,
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

  _renderMinutesPerformed() {
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                controller: _mintuesPerformedTextController,
                onChanged: (text) {
                  final minutes = int.parse(text);
                  _caloriesBurnedTextController.text =
                      ExerciseUtils.calculateCaloriesBurnedForCardioActivity(
                          widget.currentFitnessUserProfile,
                          widget.exerciseDefinition.name,
                          minutes,
                      ).toStringAsFixed(0);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 30",
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

  _renderWorkoutDate() {
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

  _renderWorkoutTime() {
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

  _displayExerciseImageIfAny() {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(),
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

  _generateDotsIfNeeded() {
    if (widget.exerciseDefinition.images.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.exerciseDefinition.images.asMap().entries.map((entry) {
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

  _generateCarouselOrStaticImage() {
    if (widget.exerciseDefinition.images.isNotEmpty) {
      return widget.exerciseDefinition.images.map((e) =>
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

  _showAddToDiaryButton() {
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
              _addExerciseToDiaryBloc.add(
                  AddCardioEntryToDiary(
                    userId: widget.currentUserProfile.userId,
                    associatedMeetupId: associatedMeetup?.id,
                    newEntry: CardioDiaryEntryCreate(
                        workoutId: widget.exerciseDefinition.uuid,
                        name: widget.exerciseDefinition.name,
                        cardioDate: selectedWorkoutDateTime,
                        durationInMinutes: durationInMins,
                        caloriesBurned: double.parse(_caloriesBurnedTextController.value.text),
                        meetupId: associatedMeetup?.id,
                    ),
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
              _addExerciseToDiaryBloc.add(
                  AddStrengthEntryToDiary(
                    userId: widget.currentUserProfile.userId,
                    associatedMeetupId: associatedMeetup?.id,
                    newEntry: StrengthDiaryEntryCreate(
                      workoutId: widget.exerciseDefinition.uuid,
                      name: widget.exerciseDefinition.name,
                      exerciseDate: selectedWorkoutDateTime,
                      sets: sets,
                      reps: reps,
                      caloriesBurned: double.parse(_caloriesBurnedTextController.value.text),
                      weightsInLbs: const [], // todo - update this
                      meetupId: associatedMeetup?.id,
                    ),
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
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

}