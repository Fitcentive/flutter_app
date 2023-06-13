import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/diary/fitness_user_profile.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/ad_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/add_exercise_to_diary/add_exercise_to_diary_view.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_bloc.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';

class DetailedExerciseView extends StatefulWidget {

  static const String routeName = "exercise/search";

  final PublicUserProfile currentUserProfile;
  final FitnessUserProfile currentFitnessUserProfile;
  final ExerciseDefinition exerciseDefinition;
  final bool isCurrentExerciseDefinitionCardio;
  final DateTime selectedDayInQuestion;

  const DetailedExerciseView({
    Key? key,
    required this.currentUserProfile,
    required this.currentFitnessUserProfile,
    required this.exerciseDefinition,
    required this.isCurrentExerciseDefinitionCardio,
    required this.selectedDayInQuestion
  }): super(key: key);

  static Route route(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion
  ) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => DetailedExerciseView.withBloc(
            currentUserProfile,
            currentFitnessUserProfile,
            exerciseDefinition,
            isCurrentExerciseDefinitionCardio,
            selectedDayInQuestion
        )
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      FitnessUserProfile currentFitnessUserProfile,
      ExerciseDefinition exerciseDefinition,
      bool isCurrentExerciseDefinitionCardio,
      DateTime selectedDayInQuestion
  ) => MultiBlocProvider(
    providers: [
      BlocProvider<DetailedExerciseBloc>(
          create: (context) => DetailedExerciseBloc(
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )
      ),
    ],
    child: DetailedExerciseView(
        currentUserProfile: currentUserProfile,
        currentFitnessUserProfile: currentFitnessUserProfile,
        exerciseDefinition: exerciseDefinition,
        isCurrentExerciseDefinitionCardio: isCurrentExerciseDefinitionCardio,
        selectedDayInQuestion: selectedDayInQuestion,
    ),
  );


  @override
  State createState() {
    return DetailedExerciseViewState();
  }
}

class DetailedExerciseViewState extends State<DetailedExerciseView> with SingleTickerProviderStateMixin {
  static const int MAX_TABS = 2;
  late final TabController _tabController;

  late DetailedExerciseBloc _detailedExerciseBloc;

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();

