import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_bloc.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_event.dart';
import 'package:flutter_app/src/views/discover_user_preferences/bloc/discover_user_preferences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransportPreferenceView extends StatefulWidget {
  final PublicUserProfile userProfile;
  final String? preferredTransportMethod;

  const TransportPreferenceView({
    Key? key,
    required this.userProfile,
    required this.preferredTransportMethod,
  }): super(key: key);

  @override
  State createState() {
    return TransportPreferenceViewState();
  }
}

class TransportPreferenceViewState extends State<TransportPreferenceView> with WidgetsBindingObserver {
  late final DiscoverUserPreferencesBloc _discoverUserPreferencesBloc;

  String selectedTransportMode = ConstantUtils.defaultTransport;

  @override
  void initState() {
    super.initState();

    _discoverUserPreferencesBloc = BlocProvider.of<DiscoverUserPreferencesBloc>(context);
    selectedTransportMode = widget.preferredTransportMethod ?? ConstantUtils.defaultTransport;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateBlocState(selectedTransportMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
                child: FittedBox(
                    child: Text("What is your preferred mode of transport?", style: TextStyle(fontSize: 20),
                    )
                )
            ),
            WidgetUtils.spacer(20),
            _transportModePicker()
          ],
        ),
      ),
    );
  }

  _transportModePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transport mode', style: TextStyle(fontSize: 13),),
        DropdownButton<String>(
            isExpanded: true,
            value: selectedTransportMode,
            items: ConstantUtils.transportTypes.map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            )).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateBlocState(newValue);
              }
            }
        )
      ],
    );
  }

  _updateBlocState(String transportMode) {
    final currentState = _discoverUserPreferencesBloc.state;
    if (currentState is UserDiscoverPreferencesModified) {
      _discoverUserPreferencesBloc.add(UserDiscoverPreferencesChanged(
        userProfile: widget.userProfile,
        locationCenter: currentState.locationCenter,
        locationRadius: currentState.locationRadius,
        preferredTransportMode: transportMode,
        activitiesInterestedIn: currentState.activitiesInterestedIn,
        fitnessGoals: currentState.fitnessGoals,
        desiredBodyTypes: currentState.desiredBodyTypes,
        gendersInterestedIn: currentState.gendersInterestedIn,
        preferredDays: currentState.preferredDays,
        minimumAge: currentState.minimumAge,
        maximumAge: currentState.maximumAge,
        hoursPerWeek: currentState.hoursPerWeek,
        hasGym: currentState.hasGym,
        gymLocationId: currentState.gymLocationId,
        gymLocationFsqId: currentState.gymLocationFsqId,
      ));
      setState(() {
        selectedTransportMode = transportMode;
      });
    }
  }

}