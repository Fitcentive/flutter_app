import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_exercise/detailed_exercise_view.dart';
import 'package:flutter_app/src/views/exercise_search/bloc/exercise_search_bloc.dart';
import 'package:flutter_app/src/views/exercise_search/bloc/exercise_search_event.dart';
import 'package:flutter_app/src/views/exercise_search/bloc/exercise_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseSearchView extends StatefulWidget {
  static const String routeName = "exercise/search";

  final PublicUserProfile currentUserProfile;
  final FitnessUserProfile currentFitnessUserProfile;
  final DateTime selectedDayInQuestion; // The day for which a potential diary entry might be added

  const ExerciseSearchView({
    Key? key,
    required this.currentUserProfile,
    required this.currentFitnessUserProfile,
    required this.selectedDayInQuestion,
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      DateTime selectedDayInQuestion
      ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => ExerciseSearchView.withBloc(currentUserProfile, currentFitnessUserProfile, selectedDayInQuestion)
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      DateTime selectedDayInQuestion
      ) => MultiBlocProvider(
    providers: [
      BlocProvider<ExerciseSearchBloc>(
          create: (context) => ExerciseSearchBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: ExerciseSearchView(
      currentUserProfile: currentUserProfile,
      currentFitnessUserProfile: currentFitnessUserProfile,
      selectedDayInQuestion: selectedDayInQuestion,
    ),
  );


  @override
  State createState() {
    return ExerciseSearchViewState();
  }
}

class ExerciseSearchViewState extends State<ExerciseSearchView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 3;
  late ExerciseSearchBloc _exerciseSearchBloc;

  late final TabController _tabController;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: MAX_TABS);

    _exerciseSearchBloc = BlocProvider.of<ExerciseSearchBloc>(context);
    _exerciseSearchBloc.add(FetchAllExerciseInfo(currentUserId: widget.currentUserProfile.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ExerciseSearchBloc, ExerciseSearchState>(
        listener: (context, state) {
          if (state is ExerciseDataFetched) {
            setState(() {
              // set state here
            });
          }
        },
        child: BlocBuilder<ExerciseSearchBloc, ExerciseSearchState>(
          builder: (context, state) {
            if (state is ExerciseDataFetched) {
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

  Widget _mainBody(ExerciseDataFetched state) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: const Text("View Exercises", style: TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.timelapse, color: Colors.teal,), text: "Recent"),
                Tab(icon: Icon(Icons.run_circle_outlined, color: Colors.teal,), text: "Cardio"),
                Tab(icon: Icon(Icons.fitness_center, color: Colors.teal,), text: "Strength"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showExerciseList(
                  List.from(
                      state
                          .filteredExerciseInfo
                          .where((element) => state.recentlyViewedWorkoutIds.contains(element.uuid))
                          .toList()
                  )
                      ..sort((a,b) => state.recentlyViewedWorkoutIds.indexOf(a.uuid) - state.recentlyViewedWorkoutIds.indexOf(b.uuid))
              ),
              _showExerciseList(state.filteredExerciseInfo.where((element) => element.category.id == ConstantUtils.CARDIO_EXERCISE_CATEGORY_DEFINITION).toList()),
              _showExerciseList(state.filteredExerciseInfo.where((element) => element.category.id != ConstantUtils.CARDIO_EXERCISE_CATEGORY_DEFINITION).toList()),
            ],
          ),
        )
    );
  }

  _showExerciseList(List<ExerciseDefinition> exercises) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetUtils.spacer(5),
        _renderWgerApiAttribution(),
        WidgetUtils.spacer(5),
        _exerciseSearchBar(),
        WidgetUtils.spacer(2.5),
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(exercises.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(child: _searchResults(exercises))
      ],
    );
  }

  _renderWgerApiAttribution() {
    return Center(
      child: RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Powered by Wger",
                    style: Theme.of(context).textTheme.subtitle2?.copyWith(color: Colors.teal),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      launchUrl(Uri.parse(ConstantUtils.WGER_ATTRIBUTION_URL));
                    }
                ),
              ]
          )
      ),
    );
  }

  _exerciseSearchBar() {
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
                  hintText: "Search by exercise name",
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _searchTextController.text = "";
                      // todo - fetch recently logged exercises too, need to save in be
                      _exerciseSearchBloc.add(const FilterSearchQueryChanged(searchQuery: ""));
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (text)  {
            _exerciseSearchBloc.add(FilterSearchQueryChanged(searchQuery: text.trim()));
            return List.empty();
          },
          itemBuilder: (context, suggestion) { // todo - there is an error here and maybe this is not needed?
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

  Widget _searchResults(List<ExerciseDefinition> items) {
    if (items.isNotEmpty) {
      return Scrollbar(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return exerciseResultItem(items[index]);
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

  Widget exerciseResultItem(ExerciseDefinition exerciseDefinition) {
    return ListTile(
      title: Text(exerciseDefinition.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Text(""),
      subtitle: Text(exerciseDefinition.category.name),
      leading: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getExerciseImage(exerciseDefinition.images),
          ),
        ),
      ),
      onTap: () {
        // Move to detailed exercise definition page from here
        Navigator.push(
            context,
            DetailedExerciseView.route(
                widget.currentUserProfile,
                widget.currentFitnessUserProfile,
                exerciseDefinition,
                exerciseDefinition.category.id == ConstantUtils.CARDIO_EXERCISE_CATEGORY_DEFINITION,
                widget.selectedDayInQuestion
            ),
        ).then((value) => Navigator.pop(context));
      },
    );
  }

}