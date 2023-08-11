import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/authenticated_user_stream_repository.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/keyboard_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
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
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
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
            if (state is UpgradeToPremiumFailure) {
              SnackbarUtils.showSnackBar(context, "Payment failed... please try again or use a different card!");
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
                return _dialogContentCard();
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
          child: GestureDetector(
            onTap: () {
              KeyboardUtils.hideKeyboard(context);
            },
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WidgetUtils.spacer(5),
                    _userProfileImageView(),
                    WidgetUtils.spacer(15),
                    const Text(
                      "For just \$2.99 a month, you get...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    const SizedBox(
                      height: 200,
                        child: Markdown(
                          data: ConstantUtils.premiumFeatures,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                        )
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
                                  ),
                                  child: _renderComparisonFeatures(),
                                ),
                              );
                            }
                        );
                      },
                      child: const Text(
                        "Tap here to learn more",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal
                        ),
                      ),
                    ),
                    WidgetUtils.spacer(15),
                    const Text(
                      "Activate now and get a free 30 day trial!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.teal
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    const Text(
                      "Please note that trial can only be used once",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        // color: Colors.teal
                      ),
                    ),
                    WidgetUtils.spacer(15),
                    const Text(
                      "Enter your credit card details to get started",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.teal
                      ),
                    ),
                    WidgetUtils.spacer(5),
                    const Text(
                      "You won't be charged until your trial ends, and you can cancel anytime!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        // color: Colors.teal
                      ),
                    ),
                    WidgetUtils.spacer(15),
                    _showCardDetails(),
                    WidgetUtils.spacer(15),
                    _payNowButton(),
                    WidgetUtils.spacer(5),
                  ],
          ),
              ),
            ),
          )
      ),
    );
  }

  DataCell _iconCheck() => DataCell(
      CircleAvatar(
        radius: 15,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal,
            image: DecorationImage(
                image: AssetImage("assets/icons/icon_check.png")
            ),
          ),
        ),
      )
  );

  DataCell _iconCross() => DataCell(
      CircleAvatar(
        radius: 15,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent,
            image: DecorationImage(
              image: AssetImage("assets/icons/icon_cross.png"),
            ),
          ),
        ),
      )
  );

  DataCell _iconCrossWithText(String text, TextStyle tableDataValueStyle) => DataCell(
      Row(
        children: [
          CircleAvatar(
            radius: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
                image: DecorationImage(
                    image: AssetImage("assets/icons/icon_cross.png")
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 3,
              style: tableDataValueStyle,
            ),
          )
        ],
      )
  );

  _renderComparisonFeatures() {
    double fontSizeTableHeader = 18;
    double fontSizeTableLeading = 14;
    double fontSizeTableData = 12;
    TextStyle tableDataStyle = TextStyle(fontWeight: FontWeight.w500, color: Colors.teal, fontSize: fontSizeTableLeading);
    TextStyle tableDataValueStyle = TextStyle(fontWeight: FontWeight.normal, color: Colors.teal, fontSize: fontSizeTableData);

    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1
            )
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 5,
                dataRowMinHeight: 45,
                dataRowMaxHeight: 60,
                columns: <DataColumn>[
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        'Feature',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: fontSizeTableHeader),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        'Freemium',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: fontSizeTableHeader),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        'Fitcentive+',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: fontSizeTableHeader),
                      ),
                    ),
                  ),
                ],
                rows: <DataRow>[
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('Unlimited social media posts', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('Unlimited nutrition tracking', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                      cells: [
                        DataCell(Text('Unlimited exercise tracking', style: tableDataStyle,)),
                        _iconCheck(),
                        _iconCheck(),
                      ]
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Progress tracking', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Achievements tracking', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Direct messaging', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Social feed', style: tableDataStyle,)),
                      _iconCheck(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Ad-free experience', style: tableDataStyle,)),
                      _iconCross(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Meetup reminders', style: tableDataStyle,)),
                      _iconCross(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Weight log reminders', style: tableDataStyle,)),
                      _iconCross(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Unlimited user discovery', style: tableDataStyle,)),
                      _iconCrossWithText("Max 5 per month", tableDataValueStyle),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Unlimited meetups', style: tableDataStyle,)),
                      _iconCrossWithText("Max 5 per month", tableDataValueStyle),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Multi person meetups', style: tableDataStyle,)),
                      _iconCross(),
                      _iconCheck(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Group chats', style: tableDataStyle,)),
                      _iconCross(),
                      _iconCheck(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
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
          child: const Text("Activate Fitcentive+", style: TextStyle(fontSize: 15, color: Colors.white)),
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
        content: const Text("You are about to subscribe to Fitcentive+ for \$2.99.\n\nThis is a monthly subscription that auto-renews every month after the trial period, if not already availed."),
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