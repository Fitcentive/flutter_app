import 'package:flutter/material.dart';
import 'package:flutter_app/src/views/search/views/user_search_bar.dart';
import 'package:flutter_app/src/views/search/views/user_search_body.dart';

class UserSearchView extends StatelessWidget {

  const UserSearchView({Key? key});

  @override
  Widget build(BuildContext context) {
    return _buildSearch(context);
  }

  Widget _buildSearch(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const <Widget> [
        UserSearchBar(),
        UserSearchBody()
      ],
    );
  }

}