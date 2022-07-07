import 'package:flutter/material.dart';

class ActivitySearchView extends StatefulWidget {

  const ActivitySearchView({Key? key});

  @override
  State createState() {
    return ActivitySearchViewState();
  }

}

class ActivitySearchViewState extends State<ActivitySearchView> with AutomaticKeepAliveClientMixin {
  @override
  bool wantKeepAlive = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Center(
      child: Text("Yet to come..."),
    );
  }
}
