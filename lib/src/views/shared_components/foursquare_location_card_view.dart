import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_location.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_photos.dart';
import 'package:flutter_app/src/models/foursquare/foursquare_result.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class FoursquareLocationCardView extends StatefulWidget {
  final FourSquareResult location;
  final String locationId;

  const FoursquareLocationCardView({
    super.key,
    required this.locationId,
    required this.location,
  });

  @override
  State createState() {
    return FoursquareLocationCardViewState();
  }
}

class FoursquareLocationCardViewState extends State<FoursquareLocationCardView> {

  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // borderOnForeground: true,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.5
        )
      ),
      elevation: 0,
      color: Theme.of(context).backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(10),
            _displayCarousel(),
            WidgetUtils.spacer(2.5),
            _generateDotsIfNeeded(widget.location.photos),
            _autoSizingText(Text(widget.location.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            _autoSizingText(Text(
                _generateFullAddress(widget.location.location),
                style: const TextStyle(fontSize: 16)
            )),
            WidgetUtils.spacer(2.5),
            Expanded(child: Text(widget.location.tel ?? "Phone number unknown")),
            WidgetUtils.spacer(2.5),
            Expanded(child: RichText(
                text: TextSpan(
                    children: [
                      TextSpan(
                          text: "View website",
                          style: Theme.of(context).textTheme.subtitle2?.copyWith(color: Colors.teal),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            launchUrl(Uri.parse(widget.location.website ?? "https://google.ca"));
                          }
                      ),
                    ]
                )
              )
            ),
            WidgetUtils.spacer(2.5),
            Expanded(child: RichText(
                text: TextSpan(
                    children: [
                      TextSpan(
                          text: "Get directions",
                          style: Theme.of(context).textTheme.subtitle2?.copyWith(color: Colors.teal),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query="
                                "${widget.location.location.address ??
                                   widget.location.location.formattedAddress ??
                                   "${widget.location.geocodes.main.latitude},${widget.location.geocodes.main.longitude}"
                                }"
                              )
                            );
                          }
                      ),
                    ]
                )
            )
            ),
            WidgetUtils.spacer(2.5),
          ]),
        ),
      ),
    );
  }



  _autoSizingText(Text textWidget) {
    return Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: textWidget,
              )
          ),
        );
  }

  _displayCarousel() {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(widget.location.photos),
        options: CarouselOptions(
          height: 100,
          // aspectRatio: 3.0,
          viewportFraction: 0.825,
          initialPage: 0,
          enableInfiniteScroll: false,
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

  _generateFullAddress(FourSquareLocation loc) {
    return "${loc.address}, ${loc.locality}, ${loc.region}, ${loc.country}";
  }

  _generateDotsIfNeeded(List<FourSquarePhoto>? photos) {
    if (photos?.isNotEmpty ?? false) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.location.photos!.asMap().entries.map((entry) {
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

  _generateCarouselOrStaticImage(List<FourSquarePhoto>? photos) {
    if (photos?.isNotEmpty ?? false) {
      return photos?.map((e) =>
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.65,
              child: Image.network(e.url, fit: BoxFit.cover)
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