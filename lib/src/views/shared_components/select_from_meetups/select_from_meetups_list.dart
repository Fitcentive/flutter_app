import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/views/shared_components/meetup_mini_card_view.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/bloc/select_from_meetups_bloc.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/bloc/select_from_meetups_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_meetups/bloc/select_from_meetups_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef UpdateSelectedMeetupIdCallback = void Function(SelectedMeetupInfo info);

GlobalKey<SelectFromMeetupsListState> selectFromFriendsViewStateGlobalKey = GlobalKey();

class SelectedMeetupInfo {
  final Meetup? associatedMeetup;
  final List<MeetupParticipant>? associatedMeetupParticipants;
  final List<MeetupDecision>? associatedMeetupDecisions;
  final Map<String, PublicUserProfile> userIdProfileMap;

  const SelectedMeetupInfo({
    required this.associatedMeetup,
    required this.associatedMeetupParticipants,
    required this.associatedMeetupDecisions,
    required this.userIdProfileMap,
  });
}

class SelectFromMeetupsList extends StatefulWidget {

  final PublicUserProfile currentUserProfile;
  final String? previouslySelectedMeetupId;

  final UpdateSelectedMeetupIdCallback selectedMeetupIdAddedCallback;
  final UpdateSelectedMeetupIdCallback selectedMeetupIdRemovedCallback;

  const SelectFromMeetupsList({
    Key? key,
    required this.currentUserProfile,
    required this.previouslySelectedMeetupId,
    required this.selectedMeetupIdAddedCallback,
    required this.selectedMeetupIdRemovedCallback,
  }): super(key: key);

  static Widget withBloc({
    Key? key,
    required PublicUserProfile currentUserProfile,
    required UpdateSelectedMeetupIdCallback selectedMeetupIdAddedCallback,
    required UpdateSelectedMeetupIdCallback selectedMeetupIdRemovedCallback,
    required String? previouslySelectedMeetupId,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SelectFromMeetupsBloc>(
            create: (context) => SelectFromMeetupsBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SelectFromMeetupsList(
        key: key,
        currentUserProfile: currentUserProfile,
        selectedMeetupIdRemovedCallback: selectedMeetupIdRemovedCallback,
        selectedMeetupIdAddedCallback: selectedMeetupIdAddedCallback,
        previouslySelectedMeetupId: previouslySelectedMeetupId,
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    return SelectFromMeetupsListState();
  }
}

class SelectFromMeetupsListState extends State<SelectFromMeetupsList> {
  static const double _scrollThreshold = 200.0;

  late final SelectFromMeetupsBloc _selectFromMeetupsBloc;
  bool isDataBeingRequested = false;
  Map<String, bool> meetupIdToBoolCheckedMap = {};

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _selectFromMeetupsBloc = BlocProvider.of<SelectFromMeetupsBloc>(context);
    _selectFromMeetupsBloc.add(FetchUserMeetupData(
        userId: widget.currentUserProfile.userId,
    ));

    _scrollController.addListener(_onScroll);

    if (widget.previouslySelectedMeetupId != null) {
      meetupIdToBoolCheckedMap[widget.previouslySelectedMeetupId!] = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SelectFromMeetupsBloc, SelectFromMeetupsState>(
      listener: (context, state) {
        if (state is MeetupUserDataFetched) {
          if (state.meetups.isNotEmpty) {
            state.meetups.forEach((element) {
              meetupIdToBoolCheckedMap[element.id] = meetupIdToBoolCheckedMap[element.id] ?? false;
            });
          }
        }
      },
      child: BlocBuilder<SelectFromMeetupsBloc, SelectFromMeetupsState>(
        builder: (context, state) {
          return _renderSelectUsersListView(state);
        },
      ),
    );
  }

  _renderSelectUsersListView(SelectFromMeetupsState state) {
    if (state is MeetupUserDataFetched) {
      isDataBeingRequested = false;
      if (state.meetups.isEmpty) {
        return const Center(
          child: Text("No meetups found..."),
        );
      }
      else {
        return Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            itemCount: state.doesNextPageExist ? state.meetups.length + 1 : state.meetups.length,
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.meetups.length) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return _userSelectSearchResultItem(state, index);
              }
            },
          ),
        );
      }
    }
    else {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  _checkBox(
      Meetup meetup,
      List<MeetupParticipant> meetupParticipants,
      List<MeetupDecision> meetupDecisions,
      Map<String, PublicUserProfile> userIdProfileMap,
    ) {
    return Transform.scale(
      scale: 1.25,
      child: Checkbox(
        checkColor: Colors.white,
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          final c = Theme.of(context).primaryColor;
          if (states.contains(MaterialState.disabled)) {
            return c.withOpacity(.32);
          }
          return c;
        }),
        value: meetupIdToBoolCheckedMap[meetup.id],
        shape: const CircleBorder(),
        onChanged: (bool? value) {
          setState(() {
            meetupIdToBoolCheckedMap.forEach((key, value) {
              if (key != meetup.id) {
                meetupIdToBoolCheckedMap[key] = false;
              }
            });

            meetupIdToBoolCheckedMap[meetup.id] = value!;
          });

          // Need to update parent bloc state here
          if (value!) {
            widget.selectedMeetupIdAddedCallback(SelectedMeetupInfo(
                associatedMeetup: meetup,
                associatedMeetupParticipants: meetupParticipants,
                associatedMeetupDecisions: meetupDecisions,
                userIdProfileMap: userIdProfileMap,
            ));
          }
          else if (!value) {
            widget.selectedMeetupIdRemovedCallback(SelectedMeetupInfo(
              associatedMeetup: meetup,
              associatedMeetupParticipants: meetupParticipants,
              associatedMeetupDecisions: meetupDecisions,
              userIdProfileMap: userIdProfileMap,
            ));
          }
        },
      ),
    );
  }

  _userSelectSearchResultItem(MeetupUserDataFetched state, int index) {
    final currentMeetup = state.meetups[index];
    final currentMeetupParticipants = state.meetupParticipants[currentMeetup.id]!;
    final currentMeetupDecisions = state.meetupDecisions[currentMeetup.id]!;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _checkBox(currentMeetup, currentMeetupParticipants, currentMeetupDecisions, state.userIdProfileMap)
        ),
        Expanded(
            flex: 8,
            child: _renderMeetupMiniCardView(
                currentMeetup,
                currentMeetupParticipants,
                currentMeetupDecisions,
                state.userIdProfileMap,
            )
        ),
      ],
    );
  }

  _renderMeetupMiniCardView(
      Meetup meetup,
      List<MeetupParticipant> meetupParticipants,
      List<MeetupDecision> meetupDecisions,
      Map<String, PublicUserProfile> userIdProfileMap,
  ) {
    return MeetupMiniCardView(
        currentUserProfile: widget.currentUserProfile,
        meetup: meetup,
        participants: meetupParticipants,
        decisions: meetupDecisions,
        userIdProfileMap: userIdProfileMap,
        onCardTapped: () {  },
    );
  }

  void _onScroll() {
    if(_scrollController.hasClients ) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        _fetchMoreResults();
      }
    }
  }

  _fetchMoreResults() {
    final currentState = _selectFromMeetupsBloc.state;
    if (currentState is MeetupUserDataFetched) {
      isDataBeingRequested = true;
      _selectFromMeetupsBloc.add(FetchMoreUserMeetupData(
          userId: widget.currentUserProfile.userId,
      ));
    }
  }

}