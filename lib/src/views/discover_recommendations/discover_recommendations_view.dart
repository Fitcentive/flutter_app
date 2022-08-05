import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/discover_repository.dart';
import 'package:flutter_app/src/models/discover/discover_recommendation.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_bloc.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_event.dart';
import 'package:flutter_app/src/views/discover_recommendations/bloc/discover_recommendations_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DiscoverRecommendationsView extends StatefulWidget {
  static const String routeName = "discover-recommendations";

  final PublicUserProfile userProfile;

  const DiscoverRecommendationsView({
    Key? key,
    required this.userProfile,
  }): super(key: key);

  static Route route({required PublicUserProfile userProfile}) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DiscoverRecommendationsBloc>(
                create: (context) => DiscoverRecommendationsBloc(
                  discoverRepository: RepositoryProvider.of<DiscoverRepository>(context),
                  secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
                )),
          ],
          child: DiscoverRecommendationsView(userProfile: userProfile),
        )
    );

  }

  @override
  State createState() {
    return DiscoverRecommendationsViewState();
  }
}

class DiscoverRecommendationsViewState extends State<DiscoverRecommendationsView> {
  late final DiscoverRecommendationsBloc _discoverRecommendationsBloc;

  @override
  void initState() {
    super.initState();

    _discoverRecommendationsBloc = BlocProvider.of<DiscoverRecommendationsBloc>(context);
    _discoverRecommendationsBloc.add(FetchUserDiscoverRecommendations(widget.userProfile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Buddies', style: TextStyle(color: Colors.teal),)),
      body: _generateBody(),
    );
  }

  _generateBody() {
    return BlocBuilder<DiscoverRecommendationsBloc, DiscoverRecommendationsState>(builder: (context, state) {
      if (state is DiscoverRecommendationsReady) {
        return _carouselSlider(state.currentUserProfile, state.recommendations);
      }
      else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }

  _carouselSlider(PublicUserProfile currentUserProfile, List<DiscoverRecommendation> recommendations) {
    final items = recommendations.map((r) {
      return Builder(
        builder: (BuildContext context) {
          return Container(
              width: ScreenUtils.getScreenWidth(context),
              height: ScreenUtils.getScreenHeight(context) * 0.9,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  color: Colors.amber
              ),
              child: Text('${r.user.userId}', style: TextStyle(fontSize: 16.0),)
          );
        },
      );
    }).toList();
    return CarouselSlider(
        items: items,
        options: CarouselOptions(
          height: 500,
          aspectRatio: 16/9,
          viewportFraction: 0.8,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          // autoPlay: true,
          // autoPlayInterval: Duration(seconds: 3),
          // autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          onPageChanged: (page, reason) {
            print("Page changed to $page for reason $reason");
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }
}