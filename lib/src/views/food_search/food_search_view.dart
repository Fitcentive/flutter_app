import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_food/detailed_food_view.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_bloc.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_event.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodSearchView extends StatefulWidget {
  static const String routeName = "food/search";

  final PublicUserProfile currentUserProfile;
  final String mealOfDay; // One of Breakfast, Lunch, Dinner, or Snack
  final DateTime selectedDayInQuestion; // The day for which a potential diary entry might be added

  const FoodSearchView({
    Key? key,
    required this.currentUserProfile,
    required this.mealOfDay,
    required this.selectedDayInQuestion,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      String mealOfDay,
      DateTime selectedDayInQuestion,
  ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => FoodSearchView.withBloc(currentUserProfile, mealOfDay, selectedDayInQuestion)
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      String mealOfDay,
      DateTime selectedDayInQuestion
  ) => MultiBlocProvider(
    providers: [
      BlocProvider<FoodSearchBloc>(
          create: (context) => FoodSearchBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            userRepository: RepositoryProvider.of<UserRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: FoodSearchView(
        currentUserProfile: currentUserProfile,
        mealOfDay: mealOfDay,
        selectedDayInQuestion: selectedDayInQuestion
    ),
  );


  @override
  State createState() {
    return FoodSearchViewState();
  }
}

class FoodSearchViewState extends State<FoodSearchView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 1;
  static const double _scrollThreshold = 400.0;

  late FoodSearchBloc _foodSearchBloc;

  late final TabController _tabController;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  Timer? _searchQueryDebounceTimer;
  Timer? _scrollControllerDebounceTimer;
  final _scrollController = ScrollController();

  late final DiaryRepository _diaryRepository;
  late final FlutterSecureStorage _flutterSecureStorage;

  bool showOnlyRecent = true;

  bool shouldShow = false;
  bool shouldHideKeyboardManually = true;

  @override
  void dispose() {
    _searchTextController.dispose();
    _scrollController.dispose();
    _searchQueryDebounceTimer?.cancel();
    _scrollControllerDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: MAX_TABS);

    _diaryRepository = RepositoryProvider.of<DiaryRepository>(context);
    _flutterSecureStorage = RepositoryProvider.of<FlutterSecureStorage>(context);
    _foodSearchBloc = BlocProvider.of<FoodSearchBloc>(context);
    _foodSearchBloc.add(
        FetchRecentFoodSearchInfo(
          currentUserId: widget.currentUserProfile.userId
        )
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    if (shouldHideKeyboardManually) {
      KeyboardUtils.hideKeyboard(context);
    }
    final maxHeight = AdUtils.defaultBannerAdHeight(context);
    final Widget? adWidget = WidgetUtils.showAdIfNeeded(context, maxHeight);
    return Scaffold(
      bottomNavigationBar: WidgetUtils.wrapAdWidgetWithUpgradeToMobileTextIfNeeded(adWidget, maxHeight),
      body: BlocListener<FoodSearchBloc, FoodSearchState>(
        listener: (context, state) {
          if (state is FoodDataFetched) {
            setState(() {
              // set state here
            });
          }
        },
        child: BlocBuilder<FoodSearchBloc, FoodSearchState>(
          builder: (context, state) {
            return _mainBody(state);
          },
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollControllerDebounceTimer?.isActive ?? false) _scrollControllerDebounceTimer?.cancel();
    _scrollControllerDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if(_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (maxScroll - currentScroll <= _scrollThreshold) {
          final currentState = _foodSearchBloc.state;
          if (currentState is FoodDataFetched) {
            _foodSearchBloc.add(
                FetchFoodSearchInfo(
                  currentUserId: widget.currentUserProfile.userId,
                  query: currentState.query,
                  pageNumber: currentState.suppliedPageNumber + 1,
                  maxResults: DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
                )
            );
          }
        }
      }
    });
  }

  Widget _mainBody(FoodSearchState state) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: Text("View ${widget.mealOfDay} Foods", style: const TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: [
                Tab(
                    icon: Icon(showOnlyRecent ? Icons.timelapse : Icons.dinner_dining,
                    color: Colors.teal,), text: showOnlyRecent ? "Recent Foods" : "All Foods"
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showFoodList(state),
            ],
          ),
        )
    );
  }

  _renderFatsecretAttribution() {
    return Center(
      child: RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Powered by Fatsecret",
                    style: Theme.of(context).textTheme.subtitle2?.copyWith(color: Colors.teal),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      launchUrl(Uri.parse(ConstantUtils.FATSECRET_ATTRIBUTION_URL));
                    }
                ),
              ]
          )
      ),
    );
  }

  _showFoodList(FoodSearchState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetUtils.spacer(5),
        _renderFatsecretAttribution(),
        WidgetUtils.spacer(5),
        _foodSearchBar(),
        WidgetUtils.spacer(2.5),
        ..._renderResultsOrProgressIndicator(state)
      ],
    );
  }

  _skeletonLoadingView() {
    return [Expanded(
      child: SingleChildScrollView(
        child: SkeletonLoader(
          builder: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Container(
                  width: 50,
                  height: 10,
                  color: Colors.white,
                ),
                trailing: Container(
                  width: 20,
                  height: 10,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    )];
  }

  List<Widget> _renderResultsOrProgressIndicator(FoodSearchState state) {
    if (state is FoodSearchStateInitial) {
      return _skeletonLoadingView();
      return [
        const ListTile(
          title: Text("Total Foods", style: TextStyle(color: Colors.teal)),
          trailing: Text("0", style: TextStyle(color: Colors.teal)),
        ),
        Expanded(
            child: _searchResults([], null)
        )
      ];
    }
    else if (state is FoodDataFetched) {
      return [
        ListTile(
          title: const Text("Total Foods", style: TextStyle(color: Colors.teal)),
          trailing: Text(showOnlyRecent ? state.recentFoods.length.toString() : state.results.foods.food.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(
            child: showOnlyRecent ? _recentFoodSearchResults(state.recentFoods) : _searchResults(state.results.foods.food, state)
        )
      ];
    }
    else if (state is OnlyRecentFoodDataFetched) {
      if (showOnlyRecent) {
        return [
          ListTile(
            title: const Text("Total Foods", style: TextStyle(color: Colors.teal)),
            trailing: Text(state.recentFoods.length.toString(), style: const TextStyle(color: Colors.teal)),
          ),
          Expanded(
            child: _recentFoodSearchResults(state.recentFoods),
          )
        ];
      }
      else {
        return [
          const ListTile(
            title: Text("Total Foods", style: TextStyle(color: Colors.teal)),
            trailing: Text("0", style: TextStyle(color: Colors.teal)),
          ),
          Expanded(
              child: _searchResults([], null)
          )
        ];
      }
    }
    else {
      return _skeletonLoadingView();
    }
  }

  _foodSearchBar() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: TypeAheadField<String>(
          suggestionsBoxController: _suggestionsController,
          debounceDuration: const Duration(milliseconds: 300),
          textFieldConfiguration: TextFieldConfiguration(
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _foodSearchBloc.add(
                      FetchFoodSearchInfo(
                        currentUserId: widget.currentUserProfile.userId,
                        query: value.trim(),
                        pageNumber: DiaryRepository.DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
                        maxResults: DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
                      )
                  );
                  setState(() {
                    showOnlyRecent = false;
                  });
                }
              },
              autocorrect: false,
              onTap: () {
                  shouldHideKeyboardManually = false;
                  _suggestionsController.toggle();
                },
              onChanged: (text) {
                shouldHideKeyboardManually = false;
                shouldShow = true;
              },
              autofocus: true,
              controller: _searchTextController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Search by food name",
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _searchTextController.text = "";
                      _foodSearchBloc.add(const ClearFoodSearchQuery());
                      shouldShow = false;
                      setState(() {
                        showOnlyRecent = true;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (pattern) async {
            if (pattern.trim().isNotEmpty) {
              // _foodSearchBloc.add(SearchQueryChanged(query: pattern));
              if (shouldShow) {
                const limit = 5;
                final accessToken = await _flutterSecureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
                return (await _diaryRepository.autocompleteFoods(pattern.trim(), accessToken!)).suggestions?.suggestion ?? const [];
              } else {
                return List.empty();
              }
            }
            else {
              return List.empty();
            }
          },
          itemBuilder: (context, suggestion) { // this might not be needed
            return ListTile(
              title: Text(suggestion),
            );
          },
          onSuggestionSelected: (suggestion) {
            _searchTextController.text = suggestion;
            _foodSearchBloc.add(
                FetchFoodSearchInfo(
                  currentUserId: widget.currentUserProfile.userId,
                  query: suggestion.trim(),
                  pageNumber: DiaryRepository.DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
                  maxResults: DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
                )
            );
            setState(() {
              showOnlyRecent = false;
            });
          },
          hideOnEmpty: true,
        )
    );
  }

  // Note - no filter by query done for recent foods
  Widget _recentFoodSearchResults(List<Either<FoodGetResult, FoodGetResultSingleServing>> recentFoods) {
    if (recentFoods.isNotEmpty) {
      return Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: recentFoods.length,
          itemBuilder: (BuildContext context, int index) {
            if (index % 2 == 0) {
              return _recentFoodResultItem(recentFoods[index], true);
            } else {
              return _recentFoodResultItem(recentFoods[index], false);
            }

          },
        ),
      );
    }
    else {
      return const Center(
        child: Text(
            "No results... refine search query"
        ),
      );
    }
  }

  Widget _searchResults(List<FoodSearchResult> items, FoodDataFetched? state) {
    if (items.isNotEmpty) {
      return Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: (state?.doesNextPageExist ?? false) ? items.length + 1 : items.length,
          itemBuilder: (BuildContext context, int index) {
            if (index != items.length) {
              if (index % 2 == 0) {
                return foodResultItem(items[index], true);

              } else {
                return foodResultItem(items[index], false);
              }
            }
            else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              );
            }
          },
        ),
      );
    }
    else {
      return const Center(
        child: Text(
            "No results... refine search query"
        ),
      );
    }
  }

  Widget foodResultItem(FoodSearchResult foodSearchResult, bool toShadeBackground) {
    return ListTile(
      tileColor: toShadeBackground ? Colors.grey.shade100 : null,
      title: Text(foodSearchResult.food_name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(foodSearchResult.food_type),
      subtitle: Text(foodSearchResult.food_description),
      onTap: () {
        Navigator.push(
            context,
            DetailedFoodView.route(
                widget.currentUserProfile,
                foodSearchResult,
                widget.mealOfDay,
                widget.selectedDayInQuestion
            )
        ).then((value) => shouldHideKeyboardManually = false);
      },
    );
  }


  Widget _recentFoodResultItem(Either<FoodGetResult, FoodGetResultSingleServing> recentFood, bool toShadeBackground) {
    if (recentFood.isLeft) {
      final currentFood = recentFood.left.food;
      return ListTile(
        tileColor: toShadeBackground ? Colors.grey.shade100 : null,
        title: Text(currentFood.food_name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(currentFood.food_type),
        // subtitle: Text(recentFood.left.food.),
        onTap: () {
          Navigator.push(
              context,
              DetailedFoodView.route(
                  widget.currentUserProfile,
                  FoodSearchResult("", "", currentFood.food_id, currentFood.food_name, currentFood.food_type, currentFood.food_url),
                  widget.mealOfDay,
                  widget.selectedDayInQuestion
              )
          ).then((value) => shouldHideKeyboardManually = false);
        },
      );
    }
    else {
      final currentFood = recentFood.right.food;
      return ListTile(
        tileColor: toShadeBackground ? Colors.grey.shade100 : null,
        title: Text(currentFood.food_name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(currentFood.food_type),
        // subtitle: Text(recentFood.right.food.),
        onTap: () {
          Navigator.push(
              context,
              DetailedFoodView.route(
                  widget.currentUserProfile,
                  FoodSearchResult("", "", currentFood.food_id, currentFood.food_name, currentFood.food_type, currentFood.food_url),
                  widget.mealOfDay,
                  widget.selectedDayInQuestion
              )
          ).then((value) => shouldHideKeyboardManually = false);
        },
      );
    }

  }

}