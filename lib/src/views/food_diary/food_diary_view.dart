import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/cardio_diary_entry.dart';
import 'package:flutter_app/src/models/diary/food_diary_entry.dart';
import 'package:flutter_app/src/models/diary/strength_diary_entry.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_event.dart';
import 'package:flutter_app/src/views/exercise_diary/bloc/exercise_diary_state.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_bloc.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_event.dart';
import 'package:flutter_app/src/views/food_diary/bloc/food_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodDiaryView extends StatefulWidget {

  static const String routeName = "diary/view-food";

  final PublicUserProfile currentUserProfile;
  final int foodId;
  final String diaryEntryId;
  final String mealOfDay;
  final DateTime selectedDayInQuestion;

  const FoodDiaryView({
    Key? key,
    required this.currentUserProfile,
    required this.foodId,
    required this.diaryEntryId,
    required this.selectedDayInQuestion,
    required this.mealOfDay,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      int foodId,
      String diaryEntryId,
      DateTime selectedDayInQuestion,
      String mealOfDay
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => FoodDiaryView.withBloc(
            currentUserProfile,
            foodId,
            diaryEntryId,
            selectedDayInQuestion,
            mealOfDay
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      int foodId,
      String diaryEntryId,
      DateTime selectedDayInQuestion,
      String mealOfDay,
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<FoodDiaryBloc>(
          create: (context) => FoodDiaryBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: FoodDiaryView(
      currentUserProfile: currentUserProfile,
      foodId: foodId,
      selectedDayInQuestion: selectedDayInQuestion,
      diaryEntryId: diaryEntryId,
      mealOfDay: mealOfDay
    ),
  );



  @override
  State<StatefulWidget> createState() {
    return FoodDiaryViewState();
  }

}

class FoodDiaryViewState extends State<FoodDiaryView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 1;

  late FoodDiaryBloc _foodDiaryBloc;
  late final TabController _tabController;

  final TextEditingController _servingsTextController = TextEditingController();

  List<Serving> servingOptions = [];
  Serving? selectedServingOption;
  double selectedServingSize = 1;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: MAX_TABS);

    _foodDiaryBloc = BlocProvider.of<FoodDiaryBloc>(context);
    _foodDiaryBloc.add(FetchFoodDiaryEntryInfo(
      userId: widget.currentUserProfile.userId,
      diaryEntryId: widget.diaryEntryId,
      foodId: widget.foodId,
    ));
  }

  @override
  void dispose() {
    _servingsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      body: BlocListener<FoodDiaryBloc, FoodDiaryState>(
        listener: (context, state) {
          if (state is FoodEntryUpdatedAndReadyToPop) {
            SnackbarUtils.showSnackBarMedium(context, "Diary entry updated successfully!");
            Navigator.pop(context);
          }
          else if (state is FoodDiaryDataLoaded) {
            setState(() {
              selectedServingSize = state.diaryEntry.numberOfServings;
              servingOptions = state.foodDefinition.isLeft ?
                  state.foodDefinition.left.food.servings.serving :
                  [state.foodDefinition.right.food.servings.serving];

              if (state.foodDefinition.isLeft) {
                servingOptions = state.foodDefinition.left.food.servings.serving;
                selectedServingOption = servingOptions
                    .firstWhere(
                        (element) => element.serving_id == state.diaryEntry.servingId.toString(),
                        orElse: () => servingOptions.first
                );
              }
              else {
                // In this case, it is a single serving
                servingOptions = [state.foodDefinition.right.food.servings.serving];
                selectedServingOption = servingOptions
                    .firstWhere(
                        (element) => element.serving_id == state.diaryEntry.servingId.toString(),
                    orElse: () => servingOptions.first
                );
              }

              _servingsTextController.text = selectedServingSize.toStringAsFixed(2);
            });
          }
        },
        child: BlocBuilder<FoodDiaryBloc, FoodDiaryState>(
          builder: (context, state) {
            if (state is FoodDiaryDataLoaded) {
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

  Widget _mainBody(FoodDiaryDataLoaded state) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.save,
                  color: Colors.teal,
                ),
                onPressed: () {
                  _saveDiaryEntryButtonPressed(state);
                },
              )
            ],
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: Text("Edit ${widget.mealOfDay} Entry", style: const TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, color: Colors.teal,), text: "Entry"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showDiaryEntryToEdit(state),
            ],
          ),
        )
    );
  }


  _saveDiaryEntryButtonPressed(FoodDiaryDataLoaded state) {
    if (_servingsTextController.value.text.isNotEmpty) {
      _foodDiaryBloc.add(
          FoodDiaryEntryUpdated(
              userId: widget.currentUserProfile.userId,
              foodDiaryEntryId: widget.diaryEntryId,
              entry: FoodDiaryEntryUpdate(
                servingId: int.parse(selectedServingOption!.serving_id!),
                numberOfServings: selectedServingSize,
                entryDate: state.diaryEntry.entryDate,
              )
          )
      );
    }
    else {
      SnackbarUtils.showSnackBarMedium(context, "Please add number of servings!");
    }

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
        height: 400,
        width: 400,
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
          ),
          // gradientList: ---To add gradient colors---
          // emptyColorGradient: ---Empty Color gradient---
        ),
      );
    }
  }

  _renderFoodTitle(FoodDiaryDataLoaded state) {
    return Text(
      state.foodDefinition.isLeft ? state.foodDefinition.left.food.food_name : state.foodDefinition.right.food.food_name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.teal,
        fontSize: 20,
      ),
    );
  }

  _showDiaryEntryToEdit(FoodDiaryDataLoaded state) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _renderFoodTitle(state),
            WidgetUtils.spacer(2.5),
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

}