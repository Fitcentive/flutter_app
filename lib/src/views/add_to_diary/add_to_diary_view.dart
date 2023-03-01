import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/datetime_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_to_diary/bloc/add_to_diary_bloc.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class AddToDiaryView extends StatefulWidget {

  static const String routeName = "exercise/search/add-to-diary";

  final PublicUserProfile currentUserProfile;
  final ExerciseDefinition exerciseDefinition;
  final bool isCurrentExerciseDefinitionCardio;

  const AddToDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.exerciseDefinition,
    required this.isCurrentExerciseDefinitionCardio
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => AddToDiaryView.withBloc(
            currentUserProfile,
            exerciseDefinition,
            isCurrentExerciseDefinitionCardio
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<AddToDiaryBloc>(
          create: (context) => AddToDiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: AddToDiaryView(
      currentUserProfile: currentUserProfile,
      exerciseDefinition: exerciseDefinition,
      isCurrentExerciseDefinitionCardio: isCurrentExerciseDefinitionCardio,
    ),
  );


  @override
  State createState() {
    return AddToDiaryViewState();
  }
}

class AddToDiaryViewState extends State<AddToDiaryView> {
  static const int MAX_TABS = 2;

  late AddToDiaryBloc _addToDiaryBloc;

  DateTime selectedWorkoutDateTime = DateTime.now();

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();

    _addToDiaryBloc = BlocProvider.of<AddToDiaryBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: _showAddToDiaryButton(),
        elevation: 0,
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
        toolbarHeight: 75,
        title: Text(widget.exerciseDefinition.name, style: const TextStyle(color: Colors.teal)),
      ),
      body: _displayMainBody(),
    );
  }

  _displayMainBody() {
    if (widget.isCurrentExerciseDefinitionCardio) {
      return Column(
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
        ]),
      );
    }
    else {
      // Needs weight per set
      return Center(
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
            WidgetUtils.spacer(1),
            _renderReps(),
          ]),
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 3",
                  hintStyle: TextStyle(color: Colors.teal),
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Eg - 3",
                  hintStyle: TextStyle(color: Colors.teal),
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
                decoration: const InputDecoration(
                  hintText: "Eg - 30",
                  hintStyle: TextStyle(color: Colors.teal),
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
          // todo - add to diary, perform validation to ensure required fields are added before diary
          // Need to update BLOC events andf state
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

}