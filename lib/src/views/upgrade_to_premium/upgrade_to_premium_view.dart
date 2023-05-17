import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/bloc/upgrade_to_premium_bloc.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/bloc/upgrade_to_premium_event.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/bloc/upgrade_to_premium_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as fs;

class UpgradeToPremiumView extends StatefulWidget {
  static const String routeName = "upgrade-to-premium";

  final PublicUserProfile currentUserProfile;
  final AuthenticatedUser authenticatedUser;

  const UpgradeToPremiumView({
    super.key,
    required this.currentUserProfile,
    required this.authenticatedUser,
  });

  static Route<bool> route({
    required PublicUserProfile currentUserProfile,
    required AuthenticatedUser authenticatedUser,
  }) => MaterialPageRoute(
    settings: const RouteSettings(
        name: routeName
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<UpgradeToPremiumBloc>(
            create: (context) => UpgradeToPremiumBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
              publicGatewayRepository: RepositoryProvider.of<PublicGatewayRepository>(context),
              authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
            )),
      ],
      child: UpgradeToPremiumView(
        currentUserProfile: currentUserProfile,
        authenticatedUser: authenticatedUser,
      ),
    ),
  );

  @override
  State<StatefulWidget> createState() {
    return UpgradeToPremiumViewState();
  }
}

class UpgradeToPremiumViewState extends State<UpgradeToPremiumView> {

  fs.CardEditController controller = fs.CardEditController();
  fs.CardFieldInputDetails? cardFieldInputDetails;

  late UpgradeToPremiumBloc _upgradeToPremiumBloc;

  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    _upgradeToPremiumBloc = BlocProvider.of<UpgradeToPremiumBloc>(context);
    controller.addListener(update);
  }

  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upgrade to Fitcentive+',
          style: TextStyle(
              color: Colors.teal,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, false);
          return false;
        },
        child: BlocListener<UpgradeToPremiumBloc, UpgradeToPremiumState>(
          listener: (context, state) {
            if (state is UpgradeToPremiumComplete) {
              SnackbarUtils.showSnackBar(context, "Congrats! You have enabled Fitcentive+ successfully!");
              Navigator.pop(context, true);
            }
            if (state is UpgradeLoading) {
              SnackbarUtils.showSnackBar(context, "Hold on... we're upgrading you...");
            }
          },
          child: BlocBuilder<UpgradeToPremiumBloc, UpgradeToPremiumState>(
            builder: (context, state) {
              if (state is UpgradeLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.teal,
                  ),
                );
              }
              else {
                return Center(
                  child: _dialogContentCard(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _userProfileImageView() {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: GestureDetector(
          onTap: () async {},
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 50, 50),
            ),
            child: widget.currentUserProfile.photoUrl == null ? const Icon(
                Icons.account_circle_outlined,
                color: Colors.teal,
                size: 100,
              )
                : null,
          ),
        ),
      ),
    );
  }

  _dialogContentCard() {
    return IntrinsicHeight(
      child: Card(
          elevation: 0,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: InkWell(
                onTap: () {
                  KeyboardUtils.hideKeyboard(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    WidgetUtils.spacer(5),
                    _userProfileImageView(),
                    WidgetUtils.spacer(10),
                    premiumWriteupContent(),
                  ],
          ),
              ),
            ),
          )
      ),
    );
  }

  premiumWriteupContent() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        WidgetUtils.spacer(5),
        const Text(
          "For just \$2.99 a month, you get...",
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

  _initiateUpgradeToPremium() async {
    if (cardFieldInputDetails?.complete ?? false) {
      final billingDetails = fs.BillingDetails(
        email: widget.authenticatedUser.user.email,
      );
      final paymentMethod = await fs.Stripe.instance.createPaymentMethod(
          params: fs.PaymentMethodParams.card(
            paymentMethodData: fs.PaymentMethodData(
              billingDetails: billingDetails,
            ),
          )
      );
      _upgradeToPremiumBloc.add(
          InitiateUpgradeToPremium(
              paymentMethodId: paymentMethod.id,
              user: widget.authenticatedUser
          )
      );
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
            if (cardFieldInputDetails?.complete ?? false) {
              _showConfirmationDialog();
            }
            else {
              SnackbarUtils.showSnackBarShort(context, "Please fill out all required card details!");
            }
          },
          child: const Text("Pay now", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
    );
  }

  _showConfirmationDialog() {
    showDialog(context: context, builder: (context) {
      Widget cancelButton = TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
        ),
        onPressed:  () {
          Navigator.pop(context);
        },
        child: const Text("Cancel"),
      );
      Widget susbcribeButton = TextButton(
        onPressed:  () {
          Navigator.pop(context);
          _initiateUpgradeToPremium();
        },
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        child: const Text("Subscribe"),
      );

      return AlertDialog(
        title: const Text(
          "Payment Confirmation",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        content: const Text("You are about to subscribe to Fitcentive+ for \$2.99. This is a monthly subscription that auto-renews every month."),
        actions: [
          cancelButton,
          susbcribeButton,
        ],
      );
    });
  }

  _showCardDetails() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: fs.CardField(
        controller: controller,
        onCardChanged: (card) {
          setState(() {
            cardFieldInputDetails = card;
          });
        },
      ),
    );
  }

}