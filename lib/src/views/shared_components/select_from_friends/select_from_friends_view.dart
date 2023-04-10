import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
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

typedef UpdateSelectedUserIdCallback = void Function(PublicUserProfile userProfile);

GlobalKey<SelectFromUsersViewState> selectFromFriendsViewStateGlobalKey = GlobalKey();

class SelectFromUsersView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;
  final List<PublicUserProfile> alreadySelectedUserProfiles;
  final bool isRestrictedOnlyToFriends;


  final UpdateSelectedUserIdCallback addSelectedUserIdToParticipantsCallback;
  final UpdateSelectedUserIdCallback removeSelectedUserFromToParticipantsCallback;

  const SelectFromUsersView({
    Key? key,
    required this.currentUserProfile,
    required this.addSelectedUserIdToParticipantsCallback,
    required this.removeSelectedUserFromToParticipantsCallback,
    required this.alreadySelectedUserProfiles,
    required this.isRestrictedOnlyToFriends,
  }): super(key: key);

  static Widget withBloc({
    String? postId,
    Key? key,
    required String currentUserId,
    required PublicUserProfile currentUserProfile,
    required UpdateSelectedUserIdCallback addSelectedUserIdToParticipantsCallback,
    required UpdateSelectedUserIdCallback removeSelectedUserFromToParticipantsCallback,
    required List<PublicUserProfile> alreadySelectedUserProfiles,
    required bool isRestrictedOnlyToFriends,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SelectFromFriendsBloc>(
            create: (context) => SelectFromFriendsBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              socialMediaRepository: RepositoryProvider.of<SocialMediaRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
            )),
      ],
      child: SelectFromUsersView(
          key: key,
          currentUserProfile: currentUserProfile,
          addSelectedUserIdToParticipantsCallback: addSelectedUserIdToParticipantsCallback,
          removeSelectedUserFromToParticipantsCallback: removeSelectedUserFromToParticipantsCallback,
          alreadySelectedUserProfiles: alreadySelectedUserProfiles,
          isRestrictedOnlyToFriends: isRestrictedOnlyToFriends,
        ),
    );
  }

  @override
  State createState() {
    return SelectFromUsersViewState();
  }
}

class SelectFromUsersViewState extends State<SelectFromUsersView> {
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

    widget.alreadySelectedUserProfiles.forEach((element) {
      userIdToBoolCheckedMap[element.userId] = true;
    });
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
        if (state is FriendsDataLoaded) {
          if (state.userProfiles.isNotEmpty) {
            state.userProfiles.forEach((element) {
              userIdToBoolCheckedMap[element.userId] = userIdToBoolCheckedMap[element.userId] ?? false;
            });
          }
        }
      },
      child: BlocBuilder<SelectFromFriendsBloc, SelectFromFriendsState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _renderSearchBar(),
              WidgetUtils.spacer(5),
              _renderSelectUsersListView(state),
            ],
          );
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

  _renderSelectUsersListView(SelectFromFriendsState state) {
    if (state is FriendsDataLoaded) {
      isDataBeingRequested = false;
      if (state.userProfiles.isEmpty) {
        if (widget.isRestrictedOnlyToFriends) {
          return const Center(
            child: Text("No friends here... get started by discovering people!"),
          );
        }
        else {
          return const Center(
            child: Text("No results found..."),
          );
        }
      }
      else {
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
              widget.addSelectedUserIdToParticipantsCallback(userProfile);
            }
            else if (!value) {
              widget.removeSelectedUserFromToParticipantsCallback(userProfile);
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

  _renderSearchBar() {
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
                      _searchTextController.text = "";
                      _selectFromFriendsBloc.add(ReFetchFriendsRequested(
                          userId: widget.currentUserProfile.userId,
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
                isRestrictedOnlyToFriends: widget.isRestrictedOnlyToFriends,
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