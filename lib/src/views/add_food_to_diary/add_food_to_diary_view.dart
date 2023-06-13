import 'dart:math';

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
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_bloc.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_event.dart';
import 'package:flutter_app/src/views/add_food_to_diary/bloc/add_food_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class AddFoodToDiaryView extends StatefulWidget {

  static const String routeName = "food/search/add-to-diary";

  final PublicUserProfile currentUserProfile;
  final Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition;
  final String mealEntry;
  final DateTime selectedDayInQuestion;
  final Serving? selectedServingOption;

  const AddFoodToDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.foodDefinition,
    required this.mealEntry,
    required this.selectedDayInQuestion,
    required this.selectedServingOption,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      String mealEntry,
      DateTime selectedDayInQuestion,
      Serving? selectedServingOption,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => AddFoodToDiaryView.withBloc(
            currentUserProfile,
            foodDefinition,
            mealEntry,
            selectedDayInQuestion,
            selectedServingOption,
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      Either<FoodGetResult, FoodGetResultSingleServing> foodDefinition,
      String mealEntry,
      DateTime selectedDayInQuestion,
      Serving? selectedServingOption,
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
      selectedDayInQuestion: selectedDayInQuestion,
      selectedServingOption: selectedServingOption,
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

    selectedServingOption = widget.selectedServingOption ?? servingOptions.first;
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

  @override
  void dispose() {
    _servingsTextController.dispose();
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

  _showMacrosPieChartIfPossible(String? carbs, String? fats, String? protein) {
    if (carbs != null && fats != null && protein != null) {
      Map<String, double> dataMap = {
        "Carbohydrates": double.parse(carbs),
        "Fats": double.parse(fats),
        "Proteins": double.parse(protein),
      };
      final colorList = <Color>[
        Colors.blue,
        Colors.red,
        Colors.green,
      ];
      return SizedBox(
        height: 200,
        width: min(ConstantUtils.WEB_APP_MAX_WIDTH, ScreenUtils.getScreenWidth(context)),
        child: PieChart(
          dataMap: dataMap,
          animationDuration: const Duration(milliseconds: 800),
          chartLegendSpacing: 32,
          chartRadius: min(ConstantUtils.WEB_APP_MAX_WIDTH, ScreenUtils.getScreenWidth(context)) / 3.2,
          colorList: colorList,
          initialAngleInDegree: 0,
          chartType: ChartType.disc,
          // ringStrokeWidth: 32,
          // centerText: "HYBRID",
          legendOptions: const LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          chartValuesOptions: const ChartValuesOptions(
            showChartValueBackground: true,
            showChartValues: true,
            showChartValuesInPercentage: true,
            showChartValuesOutside: false,
            decimalPlaces: 1,
            chartValueStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )
          ),
          // gradientList: ---To add gradient colors---
          // emptyColorGradient: ---Empty Color gradient---
        ),
      );
    }
  }

  _displayMainBody() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: WidgetUtils.skipNulls([
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
                        isExpanded: true,
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
            ),
            WidgetUtils.spacer(2.5),
            _infoItem("Serving Size", "${selectedServingOption?.metric_serving_amount ?? ""} ${selectedServingOption?.metric_serving_unit ?? ""}"),
            WidgetUtils.spacer(2.5),
            _infoItem("Calories", _stringOptToDouble(selectedServingOption?.calories)),
            _showMacrosPieChartIfPossible(selectedServingOption?.carbohydrate, selectedServingOption?.fat, selectedServingOption?.protein),
            _infoItem("Carbohydrates", "${_stringOptToDouble(selectedServingOption?.carbohydrate)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Fat", "${_stringOptToDouble(selectedServingOption?.fat)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Protein", "${_stringOptToDouble(selectedServingOption?.protein)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Calcium", "${_stringOptToDouble(selectedServingOption?.calcium)} mg"),
            WidgetUtils.spacer(2.5),
            _infoItem("Cholesterol", "${_stringOptToDouble(selectedServingOption?.cholesterol)} mg"),
            WidgetUtils.spacer(2.5),
            _infoItem("Fiber", "${_stringOptToDouble(selectedServingOption?.fiber)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Iron", "${_stringOptToDouble(selectedServingOption?.iron)} mg"),
            WidgetUtils.spacer(2.5),
            _infoItem("Monounsaturated Fat", "${_stringOptToDouble(selectedServingOption?.monounsaturated_fat)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Polyunsaturated Fat", "${_stringOptToDouble(selectedServingOption?.polyunsaturated_fat)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Potassium", "${_stringOptToDouble(selectedServingOption?.potassium)} mg"),
            WidgetUtils.spacer(2.5),
            _infoItem("Saturated Fat", "${_stringOptToDouble(selectedServingOption?.saturated_fat)} g"),
            WidgetUtils.spacer(2.5),
            _infoItem("Sodium", "${_stringOptToDouble(selectedServingOption?.sodium)} mg"),
            WidgetUtils.spacer(2.5),
            _infoItem("Sugar", "${_stringOptToDouble(selectedServingOption?.sugar)} g"),
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
          ]),
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