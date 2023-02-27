import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/exercise/exercise_definition.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/detailed_exercise/bloc/detailed_exercise_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';

class DetailedExerciseView extends StatefulWidget {

  static const String routeName = "exercise/search";

  final PublicUserProfile currentUserProfile;
  final ExerciseDefinition exerciseDefinition;

  const DetailedExerciseView({Key? key, required this.currentUserProfile, required this.exerciseDefinition}): super(key: key);

  static Route route(PublicUserProfile currentUserProfile, ExerciseDefinition exerciseDefinition) {
    return MaterialPageRoute<void>(
        settings: const RouteSettings(
            name: routeName
        ),
        builder: (_) => DetailedExerciseView.withBloc(currentUserProfile, exerciseDefinition)
    );
  }

  static Widget withBloc(
      PublicUserProfile currentUserProfile,
      ExerciseDefinition exerciseDefinition
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
        exerciseDefinition: exerciseDefinition
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
    _tabController = TabController(vsync: this, length: MAX_TABS);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: MAX_TABS,
        child: Scaffold(
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

  _showExerciseMuscles() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetUtils.spacer(5),
        _displayCarousel(),
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
        )
      ],
    );
  }

  _showExerciseInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetUtils.spacer(5),
        _displayCarousel(),
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
        )
      ],
    );
  }

  _displayCarousel() {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(),
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
              _current = page;
            });
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  // todo - fix muscle images, and then add to diary option, remove but BE first!
  _generateMusclesCarousel() {
    if (widget.exerciseDefinition.muscles.isNotEmpty) {
      return widget.exerciseDefinition.muscles.map((e) =>
          [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.65,
                child: SvgPicture.network(
                  "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
                  height: 40,
                  width: 40,
                  fit: BoxFit.fill,
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
                  height: 40,
                  width: 40,
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
              child: SvgPicture.network(
                "${ConstantUtils.WGER_API_HOST}${e.image_url_main}",
                placeholderBuilder: (BuildContext context) => Container(
                    padding: const EdgeInsets.all(30.0),
                    child: const CircularProgressIndicator(color: Colors.yellow,)),
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
              child: Image.network(e.image, fit: BoxFit.cover)
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