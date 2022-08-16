import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';

typedef FetchMoreResultsCallback = void Function();

class UserResultsList extends StatefulWidget {

  final List<PublicUserProfile> userProfiles;
  final PublicUserProfile currentUserProfile;
  final bool doesNextPageExist;

  final FetchMoreResultsCallback fetchMoreResultsCallback;

  const UserResultsList({
    Key? key,
    required this.userProfiles,
    required this.currentUserProfile,
    required this.doesNextPageExist,
    required this.fetchMoreResultsCallback,
  }): super(key: key);

  @override
  State createState() {
    return UserResultsListState();
  }
}

class UserResultsListState extends State<UserResultsList> {
  static const double _scrollThreshold = 200.0;

  final _scrollController = ScrollController();
  bool isDataBeingRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("Total Results", style: TextStyle(color: Colors.teal)),
          trailing: Text(widget.userProfiles.length.toString(), style: const TextStyle(color: Colors.teal)),
        ),
        Expanded(child: _searchResults(widget.userProfiles))
      ],
    );
  }

  Widget _searchResults(List<PublicUserProfile> items) {
    isDataBeingRequested = false;
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: widget.doesNextPageExist ? items.length + 1 : items.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _userSearchResultItem(items[index]);
          }
        },
      ),
    );
  }

  Widget _userSearchResultItem(PublicUserProfile userProfile) {
    return ListTile(
      title: Text("${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Text(""),
      subtitle: Text(userProfile.username ?? ""),
      leading: CircleAvatar(
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

  void _onScroll() {
    if(_scrollController.hasClients ) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll - currentScroll <= _scrollThreshold && !isDataBeingRequested) {
        isDataBeingRequested = true;
        widget.fetchMoreResultsCallback();
      }
    }
  }

}