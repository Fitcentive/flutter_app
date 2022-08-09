import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BodyTypePreferencesView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final List<String>? bodyTypes;

  const BodyTypePreferencesView({
    Key? key,
    required this.userProfile,
    required this.bodyTypes,
  }): super(key: key);

  @override
  State createState() {
    return BodyTypePreferencesViewState();
  }
}

class BodyTypePreferencesViewState extends State<BodyTypePreferencesView> {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  List<String> selectedBodyTypes = List<String>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedBodyTypes = widget.bodyTypes ?? List.empty(growable: true);
    _updateBlocState(selectedBodyTypes);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> bodyTypesList = List.empty(growable: true);
    ConstantUtils.bodyTypes.forEach((bodyType, imageAsset) => bodyTypesList.addAll([
      _createCheckbox(bodyType),
      _imageView(imageAsset)
    ]));
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("What body types do you prefer?", style: TextStyle(fontSize: 20),),
              WidgetUtils.spacer(5),
              const Text("Select all that apply", style: TextStyle(fontSize: 15),),
              WidgetUtils.spacer(20),
              ...bodyTypesList,
            ],
          ),
        ),
      ),
    );
  }

  _imageView(String assetImagePath) {
    return SizedBox(
      height: 150,
      child: Image(image: AssetImage(assetImagePath)),
    );
  }

  _createCheckbox(String entity) {
    return CheckboxListTile(
        value: selectedBodyTypes.contains(entity),
        title: Text(entity),
        onChanged: (newValue) {
          if (newValue != null) {
            if (newValue) {
              selectedBodyTypes.add(entity);
            }
            else {
              selectedBodyTypes.remove(entity);
            }
            _updateBlocState(selectedBodyTypes);
          }
        }
    );
  }

  _updateBlocState(List<String> newBodyTypes) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
        userProfile: widget.userProfile,
        locationCenter: currentState.locationCenter,
        locationRadius: currentState.locationRadius,
        preferredTransportMode: currentState.preferredTransportMode,
        activitiesInterestedIn: currentState.activitiesInterestedIn,
        fitnessGoals: currentState.fitnessGoals,
        desiredBodyTypes: newBodyTypes,
        gendersInterestedIn: currentState.gendersInterestedIn,
        preferredDays: currentState.preferredDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
      ));
      setState(() {
        selectedBodyTypes = newBodyTypes;
      });
    }
  }

}