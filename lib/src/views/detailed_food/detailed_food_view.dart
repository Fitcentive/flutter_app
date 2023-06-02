import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:flutter_app/src/models/fatsecret/serving.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_food_to_diary/add_food_to_diary_view.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_bloc.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_event.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  _showDetailedFoodInfo(DetailedFoodState state) {
    if (state is DetailedFoodDataFetched) {
      return Column(
        children: [
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
          _infoItem("Calories", selectedServingOption?.calories),
          WidgetUtils.spacer(2.5),
          _infoItem("Carbohydrates", selectedServingOption?.carbohydrate),
          WidgetUtils.spacer(2.5),
          _infoItem("Fat", selectedServingOption?.fat),
          WidgetUtils.spacer(2.5),
          _infoItem("Protein", selectedServingOption?.protein),
          WidgetUtils.spacer(2.5),
          _infoItem("Calcium", selectedServingOption?.calcium),
          WidgetUtils.spacer(2.5),
          _infoItem("Cholesterol", selectedServingOption?.cholesterol),
          WidgetUtils.spacer(2.5),
          _infoItem("Fiber", selectedServingOption?.fiber),
          WidgetUtils.spacer(2.5),
          _infoItem("Iron", selectedServingOption?.iron),
          WidgetUtils.spacer(2.5),
          _infoItem("Monounsaturated Fat", selectedServingOption?.monounsaturated_fat),
          WidgetUtils.spacer(2.5),
          _infoItem("Polyunsaturated Fat", selectedServingOption?.polyunsaturated_fat),
          WidgetUtils.spacer(2.5),
          _infoItem("Potassium", selectedServingOption?.potassium),
          WidgetUtils.spacer(2.5),
          _infoItem("Saturated Fat", selectedServingOption?.saturated_fat),
          WidgetUtils.spacer(2.5),
          _infoItem("Sodium", selectedServingOption?.sodium),
          WidgetUtils.spacer(2.5),
          _infoItem("Sugar", selectedServingOption?.sugar),
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