import 'package:carousel_slider/carousel_slider.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_bloc.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_event.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class AddFoodToDiaryView extends StatefulWidget {

  static const String routeName = "food/search/add-to-diary";

  final PublicUserProfile currentUserProfile;
  final Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition;
  final String mealEntry;
  final DateTime selectedDayInQuestion;

  const AddFoodToDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.foodDefinition,
    required this.mealEntry,
    required this.selectedDayInQuestion,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      String mealEntry,
      DateTime selectedDayInQuestion,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => AddFoodToDiaryView.withBloc(
            currentUserProfile,
            foodDefinition,
            mealEntry,
            selectedDayInQuestion
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      String mealEntry,
      DateTime selectedDayInQuestion,
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
      mealEntry: mealEntry,
      selectedDayInQuestion: selectedDayInQuestion
    ),
  );


  @override
  State createState() {
    return AddFoodToDiaryViewState();
  }
}

class AddFoodToDiaryViewState extends State<AddFoodToDiaryView> {
  static const int MAX_TABS = 2;

  late AddFoodToDiaryBloc _addFoodToDiaryBloc;

  DateTime selectedWorkoutDateTime = DateTime.now();

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  final TextEditingController _servingsTextController = TextEditingController();

  List<Serving> servingOptions = [];
  Serving? selectedServingOption;
  double selectedServingSize = 1;

  @override
  void initState() {
    super.initState();

    _addFoodToDiaryBloc = BlocProvider.of<AddFoodToDiaryBloc>(context);

    servingOptions = widget.foodDefinition.isLeft ?
                      widget.foodDefinition.left.food.servings.serving :
                      [widget.foodDefinition.right.food.servings.serving];

    selectedServingOption = servingOptions.first;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomBarWithOptAd(),
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
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Expanded(
                      flex: 5,
                      child: Text(
                        "# of servings",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      )
                  ),
                  Expanded(
                      flex: 8,
                      child: TextFormField(
                        controller: _servingsTextController,
                        onChanged: (text) {
                          final servingSize = double.parse(text);
                          setState(() {
                            selectedServingSize = servingSize;
                          });
                        },
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: "Eg - 1.5",
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
            ),
            WidgetUtils.spacer(2.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Expanded(
                      flex: 5,
                      child: Text(
                        "Selected serving size",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      )
                  ),
                  Expanded(
                      flex: 8,
                      child: DropdownButton<String>(
                        value: selectedServingOption?.serving_description ?? "No serving size",
                        icon: const Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Icon(Icons.fastfood),
                        ),
                        elevation: 16,
                        style: const TextStyle(color: Colors.teal),
                        underline: Container(
                          height: 2,
                          // color: Colors.tealAccent,
                        ),
                        onChanged: (String? value) {
                          // This is called when the user selects an item.
                          setState(() {
                            selectedServingOption = servingOptions.firstWhere((element) => element.serving_description == value);
                          });
                        },
                        items: servingOptions.map((e) => e.serving_description).map<DropdownMenuItem<String>>((String? value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value ?? "No serving size"),
                          );
                        }).toList(),
                      )
                  ),
                ],
              ),
            )
            ,
            WidgetUtils.spacer(2.5),
            _infoItem("Serving Size", "${selectedServingOption?.metric_serving_amount} ${selectedServingOption?.metric_serving_unit}"),
            WidgetUtils.spacer(2.5),
            _infoItem("Calories", _stringOptToDouble(selectedServingOption?.calories)),
            WidgetUtils.spacer(2.5),
            _infoItem("Carbohydrates", _stringOptToDouble(selectedServingOption?.carbohydrate)),
            WidgetUtils.spacer(2.5),
            _infoItem("Fat", _stringOptToDouble(selectedServingOption?.fat)),
            WidgetUtils.spacer(2.5),
            _infoItem("Protein", _stringOptToDouble(selectedServingOption?.protein)),
            WidgetUtils.spacer(2.5),
            _infoItem("Calcium", _stringOptToDouble(selectedServingOption?.calcium)),
            WidgetUtils.spacer(2.5),
            _infoItem("Cholesterol", _stringOptToDouble(selectedServingOption?.cholesterol)),
            WidgetUtils.spacer(2.5),
            _infoItem("Fiber", _stringOptToDouble(selectedServingOption?.fiber)),
            WidgetUtils.spacer(2.5),
            _infoItem("Iron", _stringOptToDouble(selectedServingOption?.iron)),
            WidgetUtils.spacer(2.5),
            _infoItem("Monounsaturated Fat", _stringOptToDouble(selectedServingOption?.monounsaturated_fat)),
            WidgetUtils.spacer(2.5),
            _infoItem("Polyunsaturated Fat", _stringOptToDouble(selectedServingOption?.polyunsaturated_fat)),
            WidgetUtils.spacer(2.5),
            _infoItem("Potassium", _stringOptToDouble(selectedServingOption?.potassium)),
            WidgetUtils.spacer(2.5),
            _infoItem("Saturated Fat", _stringOptToDouble(selectedServingOption?.saturated_fat)),
            WidgetUtils.spacer(2.5),
            _infoItem("Sodium", _stringOptToDouble(selectedServingOption?.sodium)),
            WidgetUtils.spacer(2.5),
            _infoItem("Sugar", _stringOptToDouble(selectedServingOption?.sugar)),
            WidgetUtils.spacer(2.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Expanded(
                      flex: 5,
                      child: Text(
                        "Serving URL",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      )
                  ),
                  Expanded(
                      flex: 8,
                      child: RichText(
                          text: TextSpan(
                              children: [
                                TextSpan(
                                    text: "View in browser",
                                    style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.teal),
                                    recognizer: TapGestureRecognizer()..onTap = () {
                                      launchUrl(Uri.parse(selectedServingOption?.serving_url ?? ConstantUtils.FALLBACK_URL));
                                    }
                                ),
                              ]
                          )
                      )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _stringOptToDouble(String? value) {
    return (double.parse(value ?? "0") * selectedServingSize).toStringAsFixed(2);
  }

  _infoItem(String name, String? value) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              flex: 5,
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )
          ),
          Expanded(
              flex: 8,
              child: Text(value ?? "n/a")
          ),
        ],
      ),
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
          if (_servingsTextController.value.text.isNotEmpty) {
            if (widget.foodDefinition.isLeft) {
              _addFoodToDiaryBloc.add(
                  AddFoodEntryToDiary(
                    userId: widget.currentUserProfile.userId,
                    newEntry: FoodDiaryEntryCreate(
                        foodId: int.parse(widget.foodDefinition.left.food.food_id),
                        servingId: int.parse(selectedServingOption!.serving_id!),
                        numberOfServings: selectedServingSize,
                        mealEntry: widget.mealEntry,
                        entryDate: widget.selectedDayInQuestion
                    ),
                  )
              );
            }
            else {
              _addFoodToDiaryBloc.add(
                  AddFoodEntryToDiary(
                    userId: widget.currentUserProfile.userId,
                    newEntry: FoodDiaryEntryCreate(
                        foodId: int.parse(widget.foodDefinition.right.food.food_id),
                        servingId: int.parse(selectedServingOption!.serving_id!),
                        numberOfServings: selectedServingSize,
                        mealEntry: widget.mealEntry,
                        entryDate: widget.selectedDayInQuestion
                    ),
                  )
              );
            }
          }
          else {
            SnackbarUtils.showSnackBar(context, "Please add number of servings!");
          }
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

}