    _detailedExerciseBloc = BlocProvider.of<DetailedExerciseBloc>(context);
    _detailedExerciseBloc.add(
        AddCurrentExerciseToUserMostRecentlyViewed(
          currentUserId: widget.currentUserProfile.userId,
          currentExerciseId: widget.exerciseDefinition.uuid
        )
    );
    _tabController = TabController(vsync: this, length: MAX_TABS);
  }

  _bottomBarWithOptAd() {
    final maxHeight = AdUtils.defaultBannerAdHeightForDetailedFoodAndExerciseView(context) * 2;
    final Widget? adWidget = WidgetUtils.showHomePageAdIfNeeded(context, maxHeight);
    if (adWidget == null) {
      return _bottomBarInternal(maxHeight);
    }
    else {
      return SizedBox(
        height: maxHeight + 100,
        child: Column(
          children: [
            _bottomBarInternal(maxHeight),
            adWidget,
          ],
        ),
      );
    }
  }

  _bottomBarInternal(double maxHeight) {
    return SizedBox(
      height: maxHeight,
      child: Column(
        children: WidgetUtils.skipNulls([
          WidgetUtils.showUpgradeToMobileAppMessageIfNeeded(),
          BottomAppBar(
            color: Colors.transparent,
            child: _showAddToDiaryButton(),
            elevation: 0,
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
          bottomNavigationBar: _bottomBarWithOptAd(),
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.teal,
            ),
            toolbarHeight: 75,
            title: Text(widget.exerciseDefinition.name, style: const TextStyle(color: Colors.teal)),
            bottom: TabBar(
              labelColor: Colors.teal,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info, color: Colors.teal,), text: "Info"),
                Tab(icon: Icon(Icons.fitness_center, color: Colors.teal,), text: "Muscles"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _showExerciseInfo(),
              _showExerciseMuscles(),
            ],
          ),
        )
    );
  }

  _showAddToDiaryButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed: () async {
          Navigator.push(
              context,
              AddExerciseToDiaryView.route(
                  widget.currentUserProfile,
                  widget.currentFitnessUserProfile,
                  widget.exerciseDefinition,
                  widget.isCurrentExerciseDefinitionCardio,
                  widget.selectedDayInQuestion
              ),
          ).then((value) => Navigator.pop(context));
        },
        child: const Text("Add to diary", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  _showExerciseMuscles() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          WidgetUtils.spacer(5),
          _displayCarousel(),
          _generateDotsIfNeeded(),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Primary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.exerciseDefinition.muscles.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          CarouselSlider(
            // carouselController: _carouselController,
              items: _generateMusclesCarousel(),
              options: CarouselOptions(
                height: 100,
                // aspectRatio: 3.0,
                viewportFraction: 0.825,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (page, reason) {
                  setState(() {
                    // _current = page;
                  });
                },
                scrollDirection: Axis.horizontal,
              )
          ),
          // Secondary muscles
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Secondary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.exerciseDefinition.muscles_secondary.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          CarouselSlider(
            // carouselController: _carouselController,
              items: _generateSecondaryMusclesCarousel(),
              options: CarouselOptions(
                height: 100,
                // aspectRatio: 3.0,
                viewportFraction: 0.825,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (page, reason) {
                  setState(() {
                    // _current = page;
                  });
                },
                scrollDirection: Axis.horizontal,
              )
          ),
        ]),
      ),
    );
  }

  _showExerciseInfo() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetUtils.skipNulls([
          WidgetUtils.spacer(5),
          _displayCarousel(),
          _generateDotsIfNeeded(),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Category",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.exerciseDefinition.category.name)
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Equipment",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.exerciseDefinition.equipment.map((e) => e.name).join(", "))
                ),
              ],
            ),
          ),
          WidgetUtils.spacer(2.5),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                    flex: 3,
                    child: Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                ),
                Expanded(
                    flex: 8,
                    child: Text(widget.exerciseDefinition.description)
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  _generateDotsIfNeeded() {
    if (widget.exerciseDefinition.images.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.exerciseDefinition.images.asMap().entries.map((entry) {
          return Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                    .withOpacity(_current == entry.key ? 0.9 : 0.4)),
          );
        }).toList(),
      );
    }
    return null;
  }

  _displayCarousel() {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(),
        options: CarouselOptions(
          height: 200,
          // aspectRatio: 3.0,
          viewportFraction: 0.825,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
          onPageChanged: (page, reason) {
            setState(() {
              _current = page;
            });
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _generateMusclesCarousel() {
    if (widget.exerciseDefinition.muscles.isNotEmpty) {
      return widget.exerciseDefinition.muscles.map((e) =>
          [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.65,
                child: SvgPicture.network(
                  "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
                  fit: BoxFit.scaleDown,
                  placeholderBuilder: (BuildContext context) => Container(
                      padding: const EdgeInsets.all(30.0),
                      child: const CircularProgressIndicator(color: Colors.yellow,)),
                )
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.65,
                child: SvgPicture.network(
                  "${ConstantUtils.WGER_API_HOST}${e.image_url_secondary}",
                  fit: BoxFit.scaleDown,
                  placeholderBuilder: (BuildContext context) => Container(
                      child: const CircularProgressIndicator(color: Colors.teal,)),
                )
            )
          ]
      )
      .expand((element) => element)
      .toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }

  _generateSecondaryMusclesCarousel() {
    if (widget.exerciseDefinition.muscles_secondary.isNotEmpty) {
      return widget.exerciseDefinition.muscles_secondary.map((e) {
        return [
          SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.65,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 200, minWidth: 200),
                child: SvgPicture.network(
                  "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
                  fit: BoxFit.scaleDown,
                  placeholderBuilder: (BuildContext context) => Container(
                      padding: const EdgeInsets.all(30.0),
                      child: const CircularProgressIndicator(color: Colors.yellow,)),
                ),
              )
          ),
          SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.65,
              child: SvgPicture.network(
                "${ConstantUtils.WGER_API_HOST}${e.image_url_secondary}",
                fit: BoxFit.scaleDown,
                placeholderBuilder: (BuildContext context) => Container(
                    padding: const EdgeInsets.all(30.0),
                    child: const CircularProgressIndicator(color: Colors.yellow,)),
              )
          )
        ];
      })
            .expand((element) => element)
            .toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }

  _generateCarouselOrStaticImage() {
    if (widget.exerciseDefinition.images.isNotEmpty) {
      return widget.exerciseDefinition.images.map((e) =>
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.65,
              child: Image.network(e.image, fit: BoxFit.contain)
          )
      ).toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/no_image_found.png")
                    )
                ),
              ),
            )
        )
      ];
    }
  }

}