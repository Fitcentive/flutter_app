import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as fs;

class UpgradeToPremiumView extends StatefulWidget {
  static const String routeName = "upgrade-to-premium";

  final PublicUserProfile currentUserProfile;

  const UpgradeToPremiumView({
    super.key,
    required this.currentUserProfile,
  });

  static Route route({
    required PublicUserProfile currentUserProfile,
  }) => MaterialPageRoute(
    settings: const RouteSettings(
        name: routeName
    ),
    builder: (_) => UpgradeToPremiumView(
      currentUserProfile: currentUserProfile,
    ),
  );

  @override
  State<StatefulWidget> createState() {
    return UpgradeToPremiumViewState();
  }
}

class UpgradeToPremiumViewState extends State<UpgradeToPremiumView> {

  fs.CardFieldInputDetails? cardFieldInputDetails;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upgrade to premium',
          style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: _dialogContentCard(),
    );
  }

  _dialogContentCard() {
    return IntrinsicHeight(
      child: Card(
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: _dialogContent(),
            ),
          )
      ),
    );
  }

  _dialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        WidgetUtils.spacer(5),
        const Text(
          "For just \$1.99 a month, you get...",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(5),
        const SizedBox(
            height: 200,
            child: Markdown(data: ConstantUtils.premiumFeatures)
        ),
        WidgetUtils.spacer(25),
        const Text(
          "Enter your credit card details to get started",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(15),
        _showCardDetails(),
        WidgetUtils.spacer(15),
        _payNowButton()
      ],
    );
  }

  MaterialStateProperty<Color> _getBackgroundColor() {
    if (cardFieldInputDetails?.complete ?? false) {
      return MaterialStateProperty.all<Color>(ColorUtils.BUTTON_AVAILABLE);
    }
    else {
      return MaterialStateProperty.all<Color>(ColorUtils.BUTTON_DISABLED);
    }
  }

  _payNowButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: _getBackgroundColor(),
          ),
          onPressed: () async {

          },
          child: const Text("Pay now", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
    );
  }

  _showCardDetails() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: fs.CardField(
        onCardChanged: (card) {
          setState(() {
            cardFieldInputDetails = card;
          });
        },
      ),
    );
  }

}