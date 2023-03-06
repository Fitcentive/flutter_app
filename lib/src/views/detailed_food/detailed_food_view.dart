import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DetailedFoodView extends StatefulWidget {

  static const String routeName = "food/view";

  final PublicUserProfile currentUserProfile;
  final FoodSearchResult foodSearchResult;

  const DetailedFoodView({
    Key? key,
    required this.currentUserProfile,
    required this.foodSearchResult,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FoodSearchResult foodSearchResult,
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => DetailedFoodView.withBloc(
            currentUserProfile,
            foodSearchResult,
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FoodSearchResult foodSearchResult,
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

  WebViewController controller = WebViewController();


  @override
  void initState() {
    super.initState();

    _detailedFoodBloc = BlocProvider.of<DetailedFoodBloc>(context);
    _tabController = TabController(vsync: this, length: MAX_TABS);

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            child: _showAddToFoodDiaryButton(),
            elevation: 0,
          ),
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
              _showFoodInfo(),
              _showNutritionInfo(),
            ],
          ),
        )
    );
  }

  _showAddToFoodDiaryButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          // todo
          // Navigator.push(
          //     context,
          //     AddExerciseToDiaryView.route(widget.currentUserProfile, widget.exerciseDefinition, widget.isCurrentExerciseDefinitionCardio),
          // );
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  _showNutritionInfo() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: ScreenUtils.getScreenHeight(context) * .8
            ),
            child: WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(const Color(0x00000000))
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onProgress: (int progress) {
                      // Update loading bar.
                    },
                    onPageStarted: (String url) {},
                    onPageFinished: (String url) {},
                    onWebResourceError: (WebResourceError error) {},
                    onNavigationRequest: (NavigationRequest request) {
                      // if (request.url.startsWith('https://www.youtube.com/')) {
                      //   return NavigationDecision.prevent;
                      // }
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(widget.foodSearchResult.food_url)),
            ),
          ),
        ],
      ),
    );
  }

  _showFoodInfo() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          WidgetUtils.spacer(5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Name",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.foodSearchResult.food_name)
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
                      "Category",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.foodSearchResult.food_type)
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
                    child: Text(widget.foodSearchResult.food_description)
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
          )
        ]),
      ),
    );
  }

}