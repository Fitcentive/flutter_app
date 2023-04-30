import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_exercise/detailed_exercise_view.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_bloc.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_event.dart';
import 'package:flutter_app/src/views/search/bloc/activity_search/activity_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ActivitySearchView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const ActivitySearchView({Key? key, required this.currentUserProfile}): super(key: key);

  @override
  State createState() {
    return ActivitySearchViewState();
  }

}

class ActivitySearchViewState extends State<ActivitySearchView> with AutomaticKeepAliveClientMixin {
  @override
  bool wantKeepAlive = true;

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  late ActivitySearchBloc _activitySearchBloc;

  @override
  void initState() {
    super.initState();

    _activitySearchBloc = BlocProvider.of<ActivitySearchBloc>(context);
    _activitySearchBloc.add(const FetchAllActivityInfo());
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ActivitySearchBloc, ActivitySearchState>(
      builder: (context, state) {
        if (state is ActivityDataFetched) {
          return _showExerciseList(state.filteredExerciseInfo);
        }
        else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  _showExerciseList(List<ExerciseDefinition> exercises) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                      _activitySearchBloc.add(const ActivityFilterSearchQueryChanged(searchQuery: ""));
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (text)  {
            _activitySearchBloc.add(ActivityFilterSearchQueryChanged(searchQuery: text.trim()));
            return List.empty();
          },
          itemBuilder: (context, suggestion) {
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
        Navigator.pushAndRemoveUntil(
            context,
            DetailedExerciseView.route(
                widget.currentUserProfile,
                exerciseDefinition,
                exerciseDefinition.category.id == ConstantUtils.CARDIO_EXERCISE_CATEGORY_DEFINITION,
                DateTime.now()
            ),
                (route) => true
        );
      },
    );
  }
}
