import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_result.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_bloc.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_event.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FoodSearchView extends StatefulWidget {
  static const String routeName = "food/search";

  final PublicUserProfile currentUserProfile;
  final String mealOfDay; // One of Breakfast, Lunch, Dinner, or Snacks

  const FoodSearchView({Key? key, required this.currentUserProfile, required this.mealOfDay}): super(key: key);

  static Route route(PublicUserProfile currentUserProfile, String mealOfDay) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => FoodSearchView.withBloc(currentUserProfile, mealOfDay)
    );
  }

  static Widget withBloc(PublicUserProfile currentUserProfile, String mealOfDay) => MultiBlocProvider(
    providers: [
      BlocProvider<FoodSearchBloc>(
          create: (context) => FoodSearchBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: FoodSearchView(currentUserProfile: currentUserProfile, mealOfDay: mealOfDay),
  );


  @override
  State createState() {
    return FoodSearchViewState();
  }
}

class FoodSearchViewState extends State<FoodSearchView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 2;
  static const double _scrollThreshold = 400.0;

  late FoodSearchBloc _foodSearchBloc;

  late final TabController _tabController;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  Timer? _searchQueryDebounceTimer;
  Timer? _scrollControllerDebounceTimer;
  final _scrollController = ScrollController();

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

    _foodSearchBloc = BlocProvider.of<FoodSearchBloc>(context);
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("View Exercises", style: TextStyle(color: Colors.teal)),
      //   iconTheme: const IconThemeData(color: Colors.teal),
      // ),
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
            title: Text("View ${widget.mealOfDay} Foods", style: TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.timelapse, color: Colors.teal,), text: "Recent"),
                Tab(icon: Icon(Icons.dinner_dining, color: Colors.teal,), text: "All"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showFoodList(state, true),
              _showFoodList(state, false),
            ],
          ),
        )
    );
  }

  _showFoodList(FoodSearchState state, bool showOnlyRecent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _foodSearchBar(),
        WidgetUtils.spacer(2.5),
        ..._renderResultsOrProgressIndicator(state, showOnlyRecent)
      ],
    );
  }

  List<Widget> _renderResultsOrProgressIndicator(FoodSearchState state, bool showOnlyRecent) {
    if (state is FoodSearchStateInitial) {
      return [
        const ListTile(
          title: Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text("0", style: TextStyle(color: Colors.teal)),
        ),
        Expanded(
            child: _searchResults([])
        )
      ];
    }
    else if (state is FoodDataFetched) {
      return [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(state.results.foods.food.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(
            child: _searchResults(showOnlyRecent ? [] : state.results.foods.food) // todo - fix this when recent is available
        )
      ];
    }
    else {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: Colors.teal,
            ),
          ),
        )
      ];
    }
  }

  _foodSearchBar() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: TypeAheadField<PublicUserProfile>(
          suggestionsBoxController: _suggestionsController,
          debounceDuration: const Duration(milliseconds: 300),
          textFieldConfiguration: TextFieldConfiguration(
              onSubmitted: (value) {},
              autocorrect: false,
              onTap: () => _suggestionsController.toggle(),
              onChanged: (text) {},
              autofocus: true,
              controller: _searchTextController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Search by food name",
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _searchTextController.text = "";
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (text)  {
            if (_searchQueryDebounceTimer?.isActive ?? false) _searchQueryDebounceTimer?.cancel();
            _searchQueryDebounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (text.trim().isNotEmpty) {
                _foodSearchBloc.add(
                    FetchFoodSearchInfo(
                      query: text.trim(),
                      pageNumber: DiaryRepository.DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
                      maxResults: DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
                    )
                );
              }
            });
            return List.empty();
          },
          // TODO  + PROVIDE ATTRIBUTEION TO WGER AND FATSECRET API
          itemBuilder: (context, suggestion) { // this might not be needed
            final s = suggestion;
            return ListTile(
              leading: CircleAvatar(
                radius: 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: ImageUtils.getUserProfileImage(suggestion, 100, 100),
                  ),
                ),
              ),
              title: Text("${s.firstName ?? ""} ${s.lastName ?? ""}"),
              subtitle: Text(suggestion.username ?? ""),
            );
          },
          onSuggestionSelected: (suggestion) {},
          hideOnEmpty: true,
        )
    );
  }

  Widget _searchResults(List<FoodSearchResult> items) {
    if (items.isNotEmpty) {
      return Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index != items.length) {
              return foodResultItem(items[index]);
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

  Widget foodResultItem(FoodSearchResult foodSearchResult) {
    return ListTile(
      title: Text(foodSearchResult.food_name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(foodSearchResult.food_type),
      subtitle: Text(foodSearchResult.food_description),
      onTap: () {
        // todo Move to detailed food definition page from here
      },
    );
  }

}