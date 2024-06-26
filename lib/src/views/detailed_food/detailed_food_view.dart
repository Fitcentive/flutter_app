import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_food_to_diary/add_food_to_diary_view.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_bloc.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_event.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailedFoodView extends StatefulWidget {

  static const String routeName = "food/view";

  final PublicUserProfile currentUserProfile;
  final FoodSearchResult foodSearchResult;
  final String mealEntry;
  final DateTime selectedDayInQuestion;

  const DetailedFoodView({
    Key? key,
    required this.currentUserProfile,
    required this.foodSearchResult,
    required this.mealEntry,
    required this.selectedDayInQuestion,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FoodSearchResult foodSearchResult,
      String mealEntry,
      DateTime selectedDayInQuestion
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => DetailedFoodView.withBloc(
            currentUserProfile,
            foodSearchResult,
            mealEntry,
            selectedDayInQuestion,
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FoodSearchResult foodSearchResult,
      String mealEntry,
      DateTime selectedDayInQuestion,
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<DetailedFoodBloc>(
          create: (context) => DetailedFoodBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: DetailedFoodView(
      currentUserProfile: currentUserProfile,
      foodSearchResult: foodSearchResult,
      mealEntry: mealEntry,
      selectedDayInQuestion: selectedDayInQuestion
    ),
  );


  @override
  State createState() {
    return DetailedFoodViewState();
  }
}

class DetailedFoodViewState extends State<DetailedFoodView> with SingleTickerProviderStateMixin {
  // static const int MAX_TABS = 2;
  static const int MAX_TABS = 1;
  late final TabController _tabController;

  late DetailedFoodBloc _detailedFoodBloc;

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  final ScrollController _scrollController = ScrollController();

  List<Serving> servingOptions = [];
  Serving? selectedServingOption;


  @override
  void initState() {
    super.initState();

    _detailedFoodBloc = BlocProvider.of<DetailedFoodBloc>(context);
    _tabController = TabController(vsync: this, length: MAX_TABS);

    _detailedFoodBloc.add(
        FetchDetailedFoodInfo(
            foodId: widget.foodSearchResult.food_id,
            currentUserId: widget.currentUserProfile.userId
        )
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  _bottomBarWithOptAd(DetailedFoodState state) {
    final maxHeight = AdUtils.defaultBannerAdHeightForDetailedFoodAndExerciseView(context) * 2;
    final Widget? adWidget = WidgetUtils.showHomePageAdIfNeeded(context, maxHeight);
    if (adWidget == null) {
      return _bottomBarInternal(state);
    }
    else {
      return IntrinsicHeight(
        child: Column(
          children: [
            _bottomBarInternal(state),
            adWidget,
          ],
        ),
      );
    }
  }

  _bottomBarInternal(DetailedFoodState state) {
    return IntrinsicHeight(
      child: Column(
        children: WidgetUtils.skipNulls([
          WidgetUtils.showUpgradeToMobileAppMessageIfNeeded(),
          BottomAppBar(
            color: Colors.transparent,
            child: _showAddToFoodDiaryButton(state),
            elevation: 0,
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailedFoodBloc, DetailedFoodState>(
        builder: (context, state) {
          return DefaultTabController(
              length: MAX_TABS,
              child: Scaffold(
                bottomNavigationBar: _bottomBarWithOptAd(state),
                appBar: AppBar(
                  iconTheme: const IconThemeData(
                    color: Colors.teal,
                  ),
                  toolbarHeight: 75,
                  title: Text(widget.foodSearchResult.food_name, style: const TextStyle(color: Colors.teal)),
                  bottom: TabBar(
                    labelColor: Colors.teal,
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.bar_chart, color: Colors.teal,), text: "Nutrition"),
                      // Tab(icon: Icon(Icons.info, color: Colors.teal,), text: "Fatsecret"),
                    ],
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _showFoodInfo(state),
                  ],
                ),
              )
          );
        },
    );
  }

  _showAddToFoodDiaryButton(DetailedFoodState state) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          if (state is DetailedFoodDataFetched) {
            Navigator.push(
              context,
              AddFoodToDiaryView.route(
                  widget.currentUserProfile,
                  state.result,
                  widget.mealEntry,
                  widget.selectedDayInQuestion,
                  selectedServingOption,
              ),
            );
          }
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  _showFoodInfo(DetailedFoodState state) {
    return BlocListener<DetailedFoodBloc, DetailedFoodState>(
      listener: (context, state) {
        if (state is DetailedFoodDataFetched) {
          if (state.result.isLeft) {
            servingOptions = state.result.left.food.servings.serving;
            selectedServingOption = servingOptions.first;
          }
          else {
            // In this case, it is a single serving
            servingOptions = [state.result.right.food.servings.serving];
            selectedServingOption = servingOptions.first;
          }
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(5),
            _infoItem("Name", widget.foodSearchResult.food_name),
            WidgetUtils.spacer(2.5),
            _infoItem("Category", widget.foodSearchResult.food_type),
            WidgetUtils.spacer(2.5),
            _infoItem("Description", widget.foodSearchResult.food_description),
            WidgetUtils.spacer(2.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Expanded(
                      flex: 5,
                      child: Text(
                        "Link",
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
                                      launchUrl(Uri.parse(widget.foodSearchResult.food_url));
                                    }
                                ),
                              ]
                          )
                      )
                  ),
                ],
              ),
            ),
            WidgetUtils.spacer(2.5),
            _showDetailedFoodInfo(state),
          ]),
        ),
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

  _showDetailedFoodInfo(DetailedFoodState state) {
    if (state is DetailedFoodDataFetched) {
      return Column(
        children: WidgetUtils.skipNulls([
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
          _infoItem("Calories", selectedServingOption?.calories),
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
      );
    }
    else {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      );
    }
  }

  _stringOptToDouble(String? value) {
    return (double.parse(value ?? "0")).toStringAsFixed(2);
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