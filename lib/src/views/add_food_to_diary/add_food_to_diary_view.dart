import 'package:carousel_slider/carousel_slider.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_bloc.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AddFoodToDiaryView extends StatefulWidget {

  static const String routeName = "food/search/add-to-diary";

  final PublicUserProfile currentUserProfile;
  final Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition;

  const AddFoodToDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.foodDefinition,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => AddFoodToDiaryView.withBloc(
            currentUserProfile,
            foodDefinition,
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<AddFoodToDiaryBloc>(
          create: (context) => AddFoodToDiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: AddFoodToDiaryView(
      currentUserProfile: currentUserProfile,
      foodDefinition: foodDefinition,
    ),
  );


  @override
  State createState() {
    return AddFoodToDiaryViewState();
  }
}

// todo - work on this, lots to do here
class AddFoodToDiaryViewState extends State<AddFoodToDiaryView> {
  static const int MAX_TABS = 2;

  late AddFoodToDiaryBloc _addFoodToDiaryBloc;

  DateTime selectedWorkoutDateTime = DateTime.now();

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  final TextEditingController _mintuesPerformedTextController = TextEditingController();
  final TextEditingController _setsTextController = TextEditingController();
  final TextEditingController _repsTextController = TextEditingController();
  final TextEditingController _caloriesBurnedTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _addFoodToDiaryBloc = BlocProvider.of<AddFoodToDiaryBloc>(context);
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
        title: Text(
            widget.foodDefinition.isLeft ? widget.foodDefinition.left.food.food_name : widget.foodDefinition.right.food.food_name,
            style: const TextStyle(color: Colors.teal)
        ),
      ),
      body: BlocListener<AddFoodToDiaryBloc, AddFoodToDiaryState>(
        listener: (context, state) {
          if (state is FoodDiaryEntryAdded) {
            var count = 0;
            Navigator.popUntil(context, (route) => count++ == 3);
          }
        },
        child: _displayMainBody(),
      ),
    );
  }

  _displayMainBody() {
    return Text("yet to come...");
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
                  final sets = _setsTextController.value.text.isEmpty ? 1 : int.parse(_setsTextController.value.text);;
                  final reps = int.parse(text);
                  _caloriesBurnedTextController.text = (sets * reps * 10).toString(); // todo - change this!
                },
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
                controller: _setsTextController,
                onChanged: (text) {
                  final sets = int.parse(text);
                  final reps = _repsTextController.value.text.isEmpty ? 1 : int.parse(_repsTextController.value.text);
                  _caloriesBurnedTextController.text = (sets * reps * 10).toString(); // todo - change this!
                },
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
          // todo - add onPressed
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

}