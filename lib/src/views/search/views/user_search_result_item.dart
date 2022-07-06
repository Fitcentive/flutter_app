import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/user_profile.dart';
import 'package:flutter_app/src/views/user_profile/user_profile.dart';

class UserSearchResultItem extends StatelessWidget {
  final UserProfile userProfile;

  const UserSearchResultItem({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
          "${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.w500)
      ),
      trailing: const Text(""),
      subtitle: const Text("username"),
      leading: const Icon(Icons.account_circle_outlined, color: Colors.teal),
      onTap: () {
        Navigator.pushAndRemoveUntil(context, UserProfileView.route(userProfile), (route) => true);
      },
    );
  }
}