import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/bloc/select_from_friends_bloc.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/bloc/select_from_friends_event.dart';
import 'package:flutter_app/src/views/shared_components/select_from_friends/bloc/select_from_friends_state.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

typedef UpdateSelectedUserIdCallback = void Function(String userId);

GlobalKey<SelectFromFriendsViewState> selectFromFriendsViewStateGlobalKey = GlobalKey();

class SelectFromFriendsView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  final UpdateSelectedUserIdCallback addSelectedUserIdToParticipantsCallback;
  final UpdateSelectedUserIdCallback removeSelectedUserIdToParticipantsCallback;

  const SelectFromFriendsView({
    Key? key,
    required this.currentUserProfile,
    required this.addSelectedUserIdToParticipantsCallback,
    required this.removeSelectedUserIdToParticipantsCallback,
  }): super(key: key);

  static Widget withBloc({
    String? postId,
    Key? key,
    required String currentUserId,
    required PublicUserProfile currentUserProfile,
    required UpdateSelectedUserIdCallback addSelectedUserIdToParticipantsCallback,
    required UpdateSelectedUserIdCallback removeSelectedUserIdToParticipantsCallback,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SelectFromFriendsBloc>(
            create: (context) => SelectFromFriendsBloc(
              socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SelectFromFriendsView(
          key: key,
          currentUserProfile: currentUserProfile,
          addSelectedUserIdToParticipantsCallback: addSelectedUserIdToParticipantsCallback,
          removeSelectedUserIdToParticipantsCallback: removeSelectedUserIdToParticipantsCallback,
        ),
    );
  }

  @override
  State createState() {
    return SelectFromFriendsViewState();
  }
}

class SelectFromFriendsViewState extends State<SelectFromFriendsView> {
  static const double _scrollThreshold = 200.0;

  late final SelectFromFriendsBloc _selectFromFriendsBloc;
  bool isDataBeingRequested = false;
  final _scrollController = ScrollController();

  Map<String, bool> userIdToBoolCheckedMap = {};

  final _searchTextController = TextEditingController();
  final _suggestionsController = SuggestionsBoxController();

  @override
  void initState() {
    super.initState();

    _selectFromFriendsBloc = BlocProvider.of<SelectFromFriendsBloc>(context);
    _selectFromFriendsBloc.add(FetchFriendsRequested(
      userId: widget.currentUserProfile.userId,
      limit: ConstantUtils.DEFAULT_LIMIT,
      offset: ConstantUtils.DEFAULT_OFFSET
    ));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  // Method called via globalKey to update
  void makeUserListItemUnselected(String userId) {
    setState(() {
      userIdToBoolCheckedMap[userId] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SelectFromFriendsBloc, SelectFromFriendsState>(
      listener: (context, state) {

      },
      child: BlocBuilder<SelectFromFriendsBloc, SelectFromFriendsState>(
        builder: (context, state) {
          if (state is FriendsDataLoaded) {
            if (state.userProfiles.isEmpty) {
              return const Center(
                child: Text("No friends here... get started by discovering people!"),
              );
            }
            else {
              state.userProfiles.forEach((element) {
                userIdToBoolCheckedMap[element.userId] = userIdToBoolCheckedMap[element.userId] ?? false;
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _renderSearchBar(state),
                  WidgetUtils.spacer(5),
                  _renderSelectUsersListView(state),
                ],
              );
            }
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
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
    final currentState = _selectFromFriendsBloc.state;
    if (currentState is FriendsDataLoaded) {
      isDataBeingRequested = true;
      _selectFromFriendsBloc.add(FetchFriendsRequested(
          userId: widget.currentUserProfile.userId,
          limit: ConstantUtils.DEFAULT_LIMIT,
          offset: currentState.userProfiles.length
      ));
    }
  }

  _renderSelectUsersListView(FriendsDataLoaded state) {
    isDataBeingRequested = false;
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: state.doesNextPageExist ? state.userProfiles.length + 1 : state.userProfiles.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= state.userProfiles.length) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _userSelectSearchResultItem(state.userProfiles[index]);
          }
        },
      ),
    );
  }

  _userSelectSearchResultItem(PublicUserProfile userProfile) {
    return ListTile(
      title: Text("${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)),
      leading: Transform.scale(
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
          value: userIdToBoolCheckedMap[userProfile.userId],
          shape: const CircleBorder(),
          onChanged: (bool? value) {
            setState(() {
              userIdToBoolCheckedMap[userProfile.userId] = value!;
            });

            // Need to update parent bloc state here
            if (value!) {
              widget.addSelectedUserIdToParticipantsCallback(userProfile.userId);
            }
            else if (!value) {
              widget.removeSelectedUserIdToParticipantsCallback(userProfile.userId);
            }
          },
        ),
      ),
      subtitle: Text(userProfile.username ?? ""),
      trailing: CircleAvatar(
        radius: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: ImageUtils.getUserProfileImage(userProfile, 500, 500),
          ),
        ),
      ),
      onTap: () {
        Navigator.pushAndRemoveUntil(
            context,
            UserProfileView.route(userProfile, widget.currentUserProfile),
                (route) => true
        );
      },
    );
  }

  _renderSearchBar(FriendsDataLoaded state) {
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
                  hintText: "Search by name/username",
                  suffixIcon: IconButton(
                    onPressed: () {
                      _suggestionsController.close();
                      _selectFromFriendsBloc.add(FetchFriendsByQueryRequested(
                          userId: widget.currentUserProfile.userId,
                          query: _searchTextController.value.text,
                          limit: ConstantUtils.DEFAULT_LIMIT,
                          offset: ConstantUtils.DEFAULT_OFFSET,
                      ));
                    },
                    icon: const Icon(Icons.close),
                  ))),
          suggestionsCallback: (text)  {
            if (text.trim().isNotEmpty) {
              _selectFromFriendsBloc.add(FetchFriendsByQueryRequested(
                userId: widget.currentUserProfile.userId,
                query: text,
                limit: ConstantUtils.DEFAULT_LIMIT,
                offset: ConstantUtils.DEFAULT_OFFSET,
              ));
            }
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
}